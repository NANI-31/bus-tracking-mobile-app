import { Server, Socket } from "socket.io";
import { AuthenticatedSocket } from "@/utils/socketAuth";
import logger from "@/utils/logger";

export const registerDisconnectHandler = (io: Server, socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;
  const user = authSocket.user;

  socket.on("disconnect", (reason: string) => {
    if (user) {
      logger.info(
        `${user.fullName || "User"} disconnected (reason: ${reason}) - Socket ${socket.id}`,
      );
    } else {
      logger.info(`User disconnected: ${socket.id} (reason: ${reason})`);
    }

    if (user && user.role === "driver" && user.collegeId) {
      const collegeRoom = user.collegeId.toString();
      const driverId = user.id;
      const driverName = user.fullName || "Driver";

      const disconnectDelay = process.env.NODE_ENV === "test" ? 100 : 30000;
      
      setTimeout(async () => {
        try {
          const sockets = await io.in(collegeRoom).fetchSockets();
          const isStillConnected = sockets.some((s: any) => {
            const sUser = (s as any).user;
            return sUser && sUser.id === driverId;
          });

          if (!isStillConnected) {
            io.to(collegeRoom).emit("driver_status_update", {
              driverId,
              status: "offline",
            });
            logger.info(
              `${driverName} is OFFLINE (confirmed after grace period)`,
            );
          } else {
            logger.info(
              `${driverName} reconnected within grace period, skipping offline emit`,
            );
          }
        } catch (err) {
          logger.warn(`[Socket] Error checking driver reconnect: ${err}`);
        }
      }, disconnectDelay);
    }
  });
};
