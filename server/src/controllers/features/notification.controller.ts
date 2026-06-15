// src/controllers/notificationController.ts
import { Request, Response } from "express";
import Notification from "@/models/Notification.model";
import User from "@/models/User.model";
import {
  sendNotificationToDevice,
  sendDataOnlyNotificationToDevices,
  sendDataOnlyNotificationToTopic,
} from "@/utils/firebase";
import { getNotificationService } from "@/services/notificationService";
import logger from "@/utils/logger";
import { s3Service } from "@/services/s3.service";
import { NOTIFICATION_TYPES } from "@/constants/notificationTypes";

/**
 * Create and send a notification
 */
export const sendNotification = async (req: Request, res: Response) => {
  try {
    const newNotification = new Notification(req.body);
    const savedNotification = await newNotification.save();

    // Send FCM notification to the receiver
    const receiver = await User.findById(req.body.receiverId);
    if (receiver?.fcmToken) {
      await sendNotificationToDevice(
        receiver.fcmToken,
        req.body.title || "New Notification",
        req.body.message,
        { notificationId: savedNotification._id.toString() },
      );
    }

    res.status(201).json(savedNotification);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Get all notifications for a user
 */
export const getUserNotifications = async (req: Request, res: Response) => {
  try {
    const rawNotifications = await Notification.find({
      receiverId: req.params.userId,
    }).sort({ timestamp: -1 });

    // Enhance voice notifications with pre-signed URLs
    const enhancedNotifications = await Promise.all(
      rawNotifications.map(async (notif) => {
        const doc = notif.toObject();
        if (
          doc.type === NOTIFICATION_TYPES.VOICE_NOTIFICATION &&
          doc.data?.voiceKey
        ) {
          try {
            doc.audioUrl = await s3Service.generatePresignedUrl(
              doc.data.voiceKey,
            );
          } catch (err) {
            logger.error(
              `Error generating pre-signed URL for ${doc._id}:`,
              err,
            );
          }
        }
        return doc;
      }),
    );

    res.status(200).json(enhancedNotifications);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Mark a notification as read
 */
export const markNotificationAsRead = async (req: Request, res: Response) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      { isRead: true },
      { returnDocument: 'after' },
    );

    if (!notification) {
      return res.status(404).json({ message: "Notification not found" });
    }

    // Sync across devices via Socket
    try {
      const { getIO } = require("../../socket/index");
      const io = getIO();
      if (notification.receiverId) {
        io.to(notification.receiverId).emit("notification_read", {
          id: notification._id,
        });
      }
    } catch (err) {
      logger.warn("[Socket] Failed to emit notification_read", err);
    }

    // Dismiss push notification across devices via Silent FCM
    try {
      const user = await User.findById(notification.receiverId);
      if (user?.fcmToken) {
        await sendDataOnlyNotificationToDevices([user.fcmToken], {
          action: "dismiss",
          notificationId: notification._id.toString(),
        });
      }
    } catch (err) {
      logger.warn("[FCM] Failed to send silent dismissal", err);
    }

    res.status(200).json(notification);
  } catch (error) {
    res.status(500).json({ message: "Error updating notification", error });
  }
};

/**
 * Mark all notifications as read for a specific user
 */
export const markAllNotificationsAsRead = async (
  req: Request,
  res: Response,
) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    const result = await Notification.updateMany(
      { receiverId: req.params.userId, isRead: false },
      { $set: { isRead: true } },
    );

    // Sync across devices via Socket
    try {
      const { getIO } = require("../../socket/index");
      const { userId } = req.params;
      getIO().to(userId).emit("notifications_read_all", { userId });
    } catch (err) {
      logger.warn("[Socket] Failed to emit notifications_read_all", err);
    }

    // Dismiss all push notifications across devices via Silent FCM
    try {
      const user = await User.findById(req.params.userId);
      if (user?.fcmToken) {
        await sendDataOnlyNotificationToDevices([user.fcmToken], {
          action: "dismiss_all",
          userId: req.params.userId as string,
        });
      }
    } catch (err) {
      logger.warn("[FCM] Failed to send silent dismissal", err);
    }

    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ message: "Error updating notifications", error });
  }
};

/**
 * Update FCM token for a user - delegates to NotificationService
 */
export const updateFcmToken = async (req: Request, res: Response) => {
  try {
    const { userId, fcmToken } = req.body;

    if (!userId || !fcmToken) {
      return res
        .status(400)
        .json({ message: "userId and fcmToken are required" });
    }

    const notificationService = getNotificationService();
    await notificationService.updateFcmToken(userId, fcmToken);

    res.status(200).json({ success: true, message: "FCM token updated" });
  } catch (error) {
    res.status(500).json({ message: "Error updating FCM token", error });
  }
};

/**
 * Remove FCM token for a user - delegates to NotificationService
 */
export const removeFcmToken = async (req: Request, res: Response) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    const notificationService = getNotificationService();
    await notificationService.removeFcmToken(userId);

    res.status(200).json({ success: true, message: "FCM token removed" });
  } catch (error) {
    logger.error(`[NotificationController] Error removing FCM token: ${error}`);
    res.status(500).json({ message: "Error removing FCM token", error });
  }
};

/**
 * Send test push notification - delegates to NotificationService
 */
export const sendTestNotification = async (req: Request, res: Response) => {
  try {
    const { userId } = req.body;

    const notificationService = getNotificationService();
    const result = await notificationService.sendTestNotification(userId);

    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: "Error sending test notification", error });
  }
};

/**
 * Helper to send templated notification (reusable across controllers)
 * Delegates to NotificationService
 */
export const sendTemplatedNotificationHelper = async (
  userId: string,
  type: string,
  payload: Record<string, string | number>,
  senderId?: string,
) => {
  const notificationService = getNotificationService();
  return notificationService.sendTemplatedNotification(
    userId,
    type,
    payload,
    senderId,
  );
};

/**
 * Send templated notification to a user - HTTP endpoint
 */
export const sendTemplatedNotification = async (
  req: Request,
  res: Response,
) => {
  try {
    const { userId, type, payload } = req.body;

    if (!userId || !type || !payload) {
      return res.status(400).json({
        message: "userId, type, and payload are required",
      });
    }

    const notificationService = getNotificationService();
    const result = await notificationService.sendTemplatedNotification(
      userId,
      type,
      payload,
    );
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({
      message: "Error sending templated notification",
      error: (error as Error).message,
    });
  }
};

/**
 * Send notification to all users of a college - delegates to NotificationService
 */
export const sendCollegeNotification = async (req: Request, res: Response) => {
  try {
    const { collegeId, title, message } = req.body;

    if (!collegeId || !title || !message) {
      return res.status(400).json({
        message: "collegeId, title, and message are required",
      });
    }

    const notificationService = getNotificationService();
    const result = await notificationService.sendCollegeNotification(
      collegeId,
      title,
      message,
    );

    res.status(200).json({
      success: true,
      message: `Notification sent to topic: ${result.topic}`,
    });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error sending college notification", error });
  }
};

/**
 * Broadcast notification to Students, Teachers, and Parents
 */
import { AuthenticatedRequest } from "@/types/authenticatedRequest";

export const broadcastNotification = async (req: Request, res: Response) => {
  try {
    const { message } = req.body;
    const collegeId = (req as AuthenticatedRequest).user?.collegeId;
    const senderId = (req as AuthenticatedRequest).user?.id;

    if (!collegeId || !senderId) {
      return res
        .status(401)
        .json({ message: "Unauthorized or missing college context" });
    }

    if (!message) {
      return res.status(400).json({ message: "Message is required" });
    }

    const notificationService = getNotificationService();
    const result = await notificationService.broadcastNotification(
      collegeId,
      senderId,
      message,
    );

    res.status(200).json(result);
  } catch (error) {
    logger.error(`[NotificationController] Broadcast error: ${error}`);
    res.status(500).json({
      message: "Error sending broadcast notification",
      error: (error as Error).message,
    });
  }
};

/**
 * Delete a notification
 * If it's a voice notification, also deletes the S3 asset
 */
export const deleteNotification = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const notification = await Notification.findById(id);

    if (!notification) {
      return res.status(444).json({ message: "Notification not found" });
    }

    // Security: Only sender, receiver, or a coordinator/admin can delete
    const { user } = req as AuthenticatedRequest;
    const isAuthorized =
      notification.senderId === user?.id ||
      notification.receiverId === user?.id ||
      user?.role === "Bus Coordinator" ||
      user?.role === "superAdmin";

    if (!isAuthorized) {
      return res
        .status(403)
        .json({ message: "Unauthorized to delete this notification" });
    }

    const voiceKey = notification.data?.voiceKey;
    const groupId = notification.groupId;
    const isVoice = notification.type === NOTIFICATION_TYPES.VOICE_NOTIFICATION;
    const collegeId = user?.collegeId;

    // 1. Cleanup S3 if it's a voice notification
    if (isVoice && voiceKey) {
      try {
        await s3Service.deleteFile(voiceKey);
        logger.info(`[NotificationController] S3 asset deleted: ${voiceKey}`);
      } catch (s3Err) {
        logger.error(`[NotificationController] S3 deletion failed: ${s3Err}`);
      }
    }

    // 2. RETRACTION LOGIC: If many notifications share the same voiceKey (broadcast) or groupId, delete all
    let deletedIds: string[] = [id as string];
    if (isVoice && voiceKey) {
      const related = await Notification.find({ "data.voiceKey": voiceKey });
      deletedIds = related.map((r) => r._id.toString());
      await Notification.deleteMany({ "data.voiceKey": voiceKey });
      logger.info(
        `[NotificationController] Retracted ${deletedIds.length} notifications for voiceKey: ${voiceKey}`,
      );
    } else if (groupId) {
      const related = await Notification.find({ groupId });
      deletedIds = related.map((r) => r._id.toString());
      await Notification.deleteMany({ groupId });
      logger.info(
        `[NotificationController] Retracted ${deletedIds.length} notifications for groupId: ${groupId}`,
      );
    } else {
      await Notification.findByIdAndDelete(id);
    }

    // 3. SYNC: Emit Socket event
    try {
      const { getIO } = require("../../socket/index");
      const io = getIO();
      if ((isVoice && voiceKey) || groupId) {
        if (collegeId) {
          // Broadcast retraction to the whole college room
          io.to(collegeId).emit("notification_deleted", {
            voiceKey,
            groupId,
            deletedIds,
          });
        }
      } else if (notification.receiverId) {
        // Single recipient sync
        io.to(notification.receiverId).emit("notification_deleted", {
          id,
          deletedIds: [id],
        });
      }
    } catch (socketErr) {
      logger.warn("[Socket] Deletion emit failed", socketErr);
    }

    // 4. DISMISS: Send silent FCM to clear system tray
    try {
      if (isVoice && voiceKey) {
        // Find all recipients to send silent push
        // Optimization: In a real system, we might use a topic for clear,
        // but here we'll try to find active tokens for related notifications if not too many.
        // For now, let's at least dismiss it for the main user or use topic if available.
        if (collegeId) {
          await sendDataOnlyNotificationToTopic(`college_${collegeId}`, {
            action: "dismiss_voice",
            voiceKey: voiceKey,
          });
        }
      } else {
        const receiver = await User.findById(notification.receiverId);
        if (receiver?.fcmToken) {
          await sendDataOnlyNotificationToDevices([receiver.fcmToken], {
            action: "dismiss",
            notificationId: id as string,
          });
        }
      }
    } catch (fcmErr) {
      logger.warn("[FCM] Silent dismissal failed", fcmErr);
    }

    res.status(200).json({
      success: true,
      message: "Notification(s) deleted/retracted successfully",
    });
  } catch (error) {
    logger.error(`[NotificationController] Deletion error: ${error}`);
    res.status(500).json({
      message: "Error deleting notification",
      error: (error as Error).message,
    });
  }
};
