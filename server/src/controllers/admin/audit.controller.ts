import { Request, Response } from "express";
import { AuthRequest } from "../../middleware/authMiddleware";
import AuditLog from "../../models/AuditLog.model";
import logger from "../../utils/logger";

/**
 * Get audit logs with filtering and pagination
 */
export const getAuditLogs = async (req: AuthRequest, res: Response) => {
  logger.info("AUDIT: Entering getAuditLogs");
  try {
    const { collegeId, adminId, action, limit = 50, skip = 0 } = req.query;

    const query: any = {};
    if (collegeId) query.collegeId = collegeId;
    if (adminId) query.userId = adminId;
    if (action) query.action = action;

    const logs = await AuditLog.find(query)
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip(Number(skip));

    const total = await AuditLog.countDocuments(query);
    logger.info(`AUDIT: Found ${logs.length} logs, total ${total}`);

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
export const createManualAuditLog = async (req: AuthRequest, res: Response) => {
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
