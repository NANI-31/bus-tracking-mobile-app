import { Server, Socket } from "socket.io";
import { AuthenticatedSocket } from "@/utils/socketAuth";
import { Bus } from "@/models/Bus.model";
import { clearLastKnownPosition } from "./location";
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

            // Clear the stale GPS anchor for this driver's assigned bus so the
            // outlier guard does not reject the first coordinate of the next trip.
            try {
              const bus = await Bus.findOne({ driverId, assignmentStatus: 'accepted' });
              if (bus) {
                clearLastKnownPosition(bus._id.toString());
              }
            } catch (busErr) {
              logger.warn(`[Socket] Could not clear GPS anchor on driver disconnect: ${busErr}`);
            }
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
