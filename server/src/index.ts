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
// app.use("/api/bus-numbers", busNumberRoutes); // Removed
app.use("/api/auth", authRoutes);

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
          <p>Time: ${new Date().toLocaleString()}</p>
        </div>
      </body>
    </html>
  `);
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
