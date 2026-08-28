import { Server, Socket } from "socket.io";
import { AuthenticatedSocket } from "@/utils/socketAuth";
import { Bus, BusLocation } from "@/models/Bus.model";
import logger from "@/utils/logger";
import { locationBuffer } from "../buffer";

export const registerTrackingHandlers = (io: Server, socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;
  const user = authSocket.user;

  socket.on("join_college", async (collegeId: string) => {
    socket.join(collegeId);

    logger.info(
      `[Socket Debug] join_college called. CollegeId: ${collegeId}. User: ${
        user ? user.fullName : "Unknown"
      }, Role: ${user ? user.role : "N/A"}`,
    );

    // If user is a coordinator or admin, join the coordinators, logs, and terminal logs rooms
    if (
      user &&
      (user.role === "busCoordinator" ||
        user.role === "coordinator" ||
        user.role === "superAdmin" ||
        user.role === "collegeAdmin")
    ) {
      const coordRoom = `${collegeId}_coordinators`;
      const logsRoom = `${collegeId}_audit_logs`;
      socket.join(coordRoom);
      socket.join(logsRoom);
      socket.join("server_terminal_logs");
      logger.info(
        `[Socket] User ${user.fullName} (${user.role}) joined SOS, Log, and Terminal rooms: ${coordRoom}, ${logsRoom}`,
      );
    } else if (user && user.role === "superAdmin") {
      socket.join("global_audit_logs");
      socket.join("server_terminal_logs");
      logger.info(`[Socket] Super Admin ${user.fullName} joined global and terminal logs`);
    } else {
      logger.info(
        `[Socket Debug] User ${
          user ? user.fullName : "Unknown"
        } DID NOT join coordinator room. Role mismatch or user missing.`,
      );
    }

    logger.info(
      `[Socket] ${user?.fullName || "User"} joined room: ${collegeId}`,
    );

    // ONLINE DRIVERS PUSH:
    if (
      user &&
      (user.role === "busCoordinator" ||
        user.role === "coordinator" ||
        user.role === "superAdmin")
    ) {
      try {
        const sockets = await io.in(collegeId).fetchSockets();
        sockets.forEach((s: any) => {
          const sUser = (s as any).user;
          if (sUser && sUser.role === "driver") {
            socket.emit("driver_status_update", {
              driverId: sUser.id,
              status: "online",
            });
          }
        });
      } catch (fetchErr) {
        logger.warn(
          `[Socket] fetchSockets timed out for room ${collegeId}, skipping online drivers push`,
        );
      }
    }

    // IMMEDIATE LOCATION PUSH:
    // Use assignmentStatus:'accepted' — the true real-time activity indicator.
    // isActive is an administrative flag; a bus can be operationally live even
    // when isActive is false. Filtering by isActive here would hide accepted buses.
    try {
      const buses = await Bus.find({ collegeId, assignmentStatus: 'accepted' });
      const busIds = buses.map((b) => b._id.toString());
      const busIdSet = new Set(busIds);

      if (busIds.length > 0) {
        const liveLocations: any[] = [];
        const processedBusIds = new Set<string>();

        // 1. Get Buffered Locations (RAM)
        locationBuffer.forEach((loc, bid) => {
          if (busIdSet.has(bid)) {
            liveLocations.push({
              busId: bid,
              collegeId: collegeId,
              location: { lat: loc.lat, lng: loc.lng },
              currentLocation: { lat: loc.lat, lng: loc.lng },
              speed: loc.speed,
              heading: loc.heading,
              timestamp: loc.timestamp,
            });
            processedBusIds.add(bid);
          }
        });

        // 2. Get DB Locations (Disk)
        const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
        const dbLocations = await BusLocation.aggregate([
          {
            $match: {
              busId: { $in: busIds },
              timestamp: { $gte: fifteenMinutesAgo },
            },
          },
          { $sort: { timestamp: -1 } },
          {
            $group: {
              _id: "$busId",
              latestLocation: { $first: "$$ROOT" },
            },
          },
        ]);

        // 3. Merge
        dbLocations.forEach((l) => {
          const locData = l.latestLocation;
          if (!processedBusIds.has(locData.busId)) {
            liveLocations.push({
              busId: locData.busId,
              collegeId: collegeId,
              location: {
                lat: locData.currentLocation?.lat,
                lng: locData.currentLocation?.lng,
              },
              currentLocation: {
                lat: locData.currentLocation?.lat,
                lng: locData.currentLocation?.lng,
              },
              speed: locData.speed,
              heading: locData.heading,
              timestamp: locData.timestamp,
            });
          }
        });

        if (liveLocations.length > 0) {
          liveLocations.forEach((payload) => {
            socket.emit("location_updated", payload);
          });
        }
      }
    } catch (err) {
      logger.error(`[Socket] Error fetching initial locations: ${err}`);
    }
  });

  socket.on("join_global_tracking", async () => {
    if (user && user.role === "superAdmin") {
      socket.join("global_tracking");
      socket.join("global_sos");
      socket.join("global_audit_logs");
      socket.join("server_terminal_logs");

      try {
        // Same reasoning as join_college: filter by assignmentStatus, not isActive.
        const buses = await Bus.find({ assignmentStatus: 'accepted' });
        const busIds = buses.map((b) => b._id.toString());

        const recentLocations = await BusLocation.aggregate([
          {
            $match: {
              busId: { $in: busIds },
              timestamp: { $gte: new Date(Date.now() - 15 * 60 * 1000) },
            },
          },
          { $sort: { timestamp: -1 } },
          { $group: { _id: "$busId", latestLocation: { $first: "$$ROOT" } } },
        ]);

        recentLocations.forEach((loc) => {
          const bus = buses.find((b) => b._id.toString() === loc._id);
          socket.emit("location_updated", {
            busId: loc._id,
            collegeId: bus?.collegeId,
            location: loc.latestLocation.currentLocation,
            speed: loc.latestLocation.speed,
            heading: loc.latestLocation.heading,
            timestamp: loc.latestLocation.timestamp,
          });
        });
      } catch (err) {
        logger.error(`[Socket] Error fetching global locations: ${err}`);
      }
    }
  });

  socket.on("join_terminal_logs", () => {
    if (user && (user.role === "superAdmin" || user.role === "collegeAdmin")) {
      socket.join("server_terminal_logs");
      logger.info(`[Socket] User ${user.fullName} (${user.role}) explicitly joined server_terminal_logs`);
    }
  });

  socket.on("leave_terminal_logs", () => {
    socket.leave("server_terminal_logs");
    if (user) {
      logger.info(`[Socket] User ${user.fullName} (${user.role}) left server_terminal_logs`);
    }
  });
};
