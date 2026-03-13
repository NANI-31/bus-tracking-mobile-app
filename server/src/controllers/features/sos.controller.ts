import { Response } from "express";
import { IAuthRequest } from "@/types";
import { SosStatus } from "@/models/Sos.model";
import { getSosService } from "@/services/sosService";
import logger from "@/utils/logger";

/**
 * Handle triggering an SOS alert
 */
export const sendSOS = async (req: IAuthRequest, res: Response) => {
  try {
    const { busId, routeId, location } = req.body;
    const userId = req.user?.id;
    const userRole = req.user?.role || "unknown";
    const collegeId = req.user?.collegeId;

    if (!location || !location.lat || !location.lng) {
      return res.status(400).json({ message: "Location data required" });
    }

    if (!collegeId) {
      return res
        .status(400)
        .json({ message: "User college information missing" });
    }

    const io = req.app.get("io");
    const sosService = getSosService(io);

    const newSos = await sosService.triggerSos({
      userId: userId!,
      userRole,
      collegeId: collegeId.toString(),
      busId,
      routeId,
      location,
    });

    res.status(201).json({
      success: true,
      message: "SOS Alert triggered successfully",
      sos: newSos,
    });
  } catch (error) {
    logger.error("Error in sendSOS details:", error);
    res.status(500).json({
      message: "Failed to trigger SOS alert",
      details: error instanceof Error ? error.message : String(error),
    });
  }
};

/**
 * Resolve an active SOS alert
 */
export const resolveSos = async (req: IAuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { resolutionNotes } = req.body;
    const userId = req.user?.id || "unknown";

    const io = req.app.get("io");
    const sosService = getSosService(io);

    const sos = await sosService.resolveSos(id as string, resolutionNotes, userId);

    res.json({ success: true, message: "SOS alert marked as resolved", sos });
  } catch (error) {
    const message = (error as Error).message;
    if (message === "SOS alert not found") {
      return res.status(404).json({ message });
    }
    logger.error("Error in resolveSos:", error);
    res.status(500).json({ message: "Failed to resolve SOS alert" });
  }
};

/**
 * Get SOS alerts (active or logs)
 */
export const getActiveSos = async (req: IAuthRequest, res: Response) => {
  logger.info(
    `SOS: Entering getActiveSos. CollegeId: ${req.params.collegeId}, Path: ${req.path}`,
  );
  try {
    const { collegeId } = req.params;
    const { status } = req.query; // Optional filter
    const user = req.user;

    // Build query filters
    const query: any = {};

    if (status) {
      query.status = status;
    } else if (req.path.includes("active")) {
      query.status = SosStatus.ACTIVE;
    } else if (req.path.includes("logs")) {
      query.status = SosStatus.RESOLVED;
    }

    const io = req.app.get("io");
    const sosService = getSosService(io);

    const alerts = await sosService.getActiveSos(
      collegeId as string,
      query,
      user?.role || "unknown",
    );

    logger.info(`SOS: Found ${alerts.length} alerts`);
    res.json(alerts);
  } catch (error) {
    const message = (error as Error).message;
    if (message === "Access denied") {
      return res.status(403).json({ message });
    }
    logger.error("Error in getActiveSos:", error);
    res.status(500).json({ message: "Failed to fetch SOS alerts" });
  }
};

