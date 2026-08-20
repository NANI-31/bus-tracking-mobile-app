import { Socket } from "socket.io";
import jwt from "jsonwebtoken";
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

export const authenticateSocket = (
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

  try {
    const decoded = jwt.verify(token as string, JWT_SECRET);
    socket.user = decoded;
    next();
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
    next(new Error("Authentication error: Invalid token"));
  }
};
