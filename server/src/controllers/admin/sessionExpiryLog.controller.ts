import { Response } from "express";
import { IAuthRequest } from "@/types";
import SessionExpiryLog, {
  SessionExpiryReason,
} from "@/models/SessionExpiryLog.model";
import logger from "@/utils/logger";

// ─── GET /admin/super/session-expiry-logs ─────────────────────────────────────
/**
 * Returns paginated session expiry logs with optional filters.
 *
 * Query params:
 *   collegeId   – filter by college (super admin only)
 *   reason      – comma-separated list of SessionExpiryReason values
 *   userRole    – filter by user role
 *   platform    – "android" | "ios" | "web"
 *   startDate   – ISO date string (inclusive)
 *   endDate     – ISO date string (inclusive)
 *   limit       – default 50, max 200
 *   skip        – default 0
 */
export const getSessionExpiryLogs = async (
  req: IAuthRequest,
  res: Response,
) => {
  try {
    const {
      collegeId,
      reason,
      userRole,
      platform,
      startDate,
      endDate,
      limit = 50,
      skip = 0,
    } = req.query;

    const query: any = {};

    // College scoping
    if (collegeId) {
      query.collegeId = collegeId;
    }

    // Reason filter (supports comma-separated multi-select)
    if (reason) {
      const reasonArray =
        typeof reason === "string" ? reason.split(",").map((r) => r.trim()) : reason;
      query.reason = Array.isArray(reasonArray)
        ? { $in: reasonArray }
        : reason;
    }

    // Role filter
    if (userRole) {
      query.userRole = userRole;
    }

    // Platform filter
    if (platform) {
      query.platform = platform;
    }

    // Date range
    if (startDate || endDate) {
      query.occurredAt = {};
      if (startDate) {
        const start = new Date(startDate as string);
        query.occurredAt.$gte = new Date(start.setHours(0, 0, 0, 0));
      }
      if (endDate) {
        const end = new Date(endDate as string);
        query.occurredAt.$lte = new Date(end.setHours(23, 59, 59, 999));
      }
    }

    const effectiveLimit = Math.min(Number(limit), 200);

    const [logs, total] = await Promise.all([
      SessionExpiryLog.find(query)
        .sort({ occurredAt: -1 })
        .limit(effectiveLimit)
        .skip(Number(skip))
        .lean(),
      SessionExpiryLog.countDocuments(query),
    ]);

    logger.info(
      `[SessionExpiryLogs] Returned ${logs.length} of ${total} logs`,
    );

    res.json({ logs, total, limit: effectiveLimit, skip: Number(skip) });
  } catch (error) {
    logger.error(`[SessionExpiryLogs] Error: ${(error as Error).message}`);
    res.status(500).json({ message: (error as Error).message });
  }
};

// ─── GET /admin/super/session-expiry-logs/summary ────────────────────────────
/**
 * Returns aggregate summary data for the dashboard cards and chart.
 *
 * Query params:
 *   collegeId – filter by college
 *   days      – lookback window in days (default 7)
 */
export const getSessionExpiryLogsSummary = async (
  req: IAuthRequest,
  res: Response,
) => {
  try {
    const { collegeId, days = 7 } = req.query;

    const since = new Date(
      Date.now() - Number(days) * 24 * 60 * 60 * 1000,
    );

    const matchStage: any = { occurredAt: { $gte: since } };
    if (collegeId) {
      matchStage.collegeId = collegeId;
    }

    const [
      totalEvents,
      last24h,
      byReason,
      affectedUsers,
      recentByDay,
    ] = await Promise.all([
      // Total in window
      SessionExpiryLog.countDocuments(matchStage),

      // Last 24 hours
      SessionExpiryLog.countDocuments({
        ...matchStage,
        occurredAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      }),

      // Breakdown by reason
      SessionExpiryLog.aggregate([
        { $match: matchStage },
        { $group: { _id: "$reason", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),

      // Unique affected users
      SessionExpiryLog.distinct("userId", {
        ...matchStage,
        userId: { $ne: null },
      }),

      // Daily trend (last N days)
      SessionExpiryLog.aggregate([
        { $match: matchStage },
        {
          $group: {
            _id: {
              $dateToString: {
                format: "%Y-%m-%d",
                date: "$occurredAt",
                timezone: "Asia/Kolkata",
              },
            },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
    ]);

    res.json({
      totalEvents,
      last24h,
      affectedUsersCount: affectedUsers.length,
      topReason: byReason[0]?._id ?? null,
      byReason,
      recentByDay,
    });
  } catch (error) {
    logger.error(
      `[SessionExpiryLogs] Summary error: ${(error as Error).message}`,
    );
    res.status(500).json({ message: (error as Error).message });
  }
};

// ─── GET /admin/super/session-expiry-logs/:id ────────────────────────────────
/**
 * Returns the full detail document for a single log entry.
 */
export const getSessionExpiryLogDetail = async (
  req: IAuthRequest,
  res: Response,
) => {
  try {
    const log = await SessionExpiryLog.findById(req.params.id).lean();
    if (!log) {
      return res.status(404).json({ message: "Log entry not found" });
    }
    res.json(log);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

// ─── DELETE /admin/super/session-expiry-logs ─────────────────────────────────
/**
 * Clears all logs older than N days (manual purge, TTL handles routine cleanup).
 */
export const purgeSessionExpiryLogs = async (
  req: IAuthRequest,
  res: Response,
) => {
  try {
    const { olderThanDays = 90 } = req.body;
    const cutoff = new Date(
      Date.now() - Number(olderThanDays) * 24 * 60 * 60 * 1000,
    );
    const result = await SessionExpiryLog.deleteMany({
      occurredAt: { $lt: cutoff },
    });
    logger.info(
      `[SessionExpiryLogs] Purged ${result.deletedCount} logs older than ${olderThanDays} days`,
    );
    res.json({
      message: `Deleted ${result.deletedCount} log entries`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
