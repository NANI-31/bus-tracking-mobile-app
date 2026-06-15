import express from "express";
import cors from "cors";
import helmet from "helmet";
import mongoSanitize from "express-mongo-sanitize";
import hpp from "hpp";
import rateLimit from "express-rate-limit";
import path from "path";
import { Server } from "socket.io";
import { createServer } from "http";
import { router } from "@/routes";
import { initializeSocket } from "@/socket/index";
import logger from "@/utils/logger";
import { errorHandler } from "@/middleware/errorMiddleware";
import { requestIdMiddleware } from "@/middleware/requestIdMiddleware";

export const createApp = () => {
  const app = express();
  app.set("trust proxy", 1); // Trust Render load balancer proxy
  const httpServer = createServer(app);

  // ===== SECURITY MIDDLEWARE =====
  app.use(requestIdMiddleware);
  app.use(helmet());

  // for more production url's
//   const allowedOrigins = [
//   "http://localhost:5173",
//   "http://localhost:3000",
//   ...(process.env.VITE_CLIENT_URL || "")
//     .split(",")
//     .map((o) => o.trim())
//     .filter(Boolean),
// ];
  const allowedOrigins = [
    "http://localhost:5173",
    "http://localhost:3000",
    `http://${process.env.VITE_CLIENT_IP_URL}`,
    (process.env.VITE_CLIENT_URL || "").trim(),
  ].filter(Boolean);

  app.use(
    cors({
      origin: allowedOrigins,
      credentials: true,
    }),
  );

  app.use(express.json({ limit: "1mb" }));
  app.use(express.urlencoded({ extended: true, limit: "1mb" }));
  app.use(mongoSanitize());
  app.use(hpp());

  const globalLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: "Too many requests. Please try again later." },
  });
  app.use("/api/v1", globalLimiter);

  app.use((req, res, next) => {
    const sanitizedUrl = req.url.replace(/token=[^&]+/g, "token=***");
    logger.info(`${req.method} ${sanitizedUrl}`);
    next();
  });

  const io = new Server(httpServer, {
    cors: {
      origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin) || process.env.NODE_ENV === "development") {
          callback(null, true);
        } else {
          logger.warn(`[Socket] CORS blocked origin: ${origin}`);
          callback(new Error("CORS not allowed"));
        }
      },
      methods: ["GET", "POST"],
    },
    pingTimeout: 20000,
    pingInterval: 25000,
    maxHttpBufferSize: 1e6,
  });

  app.set("io", io);
  app.use(express.static(path.join(__dirname, "../public")));
  app.use("/api/v1", router);
  app.get("/ping", (req, res) => res.send("pong"));
  app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname, "../public/index.html"));
  });

  app.use(errorHandler);
  initializeSocket(io);

  return { app, httpServer, io };
};
