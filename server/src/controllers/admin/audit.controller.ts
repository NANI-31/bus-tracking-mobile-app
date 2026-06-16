import { Request, Response } from "express";
import { IAuthRequest } from "@/types";
import AuditLog from "@/models/AuditLog.model";
import logger from "@/utils/logger";

/**
 * Get audit logs with filtering and pagination
 */
export const getAuditLogs = async (req: IAuthRequest, res: Response) => {
  logger.info("AUDIT: Entering getAuditLogs");
  try {
    const {
      collegeId,
      adminId,
      action,
      resource,
      date,
      startDate,
      endDate,
      limit = 50,
      skip = 0,
    } = req.query;

    const query: any = {};
    const userRole = req.user?.role;
    const userCollegeId = req.user?.collegeId;

    if (userRole === "superAdmin") {
      if (collegeId) query.collegeId = collegeId;
    } else {
      // For College Admins, force filter by their own collegeId
      if (!userCollegeId) {
        return res.status(403).json({ message: "College context missing" });
      }
      query.collegeId = userCollegeId.toString();
    }

    if (adminId) query.userId = adminId;

    // Support multi-select for action and resource
    if (action) {
      const actionArray =
        typeof action === "string" ? action.split(",") : action;
      query.action = Array.isArray(actionArray) ? { $in: actionArray } : action;
    }

    if (resource) {
      const resourceArray =
        typeof resource === "string" ? resource.split(",") : resource;
      query.resource = Array.isArray(resourceArray)
        ? { $in: resourceArray }
        : resource;
    }

    if (date) {
      const selectedDate = new Date(date as string);
      const startOfDay = new Date(selectedDate.setHours(0, 0, 0, 0));
      const endOfDay = new Date(selectedDate.setHours(23, 59, 59, 999));
      query.createdAt = {
        $gte: startOfDay,
        $lte: endOfDay,
      };
    } else if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        const start = new Date(startDate as string);
        query.createdAt.$gte = new Date(start.setHours(0, 0, 0, 0));
      }
      if (endDate) {
        const end = new Date(endDate as string);
        query.createdAt.$lte = new Date(end.setHours(23, 59, 59, 999));
      }
    }

    const logs = await AuditLog.find(query)
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip(Number(skip));

    const total = await AuditLog.countDocuments(query);
    logger.info(
      `AUDIT: Found ${logs.length} logs for role ${userRole}, total ${total}`,
    );

    res.json({
      logs,
      total,
      limit: Number(limit),
      skip: Number(skip),
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Create a manual audit log entry (internal/admin)
 */
export const createManualAuditLog = async (req: IAuthRequest, res: Response) => {
  try {
    const logData = {
      ...req.body,
      userId: req.user?.id,
      userEmail: req.user?.email,
      userName: req.user?.fullName || "Admin",
      createdAt: new Date(),
    };

    const log = await AuditLog.create(logData);
    res.status(201).json(log);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

