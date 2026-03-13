// Force trigger nodemon restart
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
import { s3Service } from "@/services/s3.service";
import { Bus, BusLocation } from "@/models/Bus.model";
import Route from "@/models/Route.model";
import Schedule from "@/models/Schedule.model";
import Notification from "@/models/Notification.model";
import { Sos } from "@/models/Sos.model";
import { Incident } from "@/models/Incident.model";
import { History } from "@/models/History.model";
import AuditLog from "@/models/AuditLog.model";
import Transaction from "@/models/Transaction.model";
import { BusAssignmentLog } from "@/models/BusAssignmentLog.model";

/**
 * Get storage statistics for Super Admin (MongoDB & Redis)
 */
export const getStorageStats = async (req: IAuthRequest, res: Response) => {
  try {
    // 1. MongoDB Stats
    if (!mongoose.connection.db) {
      return res.status(503).json({ message: "Database connection not ready" });
    }
    const [dbStats, history, s3Stats] = await Promise.all([
      mongoose.connection.db.stats(),
      MetricsService.getHistory(),
      s3Service.getBucketStats(),
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
      s3: {
        totalSize: (s3Stats.totalSize / (1024 * 1024)).toFixed(2) + " MB",
        objectCount: s3Stats.objectCount,
      },
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
 * Get full details of a specific college
 */
export const getCollegeDetails = async (req: IAuthRequest, res: Response) => {
  try {
    const { collegeId } = req.params;
    const college = await College.findById(collegeId).populate(
      "adminId",
      "name email phone role",
    );

    if (!college) {
      return res.status(404).json({ message: "College not found" });
    }

    res.json(college);
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

    res.json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Wipe out all data for a specific college or all colleges (Super Admin only)
 */
export const wipeCollegeData = async (req: IAuthRequest, res: Response) => {
  try {
    const { collegeId } = req.params; // "all" or specific ID
    const { deleteCollegeRecord } = req.body; // Flag to delete the College entry itself

    logger.info(
      `[SuperAdmin] Wipe request started for collegeId: ${collegeId}`,
    );

    const isGlobalWipe = collegeId === "all";
    const filter = isGlobalWipe ? {} : { collegeId };

    // 1. Fetch relevant users and buses if specific wipe
    let userIds: string[] = [];
    let busIds: string[] = [];
    if (!isGlobalWipe) {
      const [users, buses] = await Promise.all([
        User.find({ collegeId }, "_id"),
        Bus.find({ collegeId }, "_id"),
      ]);
      userIds = users.map((u) => u._id.toString());
      busIds = buses.map((b) => b._id.toString());
    }

    // 2. Systematic Deletion
    await Promise.all([
      // Data with direct collegeId
      Bus.deleteMany(filter),
      Route.deleteMany(filter),
      Schedule.deleteMany(filter),
      Sos.deleteMany(filter),
      Incident.deleteMany(filter),
      MetricSnapshot.deleteMany(filter),
      AuditLog.deleteMany(filter),
      BusAssignmentLog.deleteMany(filter),

      // Indirect data (linked to users or buses)
      isGlobalWipe
        ? BusLocation.deleteMany({})
        : BusLocation.deleteMany({ busId: { $in: busIds } }),

      isGlobalWipe
        ? Notification.deleteMany({}) // Wipe all notifications globally
        : Notification.deleteMany({
            $or: [
              { senderId: { $in: userIds } },
              { receiverId: { $in: userIds } },
              { "data.collegeId": collegeId },
            ],
          }),

      isGlobalWipe ? History.deleteMany({}) : History.deleteMany(filter),

      isGlobalWipe
        ? Transaction.deleteMany({})
        : Transaction.deleteMany({ userId: { $in: userIds } }),

      // Users - BE CAREFUL NOT TO DELETE THE SUPER ADMIN
      isGlobalWipe
        ? User.deleteMany({ role: { $ne: "superAdmin" } })
        : User.deleteMany({ collegeId }),
    ]);

    // 3. Optional: Delete the College record itself
    if (deleteCollegeRecord === true && !isGlobalWipe) {
      await College.findByIdAndDelete(collegeId);
    } else if (isGlobalWipe && deleteCollegeRecord === true) {
      await College.deleteMany({});
    }

    // Audit Log the wipe
    await AuditService.log({
      req,
      action: "DATA_WIPE",
      resource: isGlobalWipe ? "System" : "College",
      resourceId: isGlobalWipe ? undefined : collegeId,
      resourceName: isGlobalWipe ? "All Colleges Data" : `College Data (${collegeId})`,
      newState: {
        collegeId: collegeId,
        isGlobal: isGlobalWipe,
        deletedCollegeRecord: deleteCollegeRecord,
      },
    });

    res.status(200).json({
      success: true,
      message: `Data wipe ${isGlobalWipe ? "global" : "for college " + collegeId} completed successfully.`,
    });
  } catch (error) {
    logger.error(`[SuperAdmin] Wipe error: ${error}`);
    res.status(500).json({
      message: "Error wiping college data",
      error: (error as Error).message,
    });
  }
};
