import { Request, Response } from "express";
import { Sos, SosStatus } from "../models/Sos";
import User from "../models/User";
import { Bus } from "../models/Bus";
import { sendNotificationToDevices } from "../utils/firebase";
import logger from "../utils/logger";
import { v4 as uuidv4 } from "uuid";

interface AuthRequest extends Request {
  user?: any;
}

/**
 * Handle triggering an SOS alert
 */
export const sendSOS = async (req: AuthRequest, res: Response) => {
  try {
    const { busId, routeId, location } = req.body;
    const { id: userId, role: userRole, collegeId } = req.user;

    if (!location || !location.lat || !location.lng) {
      return res.status(400).json({ message: "Location data required" });
    }

    if (!collegeId) {
      logger.error(`SOS trigger failed: collegeId missing for user ${userId}`);
      return res
        .status(400)
        .json({ message: "User college information missing" });
    }

    const sosId = `SOS-${uuidv4().substring(0, 8).toUpperCase()}`;

    const bus = busId ? await Bus.findById(busId) : null;
    const busNumber = bus ? bus.busNumber : busId || "N/A";

    const newSos = new Sos({
      sos_id: sosId,
      collegeId: collegeId.toString(),
      user_id: userId,
      user_role: userRole,
      bus_id: busId || "N/A",
      bus_number: busNumber,
      route_id: routeId || "N/A",
      latitude: location.lat,
      longitude: location.lng,
      timestamp: new Date(),
      status: SosStatus.ACTIVE,
    });

    await newSos.save();

    // Broadcast via Socket.IO to coordinators only
    const io = req.app.get("io");
    if (io && collegeId) {
      const coordRoom = `${collegeId.toString()}_coordinators`;
      io.to(coordRoom).emit("sos_alert", newSos);
      logger.info(
        `[Socket] SOS alert broadcasted to coordinator room: ${coordRoom}`,
      );
    }

    // Send Firebase Notifications to Coordinators and College Admins
    const targetAdmins = await User.find({
      collegeId,
      role: { $in: ["busCoordinator", "collegeAdmin"] },
      fcmToken: { $exists: true, $ne: null },
    });

    const tokens = targetAdmins
      .map((c) => c.fcmToken)
      .filter((t): t is string => !!t);

    if (tokens.length > 0) {
      await sendNotificationToDevices(
        tokens,
        "🚨 SOS Alert!",
        `Emergency reported by ${userRole}. Bus: ${busNumber}`,
        {
          type: "SOS",
          sos_id: sosId,
          bus_id: busId || "",
          bus_number: busNumber,
          user_id: userId,
          lat: location.lat.toString(),
          lng: location.lng.toString(),
        },
      );
    }

    logger.info(`SOS triggered: ${sosId} by ${userId}`);
    res.status(201).json({
      success: true,
      message: "SOS Alert triggered successfully",
      sos: newSos,
    });
  } catch (error) {
    logger.error("Error in sendSOS details:", error);
    if (error instanceof Error) {
      logger.error(`Stack trace: ${error.stack}`);
    }
    res.status(500).json({
      message: "Failed to trigger SOS alert",
      details: error instanceof Error ? error.message : String(error),
    });
  }
};

/**
 * Resolve an active SOS alert
 */
export const resolveSos = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { resolutionNotes } = req.body;
    const { id: userId, collegeId, role } = req.user;

    const sos = await Sos.findOneAndUpdate(
      { sos_id: id },
      {
        status: SosStatus.RESOLVED,
        resolvedAt: new Date(),
        resolvedBy: userId,
        resolutionNotes: resolutionNotes || "Resolved by administrator",
      },
      { new: true },
    );

    if (!sos) {
      return res.status(404).json({ message: "SOS alert not found" });
    }

    // Broadcast resolution via Socket.IO to coordinators/admins
    const io = req.app.get("io");
    if (io && sos.collegeId) {
      const coordRoom = `${sos.collegeId}_coordinators`;
      io.to(coordRoom).emit("sos_resolved", { sos_id: id });
    }

    logger.info(`SOS resolved: ${id} by ${userId}`);
    res.json({ success: true, message: "SOS alert marked as resolved", sos });
  } catch (error) {
    logger.error("Error in resolveSos:", error);
    res.status(500).json({ message: "Failed to resolve SOS alert" });
  }
};

/**
 * Get SOS alerts (active or logs)
 */
export const getActiveSos = async (req: AuthRequest, res: Response) => {
  try {
    const { collegeId } = req.params;
    const { status } = req.query; // Optional filter
    const user = req.user;

    // Build query
    const query: any = {};
    if (collegeId !== "all") {
      query.collegeId = collegeId;
    } else if (user.role !== "superAdmin") {
      return res.status(403).json({ message: "Access denied" });
    }

    if (status) {
      query.status = status;
    } else if (req.path.includes("active")) {
      query.status = SosStatus.ACTIVE;
    } else if (req.path.includes("logs")) {
      query.status = SosStatus.RESOLVED;
    }

    const alerts = await Sos.find(query).sort({ timestamp: -1 });

    res.json(alerts);
  } catch (error) {
    logger.error("Error in getActiveSos:", error);
    res.status(500).json({ message: "Failed to fetch SOS alerts" });
  }
};
