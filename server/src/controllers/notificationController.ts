// src/controllers/notificationController.ts
import { Request, Response } from "express";
import Notification from "../models/Notification";
import User from "../models/User";
import { sendNotificationToDevice } from "../utils/firebase";
import { getNotificationService } from "../services/notificationService";
import logger from "../utils/logger";

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
        { notificationId: savedNotification._id.toString() }
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
    const notifications = await Notification.find({
      receiverId: req.params.userId,
    }).sort({ timestamp: -1 });
    res.status(200).json(notifications);
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
      { new: true }
    );
    res.json(notification);
  } catch (error) {
    res.status(500).json({ message: "Error updating notification", error });
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
  senderId?: string
) => {
  const notificationService = getNotificationService();
  return notificationService.sendTemplatedNotification(
    userId,
    type,
    payload,
    senderId
  );
};

/**
 * Send templated notification to a user - HTTP endpoint
 */
export const sendTemplatedNotification = async (
  req: Request,
  res: Response
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
      payload
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
      message
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
export const broadcastNotification = async (req: Request, res: Response) => {
  try {
    const { message } = req.body;
    const collegeId = (req as any).user?.collegeId;
    const senderId = (req as any).user?.id;

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
      message
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
