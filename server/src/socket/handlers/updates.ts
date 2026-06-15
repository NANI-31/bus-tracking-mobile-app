import { Server, Socket } from "socket.io";
import { AuthenticatedSocket } from "@/utils/socketAuth";
import logger from "@/utils/logger";

export const registerUpdateHandlers = (io: Server, socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;
  const user = authSocket.user;

  socket.on("bus_list_updated", () => {
    if (user && user.collegeId) {
      logger.info(
        `[Socket] Received bus_list_updated from ${user.fullName}. Broadcasting to room ${user.collegeId}`,
      );
      socket.to(user.collegeId.toString()).emit("bus_list_updated");
    }
  });

  socket.on("user_list_updated", () => {
    if (user && user.collegeId) {
      logger.info(
        `[Socket] Received user_list_updated from ${user.fullName}. Broadcasting to room ${user.collegeId}`,
      );
      socket.to(user.collegeId.toString()).emit("user_list_updated");
    }
  });
};
