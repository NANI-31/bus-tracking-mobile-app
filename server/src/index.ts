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

dotenv.config();
validateEnv();

const startServer = async () => {
  try {
    await connectDB();
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
