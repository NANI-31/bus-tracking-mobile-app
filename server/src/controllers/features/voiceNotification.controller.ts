import { Request, Response } from "express";
import { getNotificationService } from "@/services/notificationService";
import { AuthenticatedRequest } from "@/types/authenticatedRequest";
import logger from "@/utils/logger";
import { s3Service } from "@/services/s3.service";
import path from "path";
import fs from "fs";

/**
 * Handle voice notification upload and sending
 */
export const sendVoiceNotification = async (req: Request, res: Response) => {
  try {
    const { receiverId, message } = req.body;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ message: "Audio file is required" });
    }

    const { user } = req as AuthenticatedRequest;
    const senderId = user?.id;
    const role = user?.role || "unknown";

    // Setup folder structure: /voice-messages/{role}/{userId}/{timestamp}.mp3
    const timestamp = Date.now();
    const extension = path.extname(file.originalname) || ".mp3";
    const s3Key = `voice-messages/${role}/${senderId}/${timestamp}${extension}`;

    // Upload to AWS S3
    await s3Service.uploadFile(file.path, s3Key, file.mimetype || "audio/mpeg");

    // Clean up temporary local file
    try {
      if (fs.existsSync(file.path)) {
        fs.unlinkSync(file.path);
      }
    } catch (cleanErr) {
      logger.warn(
        `[VoiceNotificationController] Local file cleanup failed: ${cleanErr}`,
      );
    }

    const notificationService = getNotificationService();
    let result;

    if (!receiverId || receiverId === "coordinator") {
      const collegeId = user?.collegeId;
      if (!collegeId) {
        return res
          .status(400)
          .json({ message: "College ID not found for broadcast" });
      }
      result = await notificationService.sendVoiceNotificationToCoordinators(
        collegeId,
        s3Key,
        senderId,
        message || "New voice message from driver",
      );
    } else if (receiverId === "all" || receiverId === "broadcast") {
      const collegeId = user?.collegeId;
      if (!collegeId) {
        return res
          .status(400)
          .json({ message: "College ID not found for broadcast" });
      }
      result = await notificationService.broadcastVoiceNotification(
        collegeId,
        senderId,
        s3Key,
        message || "New voice broadcast",
      );
    } else {
      result = await notificationService.sendVoiceNotification(
        receiverId,
        s3Key,
        senderId,
        message || "New voice message",
      );
    }

    // Get a temporary pre-signed URL for the response (optional but helpful)
    const audioUrl = await s3Service.generatePresignedUrl(s3Key);

    res.status(201).json({
      success: true,
      notificationId: (result as any).notificationId,
      audioUrl: audioUrl,
      voiceKey: s3Key,
      count: (result as any).count, // For broadcast
    });
  } catch (error) {
    logger.error(`[VoiceNotificationController] Error: ${error}`);
    res.status(500).json({
      message: "Error sending voice notification",
      error: (error as Error).message,
    });
  }
};
