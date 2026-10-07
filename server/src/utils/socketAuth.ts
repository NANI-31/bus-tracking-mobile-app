import { Socket } from "socket.io";
import jwt from "jsonwebtoken";
import User from "@/models/User.model";
import logger from "@/utils/logger";
import {
  logSessionExpiry,
  SessionExpiryReason,
} from "@/utils/sessionExpiryLogger";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error("JWT_SECRET must be set in production environment");
}

export interface AuthenticatedSocket extends Socket {
  user?: any;
}

export const authenticateSocket = async (
  socket: AuthenticatedSocket,
  next: (err?: any) => void
) => {
  const token = socket.handshake.auth.token || socket.handshake.query.token;

  // Common socket metadata extracted for logging
  const socketMeta = {
    platform:
      (socket.handshake.auth.platform as string) ||
      (socket.handshake.query.platform as string) ||
      undefined,
    appVersion:
      (socket.handshake.auth.appVersion as string) ||
      (socket.handshake.query.appVersion as string) ||
      undefined,
    clientIp: socket.handshake.address || undefined,
  };

  if (!token) {
    logSessionExpiry({
      reason: SessionExpiryReason.NoToken,
      socketMeta,
    });
    return next(new Error("Authentication error: Token required"));
  }

  let decoded: any;
  try {
    decoded = jwt.verify(token as string, JWT_SECRET);
  } catch (err: any) {
    // Decode without verifying to capture token forensics
    let partialDecoded: any;
    try {
      partialDecoded = jwt.decode(token as string);
    } catch (_) {}

    logSessionExpiry({
      reason: SessionExpiryReason.SocketAuthFailed,
      decoded: partialDecoded,
      error: err,
      socketMeta,
    });
    return next(new Error("Authentication error: Invalid token"));
  }

  try {
    // Validate that user exists and tokenVersion matches current DB record
    const user = await User.findById(decoded.id).select(
      "tokenVersion approved isLoggedIn"
    );
    if (!user) {
      logger.warn(`[SocketAuth] Auth rejected: User ${decoded.id} no longer exists`);
      logSessionExpiry({
        reason: SessionExpiryReason.UserDeleted,
        decoded,
        socketMeta,
      });
      return next(new Error("Authentication error: User no longer exists"));
    }

    if (
      decoded.tokenVersion !== undefined &&
      decoded.tokenVersion !== user.tokenVersion
    ) {
      logger.warn(
        `[SocketAuth] Auth rejected: tokenVersion mismatch for user ${decoded.id}. Token: ${decoded.tokenVersion}, DB: ${user.tokenVersion}`
      );
      logSessionExpiry({
        reason: SessionExpiryReason.TokenVersionMismatch,
        decoded,
        dbUser: user,
        socketMeta,
      });
      return next(new Error("Authentication error: Session expired"));
    }

    socket.user = decoded;
    next();
  } catch (dbErr: any) {
    logger.error(`[SocketAuth] Database error during socket authentication:`, dbErr);
    return next(new Error("Authentication error: Internal error"));
  }
};
