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
