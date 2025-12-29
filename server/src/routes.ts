import express, { Express, Request, Response, NextFunction } from "express";
import cors from "cors";
import rateLimit from "express-rate-limit";
import logger from "./utils/logger";
import path from "path";

// Import aggregated routes
import apiRouter from "./routes/index";

export const registerRoutes = (app: Express) => {
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
  // Request logging middleware (Moved up to capture all requests)
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

  // Rate Limiting (DISABLED FOR DEBUGGING)
  /*
  const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: "Too many requests",
  });
  app.use("/api/", apiLimiter);
  */

  // Mount Unified API Routes
  app.use("/api", apiRouter);

  // Static files and Root route
  app.use(express.static(path.join(__dirname, "../public"))); // Adjusted path for src/ folder
  app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname, "../public", "index.html"));
  });

  // Global error error-handling middleware
  app.use((err: any, req: Request, res: Response, next: NextFunction) => {
    logger.error("💥 Global Error:", err);
    res.status(err.status || 500).json({
      success: false,
      message: err.message || "Internal Server Error",
      error: process.env.NODE_ENV === "development" ? err : {},
    });
  });
};
