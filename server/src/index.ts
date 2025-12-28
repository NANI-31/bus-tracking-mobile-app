import express from "express";
import dotenv from "dotenv";
import { createServer } from "http";
import { Server } from "socket.io";
import connectDB from "./config/db";
import { initializeFirebase } from "./utils/firebase";
import { registerRoutes } from "./routes";
import { initializeSocket } from "./socket";
import logger from "./utils/logger";

dotenv.config();

connectDB();
initializeFirebase();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*", // Allow all origins for mobile app
    methods: ["GET", "POST"],
  },
});

// Make io accessible to our router/controllers
app.set("io", io);

// Register Middleware and Routes
registerRoutes(app);

// Initialize Socket.IO
initializeSocket(io);

const PORT = Number(process.env.PORT) || 5000;

httpServer.listen(PORT, "0.0.0.0", () => {
  logger.info(`Server running on port ${PORT}`);
});
