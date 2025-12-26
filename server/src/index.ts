import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import { createServer } from "http";
import { Server } from "socket.io";
import connectDB from "./config/db";
import { initializeFirebase } from "./utils/firebase";
import { LRUCache } from "lru-cache";
import { RateLimiterMemory } from "rate-limiter-flexible";

import userRoutes from "./routes/userRoutes";
import busRoutes from "./routes/busRoutes";
import collegeRoutes from "./routes/collegeRoutes";
import routeRoutes from "./routes/routeRoutes";
import scheduleRoutes from "./routes/scheduleRoutes";
import notificationRoutes from "./routes/notificationRoutes";
import authRoutes from "./routes/authRoutes";
import assignmentRoutes from "./routes/assignmentRoutes";
import logger from "./utils/logger";

dotenv.config();

connectDB();
initializeFirebase();

import { authenticateSocket } from "./utils/socketAuth";

// LRU cache for bus metadata (max 500 entries, 30 min TTL)
const busCache = new LRUCache<
  string,
  { busNumber: string; routeId: string | null }
>({
  max: 500,
  ttl: 1000 * 60 * 30,
});

// Rate limiter for socket events (10 updates per 5 seconds per socket)
const rateLimiter = new RateLimiterMemory({
  points: 10,
  duration: 5,
});

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`);
  if (Object.keys(req.body).length > 0) {
    logger.info("📝 Body:", JSON.stringify(req.body, null, 2));
  }
  if (Object.keys(req.query).length > 0) {
    logger.info("🔍 Query:", JSON.stringify(req.query, null, 2));
  }
  next();
});

app.use("/api/users", userRoutes);
app.use("/api/buses", busRoutes);
app.use("/api/colleges", collegeRoutes);
app.use("/api/routes", routeRoutes);
app.use("/api/schedules", scheduleRoutes);
app.use("/api/notifications", notificationRoutes);
// app.use("/api/bus-numbers", busNumberRoutes); // Removed
app.use("/api/auth", authRoutes);
app.use("/api/assignments", assignmentRoutes);

app.get("/", (req, res) => {
  res.setHeader("Content-Type", "text/html");
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Server Status</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            background: #0f172a;
            color: #38bdf8;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
          }
          .card {
            background: #020617;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(56,189,248,0.3);
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>🚀 Server is Running</h1>
          <p>Status: <strong>Online</strong></p>
          <p>Real-time: <strong>Socket.io Active</strong></p>
          <p>Time: ${new Date().toLocaleString()}</p>
        </div>
      </body>
    </html>
  `);
});

// Socket.IO Connection Handling
io.use(authenticateSocket); // Secure all connections

io.on("connection", (socket) => {
  console.log("A user connected:", socket.id);

  socket.on("join_college", (collegeId) => {
    socket.join(collegeId);
    console.log(`User ${socket.id} joined college room: ${collegeId}`);
  });

  socket.on("update_location", async (data) => {
    // data: { busId, collegeId, location: { lat, lng }, speed, heading }
    const { collegeId } = data;
    // Broadcast to everyone in the same college room
    socket.to(collegeId).emit("location_updated", data);
    console.log(
      `Location update for bus ${data.busId} in college ${collegeId}`
    );

    // Check for nearby stops and notify users
    try {
      // Apply rate limiting per socket ID
      await rateLimiter.consume(socket.id);

      const { Bus } = require("./models/Bus");
      const { checkAndNotifyBusNearby } = require("./utils/busNearbyLogic");

      let busDetails = busCache.get(data.busId);

      if (busDetails) {
        if (busDetails.routeId) {
          checkAndNotifyBusNearby(
            data.busId,
            busDetails.busNumber,
            data.location.lat,
            data.location.lng,
            busDetails.routeId
          );
        }
      } else {
        // Correctly handle the promise and update cache
        const bus = await Bus.findById(data.busId);
        if (bus) {
          busDetails = {
            busNumber: bus.busNumber,
            routeId: bus.routeId ? bus.routeId.toString() : null,
          };
          busCache.set(data.busId, busDetails);

          if (busDetails.routeId) {
            checkAndNotifyBusNearby(
              data.busId,
              busDetails.busNumber,
              data.location.lat,
              data.location.lng,
              busDetails.routeId
            );
          }
        }
      }
    } catch (error) {
      if (error instanceof Error) {
        console.error("Error in update_location:", error.message);
      } else {
        // This is likely a rate limit rejection
        console.log(`Rate limit exceeded for socket ${socket.id}`);
      }
    }
  });

  socket.on("disconnect", () => {
    console.log("User disconnected:", socket.id);
  });
});

const PORT = Number(process.env.PORT) || 5000;

httpServer.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
