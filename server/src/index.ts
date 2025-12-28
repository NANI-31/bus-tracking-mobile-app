import express, { Request, Response, NextFunction } from "express";
import dotenv from "dotenv";
import cors from "cors";
import { createServer } from "http";
import { Server } from "socket.io";
import { LRUCache } from "lru-cache";
import { RateLimiterMemory } from "rate-limiter-flexible";
import rateLimit from "express-rate-limit";

import connectDB from "./config/db";
import { initializeFirebase } from "./utils/firebase";
import { authenticateSocket, AuthenticatedSocket } from "./utils/socketAuth";
import logger from "./utils/logger";

import userRoutes from "./routes/userRoutes";
import busRoutes from "./routes/busRoutes";
import collegeRoutes from "./routes/collegeRoutes";
import routeRoutes from "./routes/routeRoutes";
import scheduleRoutes from "./routes/scheduleRoutes";
import notificationRoutes from "./routes/notificationRoutes";
import authRoutes from "./routes/authRoutes";
import assignmentRoutes from "./routes/assignmentRoutes";
import sosRoutes from "./routes/sosRoutes";
import incidentRoutes from "./routes/incidentRoutes";
import historyRoutes from "./routes/historyRoutes";
import { Bus } from "./models/Bus";
import { checkAndNotifyBusNearby } from "./utils/busNearbyLogic";

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

app.use(
  cors({
    origin: true, // Allow any origin dynamically
    credentials: true, // Allow cookies/auth headers
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
  })
);

app.use(express.json());

// Rate Limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many requests from this IP, please try again after 15 minutes",
});

// Apply rate limiting to all API routes
app.use("/api/", apiLimiter);

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  logger.info(`${req.method} ${req.url}`);
  if (Object.keys(req.body).length > 0) {
    logger.info("📝 Body:", JSON.stringify(req.body, null, 2));
  }

  // Response logger
  res.on("finish", () => {
    const duration = Date.now() - start;
    const status = res.statusCode;
    const color = status >= 500 ? "🔴" : status >= 400 ? "🟡" : "🟢";
    logger.info(
      `[Response] ${color} ${status} ${req.method} ${req.url} - ${duration}ms`
    );
  });
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
app.use("/api/sos", sosRoutes);
app.use("/api/incidents", incidentRoutes);
app.use("/api/history", historyRoutes);

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
  const authSocket = socket as AuthenticatedSocket;
  const user = authSocket.user;

  // Log connection
  if (user) {
    console.log(
      `User connected: ${user.id} (${user.role}) - Socket ${socket.id}`
    );

    // If it's a driver, notify the college room
    if (user.role === "driver" && user.collegeId) {
      socket.to(user.collegeId).emit("driver_status_update", {
        driverId: user.id,
        status: "online",
      });
      console.log(`Driver ${user.id} is ONLINE`);
    }

    // Join their own room for direct messages
    socket.join(user.id);
  } else {
    console.log("A user connected (unauthenticated):", socket.id);
  }

  socket.on("join_college", (collegeId) => {
    socket.join(collegeId);
    console.log(
      `[Socket] User ${socket.id} (User: ${user?.id}) joined room: ${collegeId}`
    );
    // Debug: list rooms for this socket
    console.log(
      `[Socket] Current rooms for ${socket.id}:`,
      Array.from(socket.rooms)
    );
  });

  socket.on("bus_list_updated", () => {
    if (user && user.collegeId) {
      console.log(
        `[Socket] Received bus_list_updated from ${user.id}. Broadcasting to room ${user.collegeId}`
      );
      socket.to(user.collegeId.toString()).emit("bus_list_updated");
    } else {
      console.log(
        `[Socket] bus_list_updated received but user or collegeId missing. User: ${user?.id}`
      );
    }
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
    if (user && user.role === "driver" && user.collegeId) {
      socket.to(user.collegeId).emit("driver_status_update", {
        driverId: user.id,
        status: "offline",
      });
      console.log(`Driver ${user.id} is OFFLINE`);
    }
  });
});

// Global error error-handling middleware
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error("💥 Global Error:", err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || "Internal Server Error",
    error: process.env.NODE_ENV === "development" ? err : {},
  });
});

const PORT = Number(process.env.PORT) || 5000;

httpServer.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
