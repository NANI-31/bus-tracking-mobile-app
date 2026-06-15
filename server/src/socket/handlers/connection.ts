import { Server, Socket } from "socket.io";
import { AuthenticatedSocket } from "@/utils/socketAuth";
import logger from "@/utils/logger";

export const registerConnectionHandler = (io: Server, socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;
  const user = authSocket.user;

  if (user) {
    logger.info(
      `${user.fullName} (${user.role}) connected - Socket ${socket.id}`,
    );

    // If it's a driver, notify the college room
    if (user.role === "driver" && user.collegeId) {
      socket.to(user.collegeId).emit("driver_status_update", {
        driverId: user.id,
        status: "online",
      });
      logger.info(`${user.fullName} is ONLINE`);
    }

    // Join their own room for direct messages
    socket.join(user.id);
  } else {
    logger.info(`A user connected (unauthenticated): ${socket.id}`);
  }
};
