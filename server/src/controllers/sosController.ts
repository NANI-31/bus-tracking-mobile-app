import { Request, Response } from "express";
import User from "../models/User";
import { sendNotificationToDevices } from "../utils/firebase";
import logger from "../utils/logger";

// Extend Request to include user property added by authMiddleware
interface AuthRequest extends Request {
  user?: any;
}

export const sendSOS = async (req: AuthRequest, res: Response) => {
  try {
    const { busId, location } = req.body;
    const driverId = req.user.id;
    const collegeId = req.user.collegeId; // From authMiddleware

    if (!location || !location.lat || !location.lng) {
      return res.status(400).json({ message: "Location data required" });
    }

    // Find coordinators for this college who have FCM tokens
    const coordinators = await User.find({
      collegeId,
      role: "coordinator",
      fcmToken: { $exists: true, $ne: null },
    });

    const tokens = coordinators
      .map((c) => c.fcmToken)
      .filter((t): t is string => t !== undefined && t !== null && t !== "");

    if (tokens.length > 0) {
      await sendNotificationToDevices(
        tokens,
        "🚨 SOS Alert!",
        `Emergency reported by driver. Location: ${location.lat}, ${location.lng}`,
        {
          type: "SOS",
          busId: busId || "",
          driverId: driverId,
          lat: location.lat.toString(),
          lng: location.lng.toString(),
        }
      );
    } else {
      logger.warn(
        `SOS sent by driver ${driverId} but no coordinators found with tokens.`
      );
    }

    logger.info(`SOS sent by driver ${driverId} for bus ${busId}`);
    res.json({ success: true, message: "SOS Alert sent to coordinators" });
  } catch (error) {
    logger.error("Error sending SOS:", error);
    res.status(500).json({ message: "Failed to send SOS alert" });
  }
};
