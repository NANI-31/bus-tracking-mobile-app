import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import User from "@/models/User.model";
import logger from "@/utils/logger";
import {
  logSessionExpiry,
  SessionExpiryReason,
} from "@/utils/sessionExpiryLogger";

const JWT_SECRET = process.env.JWT_SECRET!;
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET!;

/**
 * Controller to handle token refreshing.
 * Validates the refresh token and issues a new short-lived access token.
 */
export const refreshToken = async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ message: "Refresh token is required" });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, REFRESH_TOKEN_SECRET) as any;

    // Check if user still exists
    const user = await User.findById(decoded.id);

    if (!user) {
      logSessionExpiry({
        reason: SessionExpiryReason.UserDeleted,
        decoded,
        req,
      });
      return res.status(401).json({ message: "User no longer exists" });
    }

    // Security: Check tokenVersion to allow revoking all tokens (global logout)
    if (
      decoded.tokenVersion !== undefined &&
      decoded.tokenVersion !== user.tokenVersion
    ) {
      logger.warn(`Refresh token version mismatch for user ${user.email}`);
      logSessionExpiry({
        reason: SessionExpiryReason.TokenVersionMismatch,
        decoded,
        dbUser: user,
        req,
      });
      return res.status(401).json({
        message: "Session expired. Please login again.",
        code: "SESSION_EXPIRED",
      });
    }

    // Issue new access token (15 minutes)
    const accessToken = jwt.sign(
      {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        collegeId: user.collegeId,
        approved: user.approved,
        tokenVersion: user.tokenVersion,
      },
      JWT_SECRET,
      { expiresIn: "2h" },
    );

    res.json({
      success: true,
      accessToken,
    });
  } catch (error: any) {
    logger.warn(`Refresh token validation failed: ${error.message}`);
    // Decode without verifying to capture forensic metadata
    let partialDecoded: any;
    try {
      partialDecoded = jwt.decode(req.body?.refreshToken);
    } catch (_) {}
    logSessionExpiry({
      reason: SessionExpiryReason.RefreshTokenFailed,
      decoded: partialDecoded,
      error,
      req,
    });
    res.status(401).json({
      message: "Invalid or expired refresh token",
      code: "INVALID_REFRESH_TOKEN",
    });
  }
};
