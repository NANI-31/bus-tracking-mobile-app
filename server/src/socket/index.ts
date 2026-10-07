import { Server } from "socket.io";
import { createAdapter } from "@socket.io/redis-adapter";
import { pubClient, subClient } from "@/config/redis";
import { authenticateSocket } from "@/utils/socketAuth";
import { registerSocketHandlers } from "./handlers";

export { stopSocketInterval } from "./buffer";

let ioInstance: Server;

export const getIO = () => {
  if (!ioInstance) {
    throw new Error("Socket.io not initialized!");
  }
  return ioInstance;
};

export const initializeSocket = (io: Server) => {
  ioInstance = io;
  // Use Redis Adapter
  io.adapter(createAdapter(pubClient, subClient));

  // Socket.IO Connection Handling
  io.use(authenticateSocket); // Secure all connections

  io.on("connection", (socket) => {
    registerSocketHandlers(io, socket);
  });
};

/**
 * Disconnects all active WebSocket connections for a specific user across cluster.
 * Emits 'session_terminated' to the user's room and forcefully disconnects the sockets.
 */
export const disconnectUserSockets = (userId: string) => {
  if (!ioInstance) {
    return;
  }

  try {
    const userRoom = String(userId);
    // 1. Notify all client sockets belonging to this user
    ioInstance.to(userRoom).emit("session_terminated", {
      reason: "User logged out",
      timestamp: new Date().toISOString(),
    });

    // 2. Disconnect all sockets currently in this user's room across cluster/adapters
    ioInstance.in(userRoom).disconnectSockets(true);

    // 3. Fallback: inspect in-memory local sockets directly
    for (const [, socket] of ioInstance.sockets.sockets) {
      const socketUser = (socket as any).user;
      if (
        socketUser &&
        String(socketUser.id || socketUser._id) === String(userId)
      ) {
        socket.disconnect(true);
      }
    }
  } catch (err) {
    console.error(`[Socket] Error terminating sockets for user ${userId}:`, err);
  }
};

