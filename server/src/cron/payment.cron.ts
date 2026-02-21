import cron from "node-cron";
import User from "@/models/User.model";
import Transaction from "@/models/Transaction.model";
import { sendNotificationToDevice } from "@/utils/firebase";
import Razorpay from "razorpay";
import logger from "@/utils/logger";

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID!,
  key_secret: process.env.RAZORPAY_KEY_SECRET!,
});

export const initPaymentCron = () => {
  // Run every hour
  cron.schedule("0 * * * *", async () => {
    logger.info("[Cron] Running payment and subscription checks...");
    await checkExpiringSubscriptions();
    await syncPendingTransactions();
  });
};

const checkExpiringSubscriptions = async () => {
  try {
    const now = new Date();
    // Find premium users whose expiry is in the future
    const users = await User.find({
      isPremium: true,
      premiumUntil: { $gt: now },
      fcmToken: { $exists: true, $ne: "" },
    });

    for (const user of users) {
      const expiry = new Date(user.premiumUntil!);
      const remainingTime = expiry.getTime() - now.getTime();

      // Example: For a 30-day plan, 10% is 3 days.
      // We'll calculate 10% based on the last transaction or default plan durations (30 days / 180 days)
      // For simplicity, let's say "within 48 hours" or "last 10%"
      // Let's assume 30 days total for now if we don't have the starting date handy
      const totalDuration = 30 * 24 * 60 * 60 * 1000; // 30 days in ms
      const tenPercent = totalDuration * 0.1;

      if (remainingTime < tenPercent) {
        // Send notification if not sent in the last 24h
        // (This logic could be improved by storing lastNotificationSent in User model)
        await sendNotificationToDevice(
          user.fcmToken!,
          "Subscription Expiring Soon!",
          `Your premium status expires in ${Math.round(remainingTime / (1000 * 60 * 60))} hours. Renew now to stay premium!`,
          { type: "subscription_expiry" },
        );
      }
    }
  } catch (error) {
    logger.error("[Cron] Error in checkExpiringSubscriptions:", error);
  }
};

const syncPendingTransactions = async () => {
  try {
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    const pendingTxs = await Transaction.find({
      status: "pending",
      createdAt: { $lt: tenMinutesAgo },
    });

    for (const tx of pendingTxs) {
      if (!tx.paymentId) continue;

      try {
        // Fetch status from Razorpay
        // Note: Razorpay paymentId might be orderId or paymentId depending on how it's stored
        // If it's the orderId, we check payments for that order
        const order = await razorpay.orders.fetchPayments(tx.paymentId);
        const payments = (order as any).items || [];

        if (payments.length > 0) {
          const latestPayment = payments[0];
          if (latestPayment.status === "captured") {
            tx.status = "captured";
            await tx.save();

            // Also ensure user is premium
            const user = await User.findById(tx.userId);
            if (user && !user.isPremium) {
              user.isPremium = true;
              // Calculate new expiry...
              await user.save();
            }
            logger.info(
              `[Cron] Synced transaction ${tx.paymentId} to captured`,
            );
          } else if (latestPayment.status === "failed") {
            tx.status = "failed";
            await tx.save();
            logger.info(`[Cron] Synced transaction ${tx.paymentId} to failed`);
          }
        }
      } catch (err) {
        logger.error(`[Cron] Error syncing tx ${tx.paymentId}:`, err);
      }
    }
  } catch (error) {
    logger.error("[Cron] Error in syncPendingTransactions:", error);
  }
};
