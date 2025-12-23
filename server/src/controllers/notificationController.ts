import { Request, Response } from "express";
import Notification from "../models/Notification";

export const sendNotification = async (req: Request, res: Response) => {
  try {
    const newNotification = new Notification(req.body);
    const savedNotification = await newNotification.save();
    // Logic to push notification via FCM or similar would go here
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
