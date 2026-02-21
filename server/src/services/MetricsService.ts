import cron from "node-cron";
import mongoose from "mongoose";
import { pubClient } from "@/config/redis";
import logger from "@/utils/logger";
import College from "@/models/College.model";
import User from "@/models/User.model";
import { Bus } from "@/models/Bus.model";
import Transaction from "@/models/Transaction.model";
import Notification from "@/models/Notification.model";
import AuditLog from "@/models/AuditLog.model";
import MetricSnapshot from "@/models/MetricSnapshot.model";

export class MetricsService {
  private static readonly HISTORY_KEY = "storage_stats:history";
  private static readonly MAX_SAMPLES = 24; // 24 hours of history

  /**
   * Initialize background metric sampling
   */
  public static init() {
    // Run system-wide sample every hour
    cron.schedule("0 * * * *", () => {
      this.sampleMetrics();
    });

    // Run per-college aggregation daily at midnight
    cron.schedule("0 0 * * *", () => {
      this.samplePerCollegeMetrics();
    });

    // Run once on startup
    this.sampleMetrics();
    this.samplePerCollegeMetrics();

    logger.info(
      "Metrics background service initialized (1h system / 24h college sampling)",
    );
  }

  /**
   * Aggregates and stores usage metrics for every college
   */
  public static async samplePerCollegeMetrics() {
    try {
      const colleges = await College.find({ verified: true });
      const stats = await mongoose.connection.db!.stats();
      const avgObjSize = stats.avgObjSize || 0;

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      logger.info(
        `Starting per-college metric sampling for ${colleges.length} colleges`,
      );

      for (const college of colleges) {
        const collegeId = college._id;

        const [users, buses, transactions, notifications, auditLogs] =
          await Promise.all([
            User.countDocuments({ collegeId }),
            Bus.countDocuments({ collegeId }),
            Transaction.countDocuments({ collegeId }),
            Notification.countDocuments({ collegeId }),
            AuditLog.countDocuments({ collegeId }),
          ]);

        const totalDocs =
          users + buses + transactions + notifications + auditLogs;
        const estimatedStorageBytes = totalDocs * avgObjSize;
        const estimatedStorageMB = parseFloat(
          (estimatedStorageBytes / (1024 * 1024)).toFixed(2),
        );

        await MetricSnapshot.findOneAndUpdate(
          { collegeId, date: today },
          {
            counts: { users, buses, transactions, notifications, auditLogs },
            estimatedStorageMB,
          },
          { upsert: true },
        );
      }

      logger.info("Per-college metric snapshots updated");
    } catch (error) {
      logger.error("Failed to sample per-college metrics", error);
    }
  }

  /**
   * Sample current stats and push to Redis history
   */
  private static async sampleMetrics() {
    try {
      if (!mongoose.connection.db) return;

      const dbStats = await mongoose.connection.db.stats();
      const redisInfo = await pubClient.info("memory");

      const lines = redisInfo.split("\r\n");
      const findRedisValue = (key: string) => {
        const line = lines.find((l) => l.startsWith(key));
        return line ? line.split(":")[1] : "0";
      };

      const sample = {
        timestamp: new Date().toISOString(),
        mongodb: {
          dataSize: (dbStats.dataSize / (1024 * 1024)).toFixed(2), // MB
          storageSize: (dbStats.storageSize / (1024 * 1024)).toFixed(2), // MB
          indexSize: (dbStats.indexSize / (1024 * 1024)).toFixed(2), // MB
        },
        redis: {
          usedMemory: findRedisValue("used_memory_human"),
          usedMemoryBytes: findRedisValue("used_memory"), // raw bytes for better charting
        },
      };

      // Push to Redis List
      await pubClient.lPush(this.HISTORY_KEY, JSON.stringify(sample));

      // Keep only last N samples
      await pubClient.lTrim(this.HISTORY_KEY, 0, this.MAX_SAMPLES - 1);

      logger.info("Storage metrics sample recorded");
    } catch (error) {
      logger.error("Failed to sample metrics", error);
    }
  }

  /**
   * Retrieve historical metrics
   */
  public static async getHistory() {
    try {
      const history = await pubClient.lRange(this.HISTORY_KEY, 0, -1);
      return history.map((item) => JSON.parse(item)).reverse(); // Return in chronological order
    } catch (error) {
      logger.error("Failed to fetch metrics history", error);
      return [];
    }
  }
}
