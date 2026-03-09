import express from "express";
import cors from "cors";
import helmet from "helmet";
import mongoSanitize from "express-mongo-sanitize";
import hpp from "hpp";
import rateLimit from "express-rate-limit";
import dotenv from "dotenv";
import { createServer } from "http";
import path from "path";
import { Server } from "socket.io";
import connectDB from "@/config/db";
import { connectRedis } from "@/config/redis";
import { validateEnv } from "@/config/env";
import { initializeFirebase } from "@/utils/firebase";
import { router } from "@/routes";
import { initializeSocket } from "@/socket";
import logger from "@/utils/logger";
import { initPaymentCron } from "@/cron/payment.cron";
import { initNotificationCron } from "@/cron/notification.cron";
import { errorHandler } from "@/middleware/errorMiddleware";
import { requestIdMiddleware } from "@/middleware/requestIdMiddleware";
import { MetricsService } from "@/services/MetricsService";

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

    const app = express();
    const httpServer = createServer(app);

    // ===== SECURITY MIDDLEWARE (ORDER MATTERS) =====

    // 0. Request ID for tracing
    app.use(requestIdMiddleware);

    // 1. HTTP Security Headers (Helmet)
    app.use(helmet());

    // 2. CORS — Restrict to known origins
    const allowedOrigins = (
      process.env.ALLOWED_ORIGINS || "http://localhost:5173"
    )
      .split(",")
      .map((o) => o.trim());
    app.use(
      cors({
        origin: allowedOrigins,
        credentials: true,
      }),
    );

    // 3. Body Parsing with Size Limits (DDoS protection)
    app.use(express.json({ limit: "1mb" }));
    app.use(express.urlencoded({ extended: true, limit: "1mb" }));

    // 4. NoSQL Injection Sanitization
    app.use(mongoSanitize());

    // 5. HTTP Parameter Pollution protection
    app.use(hpp());

    // 6. Global Rate Limiting (100 requests per minute per IP)
    const globalLimiter = rateLimit({
      windowMs: 60 * 1000,
      max: 100,
      standardHeaders: true,
      legacyHeaders: false,
      message: { message: "Too many requests. Please try again later." },
    });
    app.use("/api/v1", globalLimiter);

    // 7. Request Logging (sanitize sensitive data)
    app.use((req, res, next) => {
      const sanitizedUrl = req.url.replace(/token=[^&]+/g, "token=***");
      logger.info(`${req.method} ${sanitizedUrl}`);
      next();
    });

    // Socket.io — Mobile apps don't send Origin headers,
    // so they bypass CORS. Web clients are restricted.
    const io = new Server(httpServer, {
      cors: {
        origin: (origin, callback) => {
          // Allow mobile apps (no origin) and whitelisted web origins
          if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
          } else {
            logger.warn(`[Socket] CORS blocked origin: ${origin}`);
            callback(new Error("CORS not allowed"));
          }
        },
        methods: ["GET", "POST"],
      },
      // Connection security
      pingTimeout: 20000,
      pingInterval: 25000,
      maxHttpBufferSize: 1e6, // 1MB max message size
    });

    // Make io accessible to our router/controllers
    app.set("io", io);

    // Serve static files from the "public" folder
    app.use(express.static(path.join(__dirname, "../public")));

    // Register Middleware and Routes
    app.use("/api/v1", router);
    app.get("/ping", (req, res) => res.send("pong"));

    // Serve HTML entry file for the root URL
    app.get("/", (req, res) => {
      res.sendFile(path.join(__dirname, "../public/index.html"));
    });

    // Global Error Handler
    app.use(errorHandler);

    // Initialize Socket.IO
    initializeSocket(io);

    const PORT = Number(process.env.PORT) || 5000;

    httpServer.listen(PORT, "0.0.0.0", () => {
      logger.info(`Server running on port ${PORT}`);
    });
  } catch (error) {
    logger.error("Failed to start server:", error);
    process.exit(1);
  }
};

// Catch unhandled rejections
process.on("unhandledRejection", (err) => {
  logger.error("UNHANDLED REJECTION! 💥 Shutting down...", err);
  console.error(err);
  process.exit(1);
});

// Catch uncaught exceptions
process.on("uncaughtException", (err) => {
  logger.error("UNCAUGHT EXCEPTION! 💥 Shutting down...", err);
  console.error(err);
  process.exit(1);
});

startServer();
