import dotenv from "dotenv";
import connectDB from "@/config/db";
import { connectRedis } from "@/config/redis";
import { validateEnv } from "@/config/env";
import { initializeFirebase } from "@/utils/firebase";
import { initPaymentCron } from "@/cron/payment.cron";
import { initNotificationCron } from "@/cron/notification.cron";
import logger from "@/utils/logger";
import { MetricsService } from "@/services/MetricsService";
import { createApp } from "./app";
import Plan from "@/models/Plan.model";

dotenv.config();
validateEnv();

const seedPlansIfEmpty = async () => {
  try {
    const count = await Plan.countDocuments();
    if (count === 0) {
      logger.info("Plans collection is empty. Seeding default plans...");
      const defaultPlans = [
        {
          name: "Standard Monthly",
          alias: "standard_30",
          price: 10,
          durationDays: 30,
          features: ["Live Tracking", "Basic Alerts", "Route Viewing"],
          isActive: true,
          isBestValue: false,
        },
        {
          name: "Standard Yearly",
          alias: "standard_365",
          price: 100,
          durationDays: 365,
          features: [
            "Live Tracking",
            "Basic Alerts",
            "Route Viewing",
            "Priority Support",
          ],
          isActive: true,
          isBestValue: true,
        },
        {
          name: "Premium Monthly",
          alias: "premium_30",
          price: 20,
          durationDays: 30,
          features: [
            "Live Tracking",
            "Advanced Alerts",
            "Ad-Free Experience",
            "Route Insights",
          ],
          isActive: true,
          isBestValue: false,
        },
        {
          name: "Premium Yearly",
          alias: "premium_365",
          price: 200,
          durationDays: 365,
          features: [
            "Live Tracking",
            "Advanced Alerts",
            "Ad-Free Experience",
            "Route Insights",
            "Priority Support",
            "Family Sharing",
          ],
          isActive: true,
          isBestValue: true,
        },
      ];
      await Plan.insertMany(defaultPlans);
      logger.info("✅ Default plans seeded successfully.");
    }
  } catch (error) {
    logger.error("Error checking/seeding plans on startup:", error);
  }
};

const startServer = async () => {
  try {
    await connectDB();
    await seedPlansIfEmpty();
    await connectRedis();
    initializeFirebase();
    MetricsService.init();
    initPaymentCron();
    initNotificationCron();

    const { httpServer } = createApp();

    const PORT = process.env.PORT ? parseInt(process.env.PORT) : 5000;

    httpServer.listen(PORT, "0.0.0.0", () => {
      logger.info(`[Render] Server identified and listening on port: ${PORT}`);
    });
  } catch (error) {
    logger.error("Failed to start server:", error);
    process.exit(1);
  }
};

process.on("unhandledRejection", (err) => {
  logger.error("UNHANDLED REJECTION! 💥 Shutting down...", err);
  process.exit(1);
});

process.on("uncaughtException", (err) => {
  logger.error("UNCAUGHT EXCEPTION! 💥 Shutting down...", err);
  process.exit(1);
});

startServer();
