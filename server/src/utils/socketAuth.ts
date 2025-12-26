import { Socket } from "socket.io";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET && process.env.NODE_ENV === "production") {
  throw new Error("JWT_SECRET must be set in production environment");
}
const DEFAULT_SECRET = "your_jwt_secret_key_change_in_production";

export interface AuthenticatedSocket extends Socket {
  user?: any;
}

export const authenticateSocket = (
  socket: AuthenticatedSocket,
  next: (err?: any) => void
) => {
  const token = socket.handshake.auth.token || socket.handshake.query.token;

  if (!token) {
    return next(new Error("Authentication error: Token required"));
  }

  try {
    const decoded = jwt.verify(token as string, JWT_SECRET || DEFAULT_SECRET);
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error("Authentication error: Invalid token"));
  }
};
