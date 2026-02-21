import { Request, Response } from "express";
import { IAuthRequest } from "@/types";
import College from "@/models/College.model";
import User from "@/models/User.model";
import mongoose from "mongoose";
import { AuditService } from "@/services/AuditService";
import { pubClient } from "@/config/redis";
import logger from "@/utils/logger";
import { MetricsService } from "@/services/MetricsService";
import MetricSnapshot from "@/models/MetricSnapshot.model";

/**
 * Get storage statistics for Super Admin (MongoDB & Redis)
 */
export const getStorageStats = async (req: IAuthRequest, res: Response) => {
  try {
    // 1. MongoDB Stats
    if (!mongoose.connection.db) {
      return res.status(503).json({ message: "Database connection not ready" });
    }
    const [dbStats, history] = await Promise.all([
      mongoose.connection.db.stats(),
      MetricsService.getHistory(),
    ]);

    // 2. Redis Memory Stats
    let redisStats = { usedMemory: "0", peakMemory: "0", fragmentation: "0" };
    try {
      const info = await pubClient.info("memory");
      // Basic parsing of redis info string
      const lines = info.split("\r\n");
      const findValue = (key: string) => {
        const line = lines.find((l) => l.startsWith(key));
        return line ? line.split(":")[1] : "0";
      };

      redisStats = {
        usedMemory: findValue("used_memory_human"),
        peakMemory: findValue("used_memory_peak_human"),
        fragmentation: findValue("mem_fragmentation_ratio"),
      };
    } catch (redisErr) {
      logger.error("Failed to fetch Redis stats", redisErr);
      // Don't fail the whole request if Redis is just for pub/sub but not stats-accessible
    }

    res.json({
      mongodb: {
        dbName: dbStats.db,
        collections: dbStats.collections,
        objects: dbStats.objects,
        avgObjSize: (dbStats.avgObjSize / 1024).toFixed(2) + " KB",
        dataSize: (dbStats.dataSize / (1024 * 1024)).toFixed(2) + " MB",
        storageSize: (dbStats.storageSize / (1024 * 1024)).toFixed(2) + " MB",
        indexSize: (dbStats.indexSize / (1024 * 1024)).toFixed(2) + " MB",
      },
      redis: redisStats,
      history,
    });
  } catch (error) {
    logger.error("Storage Stats Error:", error);
    res.status(500).json({ message: "Failed to fetch storage stats" });
  }
};

/**
 * Get historical storage metrics for a specific college
 */
export const getCollegeStorageHistory = async (
  req: IAuthRequest,
  res: Response,
) => {
  try {
    const { collegeId } = req.params;
    const { startDate, endDate } = req.query;

    const query: any = { collegeId };

    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate as string);
      if (endDate) query.date.$lte = new Date(endDate as string);
    }

    const history = await MetricSnapshot.find(query).sort({ date: 1 });

    res.json(history);
  } catch (error) {
    logger.error("College Storage History Error:", error);
    res
      .status(500)
      .json({ message: "Failed to fetch college storage history" });
  }
};

/**
 * Get system-wide statistics for Super Admin
 */
export const getSystemStats = async (req: IAuthRequest, res: Response) => {
  try {
    const [collegeCount, userCount, activeBuses, pendingColleges] =
      await Promise.all([
        College.countDocuments(),
        User.countDocuments(),
        // Assuming 'running' is the status for active buses
        User.countDocuments({ role: "driver" }), // Simple proxy for now
        College.countDocuments({ verified: false }),
      ]);

    res.json({
      collegeCount,
      userCount,
      activeBuses,
      pendingColleges,
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Verify a college
 */
export const verifyCollege = async (req: IAuthRequest, res: Response) => {
  try {
    const { collegeId } = req.params;
    const college = await College.findByIdAndUpdate(
      collegeId,
      { verified: true, updatedAt: new Date() },
      { new: true },
    );

    if (!college) {
      return res.status(404).json({ message: "College not found" });
    }

    // Audit Log
    await AuditService.log({
      req,
      action: "COLLEGE_VERIFY",
      resource: "College",
      resourceId: collegeId,
      resourceName: college.name,
      newState: { verified: true },
    });

    res.json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Suspend a college
 */
export const suspendCollege = async (req: IAuthRequest, res: Response) => {
  try {
    const { collegeId } = req.params;
    const { reason } = req.body;

    const college = await College.findByIdAndUpdate(
      collegeId,
      {
        suspended: true,
        suspensionReason: reason,
        updatedAt: new Date(),
      },
      { new: true },
    );

    if (!college) {
      return res.status(404).json({ message: "College not found" });
    }

    // Audit Log
    await AuditService.log({
      req,
      action: "COLLEGE_SUSPEND",
      resource: "College",
      resourceId: collegeId,
      resourceName: college.name,
      newState: { suspended: true, suspensionReason: reason },
    });

    res.json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

