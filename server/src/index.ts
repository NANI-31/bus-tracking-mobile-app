import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import connectDB from "./config/db";

import userRoutes from "./routes/userRoutes";
import busRoutes from "./routes/busRoutes";
import collegeRoutes from "./routes/collegeRoutes";
import routeRoutes from "./routes/routeRoutes";
import scheduleRoutes from "./routes/scheduleRoutes";
import notificationRoutes from "./routes/notificationRoutes";
import busNumberRoutes from "./routes/busNumberRoutes";
import authRoutes from "./routes/authRoutes";

dotenv.config();

connectDB();

const app = express();

app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  if (Object.keys(req.body).length > 0) {
    console.log("Body:", JSON.stringify(req.body, null, 2));
  }
  if (Object.keys(req.query).length > 0) {
    console.log("Query:", JSON.stringify(req.query, null, 2));
  }
  next();
});

app.use("/api/users", userRoutes);
app.use("/api/buses", busRoutes);
app.use("/api/colleges", collegeRoutes);
app.use("/api/routes", routeRoutes);
app.use("/api/schedules", scheduleRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/bus-numbers", busNumberRoutes);
app.use("/api/auth", authRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
