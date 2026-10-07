import { Bus } from "@/models/Bus.model";
import { releaseTeacherOverride } from "@/services/teacherOverrideService";
import logger from "@/utils/logger";

const OVERRIDE_TTL_MS = 2 * 60 * 1000; // 2 minutes

/**
 * Checks for ghost teacher overrides where no heartbeat or location update
 * has been received for 2 minutes, and automatically releases them.
 */
export const cleanupExpiredOverrides = async () => {
  try {
    const cutoffTime = new Date(Date.now() - OVERRIDE_TTL_MS);

    // Find any bus currently under teacher override whose heartbeat is older than 2 minutes
    // or where no heartbeat was ever recorded and override is active.
    const expiredBuses = await Bus.find({
      trackingTeacherId: { $ne: null, $exists: true },
      $or: [
        { lastTrackingHeartbeat: { $lt: cutoffTime } },
        {
          lastTrackingHeartbeat: { $exists: false },
          updatedAt: { $lt: cutoffTime },
        },
      ],
    });

    if (expiredBuses.length > 0) {
      logger.warn(
        `[TTL Cleaner] Found ${expiredBuses.length} ghost teacher override(s) with no updates for 2m. Auto-releasing...`
      );
      for (const bus of expiredBuses) {
        await releaseTeacherOverride(bus._id.toString(), "ttl_expired");
      }
    }
  } catch (err) {
    logger.error("[TTL Cleaner] Error cleaning up expired overrides:", err);
  }
};

/**
 * Initialize periodic TTL cleaner (runs every 30 seconds)
 */
export const initTrackingCleanupCron = () => {
  setInterval(cleanupExpiredOverrides, 30000);
  logger.info("[Cron] Tracking cleanup TTL cleaner initialized (30s interval, 2m threshold)");
};
