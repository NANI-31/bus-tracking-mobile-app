import cron from "node-cron";
import Notification from "@/models/Notification.model";
import { s3Service } from "@/services/s3.service";
import logger from "@/utils/logger";
import { NOTIFICATION_TYPES } from "@/constants/notificationTypes";

/**
 * Initialize all notification related crons
 */
export const initNotificationCron = () => {
  // Run every day at midnight (00:00)
  cron.schedule("0 0 * * *", async () => {
    logger.info("[Cron] Running notification cleanup check (5-day policy)...");
    await cleanupOldNotifications();
  });
};

/**
 * Deletes notifications and S3 assets older than 5 days
 */
const cleanupOldNotifications = async () => {
  try {
    const fiveDaysAgo = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000);

    // 1. Find all notifications older than 5 days
    const oldNotifications = await Notification.find({
      timestamp: { $lt: fiveDaysAgo },
    });

    if (oldNotifications.length === 0) {
      logger.info("[Cron] No old notifications to cleanup.");
      return;
    }

    logger.info(
      `[Cron] Found ${oldNotifications.length} notifications to delete.`,
    );

    // 2. Filter notifications that have S3 assets to clean up first
    const voiceNotifications = oldNotifications.filter((n) => n.data?.voiceKey);

    if (voiceNotifications.length > 0) {
      logger.info(
        `[Cron] Deleting ${voiceNotifications.length} S3 voice assets...`,
      );
      for (const notification of voiceNotifications) {
        if (notification.data?.voiceKey) {
          try {
            await s3Service.deleteFile(notification.data.voiceKey);
          } catch (s3Err) {
            logger.error(
              `[Cron] Failed to delete S3 asset ${notification.data.voiceKey}:`,
              s3Err,
            );
          }
        }
      }
    }

    // 3. Purge from MongoDB
    const idsToDelete = oldNotifications.map((n) => n._id);
    const result = await Notification.deleteMany({ _id: { $in: idsToDelete } });

    logger.info(
      `[Cron] Successfully purged ${result.deletedCount} notifications from MongoDB.`,
    );
  } catch (error) {
    logger.error("[Cron] Error in cleanupOldNotifications:", error);
  }
};
