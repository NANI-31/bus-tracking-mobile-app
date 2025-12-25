// src/controllers/notificationController.ts
import { Request, Response } from "express";
import Notification from "../models/Notification";
import User from "../models/User";
import {
  sendNotificationToDevice,
  sendNotificationToTopic,
} from "../utils/firebase";
import { buildNotificationMessage } from "../utils/buildNotification";
import { NOTIFICATION_TYPES } from "../constants/notificationTypes";

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

// Save/update FCM token for a user
export const updateFcmToken = async (req: Request, res: Response) => {
  try {
    const { userId, fcmToken } = req.body;

    if (!userId || !fcmToken) {
      return res
        .status(400)
        .json({ message: "userId and fcmToken are required" });
    }

    await User.findByIdAndUpdate(userId, { fcmToken });

    res.status(200).json({ success: true, message: "FCM token updated" });
  } catch (error) {
    res.status(500).json({ message: "Error updating FCM token", error });
  }
};

// Send test push notification using templates
export const sendTestNotification = async (req: Request, res: Response) => {
  try {
    const { userId } = req.body;

    // Sample test payloads using templates
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

    // Pick a random test payload
    const randomPayload =
      testPayloads[Math.floor(Math.random() * testPayloads.length)];

    // Get user's language preference
    let userLanguage: "en" | "hi" | "te" = "en";
    if (userId) {
      const user = await User.findById(userId);
      if (user?.language && ["en", "hi", "te"].includes(user.language)) {
        userLanguage = user.language as "en" | "hi" | "te";
      }

      // Build the notification message from template in user's language
      const { title, message } = buildNotificationMessage(
        randomPayload.type,
        randomPayload.payload as unknown as Record<string, string | number>,
        userLanguage
      );

      // Send to user's device if they have FCM token
      if (user?.fcmToken) {
        await sendNotificationToDevice(user.fcmToken, title, message, {
          type: randomPayload.type,
        });
      }

      return res.status(200).json({
        success: true,
        title,
        message,
        type: randomPayload.type,
        language: userLanguage,
        timestamp: new Date().toISOString(),
      });
    }

    // Default response if no userId
    const { title, message } = buildNotificationMessage(
      randomPayload.type,
      randomPayload.payload as unknown as Record<string, string | number>,
      "en"
    );

    res.status(200).json({
      success: true,
      title,
      message,
      type: randomPayload.type,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ message: "Error sending test notification", error });
  }
};

// Send templated notification to a user
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

    // Get user's language preference
    const user = await User.findById(userId);
    let userLanguage: "en" | "hi" | "te" = "en";
    if (user?.language && ["en", "hi", "te"].includes(user.language)) {
      userLanguage = user.language as "en" | "hi" | "te";
    }

    // Build the notification message from template in user's language
    const { title, message } = buildNotificationMessage(
      type,
      payload,
      userLanguage
    );

    // Save to database
    const newNotification = new Notification({
      receiverId: userId,
      title,
      message,
      type,
    });
    await newNotification.save();

    // Send FCM notification
    if (user?.fcmToken) {
      await sendNotificationToDevice(user.fcmToken, title, message, {
        type,
        notificationId: newNotification._id.toString(),
      });
    }

    res.status(200).json({
      success: true,
      notification: { title, message, type },
    });
  } catch (error) {
    res.status(500).json({
      message: "Error sending templated notification",
      error,
    });
  }
};

// Send notification to all users of a college (via topic)
export const sendCollegeNotification = async (req: Request, res: Response) => {
  try {
    const { collegeId, title, message } = req.body;

    if (!collegeId || !title || !message) {
      return res.status(400).json({
        message: "collegeId, title, and message are required",
      });
    }

    // Topic format: college_<collegeId>
    const topic = `college_${collegeId}`;
    await sendNotificationToTopic(topic, title, message);

    res.status(200).json({
      success: true,
      message: `Notification sent to topic: ${topic}`,
    });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error sending college notification", error });
  }
};
