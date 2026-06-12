import User, { UserRole } from "@/models/User.model";
import Notification from "@/models/Notification.model";
import { logHistoryHelper } from "@/controllers/transport/history.controller";
import {
  sendNotificationToDevice,
  sendNotificationToDevices,
  sendNotificationToTopic,
} from "../utils/firebase";
import { buildNotificationMessage } from "@/utils/buildNotification";
import { NOTIFICATION_TYPES } from "@/constants/notificationTypes";
import logger from "@/utils/logger";
import { s3Service } from "@/services/s3.service";
import { v4 as uuidv4 } from "uuid";

/**
 * NotificationService - Encapsulates notification business logic.
 * Follows Single Responsibility Principle.
 */
export class NotificationService {
  /**
   * Get user's preferred language
   */
  private async getUserLanguage(userId: string): Promise<"en" | "hi" | "te"> {
    const user = await User.findById(userId);
    if (user?.language && ["en", "hi", "te"].includes(user.language)) {
      return user.language as "en" | "hi" | "te";
    }
    return "en";
  }

  /**
   * Send a templated notification to a user
   */
  async sendTemplatedNotification(
    userId: string,
    type: string,
    payload: Record<string, string | number>,
    senderId?: string,
  ): Promise<{
    success: boolean;
    notification: { title: string; message: string; type: string };
  }> {
    const user = await User.findById(userId);
    const userLanguage = await this.getUserLanguage(userId);

    // Build the notification message from template
    const { title, message } = buildNotificationMessage(
      type,
      payload,
      userLanguage,
    );

    logger.info(
      `[NotificationService] Preparing to send ${type} to user ${userId} (Language: ${userLanguage})`,
    );

    // Save to database
    const newNotification = new Notification({
      senderId,
      receiverId: userId,
      title,
      message,
      type,
    });
    await newNotification.save();

    // Send FCM push notification
    await this.sendPushNotification(user, title, message, {
      type,
      notificationId: newNotification._id.toString(),
    });

    // Send Socket Notification
    try {
      const { getIO } = require("../socket");
      const io = getIO();
      io.to(userId).emit("notification_received", {
        id: newNotification._id.toString(),
        title,
        message,
        type,
        timestamp: newNotification.timestamp,
      });
      logger.info(
        `[Socket] Emitted notification_received to user room: ${userId}`,
      );
    } catch (socketErr) {
      logger.warn("Notification saved but socket emit failed", socketErr);
    }

    return { success: true, notification: { title, message, type } };
  }

  /**
   * Send a voice notification to a user
   */
  async sendVoiceNotification(
    receiverId: string,
    voiceKey: string,
    senderId?: string,
    message: string = "New voice message",
  ): Promise<{ success: boolean; notificationId: string }> {
    const title = "Voice Message";
    const type = NOTIFICATION_TYPES.VOICE_NOTIFICATION;

    // Save to database
    const newNotification = new Notification({
      senderId,
      receiverId,
      message,
      type,
      data: {
        voiceKey,
      },
    });
    await newNotification.save();

    // Generate pre-signed URL for real-time playability
    let audioUrl: string | undefined;
    try {
      audioUrl = await s3Service.generatePresignedUrl(voiceKey);
    } catch (err) {
      logger.error(`Error generating pre-signed URL for socket emit:`, err);
    }

    // Send Socket Notification
    try {
      const { getIO } = require("../socket");
      const io = getIO();
      io.to(receiverId).emit("notification_received", {
        id: newNotification._id.toString(),
        title,
        message,
        type,
        data: { voiceKey },
        audioUrl,
        timestamp: newNotification.timestamp,
      });
    } catch (socketErr) {
      logger.warn("Voice notification saved but socket emit failed", socketErr);
    }

    // Also send Push if tokens exist
    const receiver = await User.findById(receiverId);
    if (receiver) {
      await this.sendPushNotification(receiver, title, message, {
        type,
        notificationId: newNotification._id.toString(),
        voiceKey,
        audioUrl: audioUrl || "",
      });
    }

    return { success: true, notificationId: newNotification._id.toString() };
  }

  /**
   * Send a voice notification to all coordinators of a college
   */
  async sendVoiceNotificationToCoordinators(
    collegeId: string,
    voiceKey: string,
    senderId?: string,
    message: string = "New voice message from driver",
  ): Promise<{ success: boolean; count: number }> {
    const title = "Voice Message";
    const type = NOTIFICATION_TYPES.VOICE_NOTIFICATION;

    // 1. Find all coordinators and admins for this college
    const targets = await User.find({
      collegeId,
      role: { $in: [UserRole.BusCoordinator, UserRole.SuperAdmin] },
    });

    if (targets.length === 0) {
      return { success: true, count: 0 };
    }

    // 2. Save notifications to DB
    const notificationDocs = targets.map((u) => ({
      senderId,
      receiverId: u._id,
      message,
      type,
      data: { voiceKey },
    }));
    await Notification.insertMany(notificationDocs);

    // Generate pre-signed URL for real-time playability
    let audioUrl: string | undefined;
    try {
      audioUrl = await s3Service.generatePresignedUrl(voiceKey);
    } catch (err) {
      logger.error(`Error generating pre-signed URL for broadast emit:`, err);
    }

    // 3. Emit Socket Notifications
    try {
      const { getIO } = require("../socket");
      const io = getIO();
      // To individual rooms
      targets.forEach((u) => {
        io.to(u._id.toString()).emit("notification_received", {
          title,
          message,
          type,
          data: { voiceKey },
          audioUrl,
          timestamp: new Date(),
        });
      });
      // Also to the general college room if needed
      io.to(collegeId).emit("notification_received", {
        title,
        message,
        type,
        data: { voiceKey },
        audioUrl,
        timestamp: new Date(),
      });
    } catch (socketErr) {
      logger.warn("Voice broadcast saved but socket emit failed", socketErr);
    }

    // 4. Send Push Notifications (Exclude sender from push/status bar)
    for (const target of targets) {
      if (target.fcmToken && target._id.toString() !== senderId) {
        await this.sendPushNotification(target, title, message, {
          type,
          voiceKey,
          audioUrl: audioUrl || "",
        });
      }
    }

    return { success: true, count: targets.length };
  }

  /**
   * Broadcast voice message to all users in the college
   */
  async broadcastVoiceNotification(
    collegeId: string,
    senderId: string,
    voiceKey: string,
    message: string = "New voice broadcast",
  ): Promise<{ success: boolean; count: number }> {
    const title = "Voice Broadcast";
    const type = NOTIFICATION_TYPES.VOICE_NOTIFICATION;

    // 1. Find target users (ALL users in the college)
    const users = await User.find({
      collegeId,
      role: {
        $in: [
          UserRole.Student,
          UserRole.Teacher,
          UserRole.Parent,
          UserRole.BusCoordinator,
          UserRole.SuperAdmin,
        ],
      },
    });

    if (users.length === 0) {
      return { success: true, count: 0 };
    }

    // 2. Save notifications to DB
    const notificationDocs = users.map((u) => ({
      senderId,
      receiverId: u._id,
      message,
      type,
      data: { voiceKey },
    }));
    await Notification.insertMany(notificationDocs);

    // Generate pre-signed URL for real-time playability
    let audioUrl: string | undefined;
    try {
      audioUrl = await s3Service.generatePresignedUrl(voiceKey);
    } catch (err) {
      logger.error(`Error generating pre-signed URL for broadcast emit:`, err);
    }

    // 3. Send Socket Notifications
    try {
      const { getIO } = require("../socket");
      const io = getIO();
      io.to(collegeId).emit("notification_received", {
        title,
        message,
        type,
        data: { voiceKey },
        audioUrl,
        timestamp: new Date(),
      });
    } catch (socketErr) {
      logger.warn("Voice broadcast saved but socket emit failed", socketErr);
    }

    // 4. Send Push Notifications (Batched, excluding sender from push/status bar)
    const fcmTokens = users
      .filter((u) => u._id.toString() !== senderId)
      .map((u) => u.fcmToken)
      .filter((t): t is string => !!t);

    const batchSize = 500;
    for (let i = 0; i < fcmTokens.length; i += batchSize) {
      const batch = fcmTokens.slice(i, i + batchSize);
      await sendNotificationToDevices(batch, title, message, {
        type,
        voiceKey,
        audioUrl: audioUrl || "",
      });
    }

    return { success: true, count: users.length };
  }

  /**
   * Send a random test notification to a user
   */
  async sendTestNotification(userId?: string): Promise<{
    success: boolean;
    title: string;
    message: string;
    type: string;
    language?: string;
    timestamp: string;
  }> {
    const testPayloads = [
      {
        type: NOTIFICATION_TYPES.BUS_DELAYED,
        payload: { busNumber: "12", delayMinutes: 15, reason: "heavy traffic" },
      },
      {
        type: NOTIFICATION_TYPES.BUS_ARRIVING,
        payload: { busNumber: "7", stopName: "Main Gate", etaMinutes: 5 },
      },
      {
        type: NOTIFICATION_TYPES.BUS_NEARBY,
        payload: { busNumber: "3", stopName: "Science Block" },
      },
      {
        type: NOTIFICATION_TYPES.BUS_CANCELLED,
        payload: { busNumber: "9", reason: "mechanical issue" },
      },
      {
        type: NOTIFICATION_TYPES.NEXT_STOP,
        payload: { busNumber: "5", stopName: "Library Stop" },
      },
    ];

    const randomPayload =
      testPayloads[Math.floor(Math.random() * testPayloads.length)];
    let userLanguage: "en" | "hi" | "te" = "en";

    if (userId) {
      userLanguage = await this.getUserLanguage(userId);
      const user = await User.findById(userId);

      const { title, message } = buildNotificationMessage(
        randomPayload.type,
        randomPayload.payload as unknown as Record<string, string | number>,
        userLanguage,
      );

      if (user?.fcmToken) {
        await sendNotificationToDevice(user.fcmToken, title, message, {
          type: randomPayload.type,
        });
      }

      return {
        success: true,
        title,
        message,
        type: randomPayload.type,
        language: userLanguage,
        timestamp: new Date().toISOString(),
      };
    }

    // Default response if no userId
    const { title, message } = buildNotificationMessage(
      randomPayload.type,
      randomPayload.payload as unknown as Record<string, string | number>,
      "en",
    );

    return {
      success: true,
      title,
      message,
      type: randomPayload.type,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Send notification to all users of a college via topic
   */
  async sendCollegeNotification(
    collegeId: string,
    title: string,
    message: string,
  ): Promise<{ success: boolean; topic: string }> {
    const topic = `college_${collegeId}`;
    await sendNotificationToTopic(topic, title, message);
    return { success: true, topic };
  }

  /**
   * Broadcast message to specifically Students, Teachers, and Parents
   */
  async broadcastNotification(
    collegeId: string,
    senderId: string,
    message: string,
  ): Promise<{ success: boolean; count: number }> {
    const title = "College Announcement";
    const type = NOTIFICATION_TYPES.GENERAL_ANNOUNCEMENT;

    // 1. Find target users (ALL users in these roles for the college)
    const users = await User.find({
      collegeId,
      role: {
        $in: [
          UserRole.Student,
          UserRole.Teacher,
          UserRole.Parent,
          UserRole.BusCoordinator,
          UserRole.SuperAdmin,
        ],
      },
    });

    logger.info(
      `[NotificationService] Found ${users.length} users for broadcast in college ${collegeId}`,
    );

    if (users.length === 0) {
      return { success: true, count: 0 };
    }

    // Filter users with FCM tokens for push notifications (Exclude sender)
    const usersWithTokens = users.filter(
      (u) => !!u.fcmToken && u._id.toString() !== senderId,
    );
    const fcmTokens = usersWithTokens
      .map((u) => u.fcmToken)
      .filter((t): t is string => !!t);

    logger.info(
      `[NotificationService] Found ${fcmTokens.length} users with FCM tokens for push broadcast.`,
    );

    // 2. Save notifications to DB for each user
    const groupId = uuidv4();
    const notificationDocs = users.map((u) => ({
      senderId,
      receiverId: u._id,
      title,
      message,
      type,
      groupId,
    }));
    await Notification.insertMany(notificationDocs);

    // 3. Send push notifications in batches (FCM limit is 500)
    const batchSize = 500;
    let successCount = 0;

    for (let i = 0; i < fcmTokens.length; i += batchSize) {
      const batch = fcmTokens.slice(i, i + batchSize);
      const result = await sendNotificationToDevices(batch, title, message, {
        type,
      });
      successCount += result.success;
    }

    // 4. Send Socket Notification to College Room
    try {
      const { getIO } = require("../socket");
      const io = getIO();
      io.to(collegeId).emit("notification_received", {
        title,
        message,
        type,
        timestamp: new Date(),
      });
      logger.info(
        `[Socket] Emitted notification_received to college room: ${collegeId}`,
      );
    } catch (socketErr) {
      logger.warn("Broadcast saved but socket emit failed", socketErr);
    }

    // 5. Log to college history
    await logHistoryHelper(
      collegeId,
      "broadcast_announcement",
      `Broadcast message sent to ${users.length} users: ${message}`,
      { senderId, message },
      undefined,
      senderId,
    );

    return { success: true, count: users.length };
  }

  /**
   * Helper to send push notification to a user's device
   */
  private async sendPushNotification(
    user: any,
    title: string,
    message: string,
    data: Record<string, string>,
  ): Promise<boolean> {
    if (user?.fcmToken) {
      logger.info(
        `[NotificationService] User ${user._id} has FCM token. Sending...`,
      );
      const success = await sendNotificationToDevice(
        user.fcmToken,
        title,
        message,
        data,
      );
      logger.info(
        `[NotificationService] Send result for user ${user._id}: ${success}`,
      );
      return success;
    } else {
      logger.warn(
        `[NotificationService] User ${user?._id} has NO FCM token. Skipping push.`,
      );
      return false;
    }
  }

  /**
   * Update FCM token for a user
   */
  async updateFcmToken(userId: string, fcmToken: string): Promise<void> {
    await User.findByIdAndUpdate(userId, { fcmToken });
  }

  /**
   * Remove FCM token for a user (logout cleanup)
   */
  async removeFcmToken(userId: string): Promise<void> {
    await User.findByIdAndUpdate(userId, { $unset: { fcmToken: 1 } });
    logger.info(`[NotificationService] FCM token removed for user ${userId}`);
  }
}

// Singleton instance
let notificationServiceInstance: NotificationService | null = null;

export const getNotificationService = (): NotificationService => {
  if (!notificationServiceInstance) {
    notificationServiceInstance = new NotificationService();
  }
  return notificationServiceInstance;
};
