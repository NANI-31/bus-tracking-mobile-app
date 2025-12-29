import User from "../models/User";
import Notification from "../models/Notification";
import {
  sendNotificationToDevice,
  sendNotificationToTopic,
} from "../utils/firebase";
import { buildNotificationMessage } from "../utils/buildNotification";
import { NOTIFICATION_TYPES } from "../constants/notificationTypes";
import logger from "../utils/logger";

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
    senderId?: string
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
      userLanguage
    );

    logger.info(
      `[NotificationService] Preparing to send ${type} to user ${userId} (Language: ${userLanguage})`
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

    return { success: true, notification: { title, message, type } };
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
        userLanguage
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
      "en"
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
    message: string
  ): Promise<{ success: boolean; topic: string }> {
    const topic = `college_${collegeId}`;
    await sendNotificationToTopic(topic, title, message);
    return { success: true, topic };
  }

  /**
   * Helper to send push notification to a user's device
   */
  private async sendPushNotification(
    user: any,
    title: string,
    message: string,
    data: Record<string, string>
  ): Promise<boolean> {
    if (user?.fcmToken) {
      logger.info(
        `[NotificationService] User ${user._id} has FCM token. Sending...`
      );
      const success = await sendNotificationToDevice(
        user.fcmToken,
        title,
        message,
        data
      );
      logger.info(
        `[NotificationService] Send result for user ${user._id}: ${success}`
      );
      return success;
    } else {
      logger.warn(
        `[NotificationService] User ${user?._id} has NO FCM token. Skipping push.`
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
