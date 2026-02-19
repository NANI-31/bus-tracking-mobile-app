import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import logger from "../utils/logger";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error("JWT_SECRET must be set in environment variables");
}

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
    fullName?: string;
    collegeId: any;
  };
}

export const protect = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    try {
      token = req.headers.authorization.split(" ")[1];
      const decoded = jwt.verify(token, JWT_SECRET) as any;

      // Check if user still exists and tokenVersion matches
      const User = require("../models/User.model").default;
      const user = await User.findById(decoded.id);

      if (!user) {
        logger.warn(`Auth failed: User ${decoded.id} no longer exists`);
        return res.status(401).json({ message: "User no longer exists" });
      }

      if (
        decoded.tokenVersion !== undefined &&
        decoded.tokenVersion !== user.tokenVersion
      ) {
        logger.warn(
          `Auth failed: tokenVersion mismatch for user ${user.email}. Token: ${decoded.tokenVersion}, DB: ${user.tokenVersion}`,
        );
        return res.status(401).json({
          message:
            "Session expired. You have been logged in on another device.",
          code: "SESSION_EXPIRED",
        });
      }

      req.user = {
        id: decoded.id,
        email: decoded.email,
        role: decoded.role,
        fullName: decoded.fullName,
        collegeId: decoded.collegeId,
      };

      next();
    } catch (error: any) {
      console.error("Token verification failed:", error);

      // Distinguish between actual token issues and system errors (like DB disconnection)
      const isJwtError =
        error.name === "JsonWebTokenError" ||
        error.name === "TokenExpiredError" ||
        error.name === "NotBeforeError";

      if (isJwtError) {
        return res.status(401).json({
          message: "Session expired or invalid token.",
          code: "SESSION_EXPIRED",
        });
      }

      // For database errors (MongoServerSelectionError, etc.) or other system issues,
      // return 500 so the app doesn't force a logout (which 401 triggers).
      res.status(500).json({
        message: "Internal server error during authentication check.",
        code: "SERVER_ERROR",
      });
    }
  }

  if (!token) {
    res.status(401).json({ message: "Not authorized, no token" });
  }
};

export const authorize = (...roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        message: `User role '${req.user.role}' is not authorized to access this route`,
      });
    }
    next();
  };
};

export const superAdminOnly = authorize("superAdmin");

export const collegeAdminOnly = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) => {
  if (!req.user) {
    return res.status(401).json({ message: "Not authenticated" });
  }

  if (req.user.role === "superAdmin") {
    return next(); // Super admin can access anything
  }

  if (req.user.role !== "collegeAdmin") {
    return res.status(403).json({ message: "College Admin access required" });
  }

  // Cross-tenant check: If collegeId is present in params/body, it must match user's collegeId
  const targetCollegeId =
    req.params.collegeId || req.body.collegeId || req.query.collegeId;

  if (
    targetCollegeId &&
    targetCollegeId.toString() !== req.user.collegeId.toString()
  ) {
    return res.status(403).json({
      message: "Access denied. You can only manage your own college.",
    });
  }

  next();
};
