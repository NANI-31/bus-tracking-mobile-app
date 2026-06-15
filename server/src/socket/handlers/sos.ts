import { Server, Socket } from "socket.io";
import { AuthenticatedSocket } from "@/utils/socketAuth";
import logger from "@/utils/logger";

export const registerSosHandlers = (io: Server, socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;
  const user = authSocket.user;

  socket.on("trigger_sos", (data: any) => {
    if (user && user.collegeId) {
      const coordRoom = `${user.collegeId.toString()}_coordinators`;
      logger.info(
        `[Socket] SOS triggered by ${user.fullName}. Broadcasting to SOS room ${coordRoom}`,
      );
      socket.to(coordRoom).emit("sos_alert", data);
    }
  });

  socket.on("resolve_sos", (data: any) => {
    if (user && user.collegeId) {
      const coordRoom = `${user.collegeId.toString()}_coordinators`;
      logger.info(
        `[Socket] SOS resolved. Broadcasting to SOS room ${coordRoom}`,
      );
      socket.to(coordRoom).emit("sos_resolved", data);
    }
  });
};
