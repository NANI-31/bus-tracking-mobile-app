import express from "express";
import dotenv from "dotenv";
import { createServer } from "http";
import { Server } from "socket.io";
import connectDB from "./config/db";
import { connectRedis } from "./config/redis";
import { initializeFirebase } from "./utils/firebase";
import { router } from "./routes";
import { initializeSocket } from "./socket";
import logger from "./utils/logger";
import { errorHandler } from "./middleware/errorMiddleware";

dotenv.config();

const startServer = async () => {
  try {
    await connectDB();
    await connectRedis();
    initializeFirebase();

    const app = express();
    const httpServer = createServer(app);

    // Request Logging Middleware
    app.use((req, res, next) => {
      logger.info(`${req.method} ${req.url}`);
      next();
    });

    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));

    const io = new Server(httpServer, {
      cors: {
        origin: "*", // Allow all origins for mobile app
        methods: ["GET", "POST"],
      },
    });

    // Make io accessible to our router/controllers
    app.set("io", io);

    // Register Middleware and Routes
    app.use("/api/v1", router);
    app.get("/ping", (req, res) => res.send("pong"));

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
  logger.error("UNHANDLED REJECTION! 💥 Shutting down...");
  console.error(err);
  process.exit(1);
});

// Catch uncaught exceptions
process.on("uncaughtException", (err) => {
  logger.error("UNCAUGHT EXCEPTION! 💥 Shutting down...");
  console.error(err);
  process.exit(1);
});

startServer();
