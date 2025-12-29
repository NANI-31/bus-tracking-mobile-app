import { Server } from "socket.io";
import { LRUCache } from "lru-cache";
import { RateLimiterMemory } from "rate-limiter-flexible";
import { authenticateSocket, AuthenticatedSocket } from "./utils/socketAuth";
import { Bus, BusLocation } from "./models/Bus";
import { checkAndNotifyBusNearby } from "./utils/busNearbyLogic";
import logger from "./utils/logger";

// LRU cache for bus metadata (max 500 entries, 30 min TTL)
const busCache = new LRUCache<
  string,
  { busNumber: string; routeId: string | null }
>({
  max: 500,
  ttl: 1000 * 60 * 30,
});

// Rate limiter for socket events (10 updates per 5 seconds per socket)
const rateLimiter = new RateLimiterMemory({
  points: 10,
  duration: 5,
});

export const initializeSocket = (io: Server) => {
  // Socket.IO Connection Handling
  io.use(authenticateSocket); // Secure all connections

  io.on("connection", (socket) => {
    const authSocket = socket as AuthenticatedSocket;
    const user = authSocket.user;

    // Log connection
    if (user) {
      let idPrefix = "USR";
      switch (user.role) {
        case "student":
          idPrefix = "STU";
          break;
        case "driver":
          idPrefix = "DRI";
          break;
        case "teacher":
          idPrefix = "TEA";
          break;
        case "parent":
          idPrefix = "PAR";
          break;
        case "admin":
          idPrefix = "ADM";
          break;
        case "busCoordinator":
          idPrefix = "CRD";
          break;
      }
      logger.info(
        `${user.fullName} (${user.role}) connected - Socket ${socket.id}`
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

    socket.on("join_college", async (collegeId) => {
      socket.join(collegeId);
      logger.info(
        `[Socket] ${user?.fullName || "User"} joined room: ${collegeId}`
      );

      // IMMEDIATE LOCATION PUSH:
      // Fetch latest locations for buses in this college and send to the joining user
      try {
        const buses = await Bus.find({ collegeId, isActive: true });
        // FIX: Convert ObjectId to String because BusLocation stores busId as String
        const busIds = buses.map((b) => b._id.toString());

        if (busIds.length > 0) {
          const locations = await BusLocation.aggregate([
            { $match: { busId: { $in: busIds } } },
            { $sort: { timestamp: -1 } },
            {
              $group: {
                _id: "$busId",
                latestLocation: { $first: "$$ROOT" },
              },
            },
          ]);

          logger.info(
            `[Socket] Sending ${locations.length} cached locations to ${socket.id}`
          );

          locations.forEach((l) => {
            const locData = l.latestLocation;
            // Transform to match the structure expected by the client
            // Client expects: { busId, collegeId, location: { lat, lng }, speed, heading, timestamp }
            const payload = {
              busId: locData.busId,
              collegeId: collegeId, // ensuring collegeId is present
              location: {
                lat: locData.currentLocation?.lat,
                lng: locData.currentLocation?.lng,
              },
              currentLocation: {
                // Include this too for redundancy given the recent fix
                lat: locData.currentLocation?.lat,
                lng: locData.currentLocation?.lng,
              },
              speed: locData.speed,
              heading: locData.heading,
              timestamp: locData.timestamp,
            };
            socket.emit("location_updated", payload);
          });
        }
      } catch (err) {
        logger.error(`[Socket] Error fetching initial locations: ${err}`);
      }
    });

    socket.on("bus_list_updated", () => {
      if (user && user.collegeId) {
        logger.info(
          `[Socket] Received bus_list_updated from ${user.fullName}. Broadcasting to room ${user.collegeId}`
        );
        socket.to(user.collegeId.toString()).emit("bus_list_updated");
      } else {
        logger.info(
          `[Socket] bus_list_updated received but user or collegeId missing. User: ${user?.id}`
        );
      }
    });

    socket.on("update_location", async (data) => {
      // data: { busId, collegeId, location: { lat, lng }, speed, heading }
      const { collegeId } = data;
      // Broadcast to everyone in the same college room
      // Broadcast to everyone in the same college room
      socket.to(collegeId).emit("location_updated", data);

      // Persist location to DB to avoid 404s on REST API polling
      try {
        const newLocation = new BusLocation({
          busId: data.busId,
          currentLocation: { lat: data.location.lat, lng: data.location.lng },
          speed: data.speed,
          heading: data.heading,
        });
        // Save asynchronously without blocking the socket flow too much
        newLocation.save().catch((err) => {
          logger.error(`Error saving location to DB: ${err.message}`);
        });
      } catch (e) {
        logger.error(`Error saving location: ${e}`);
      }

      let busName = data.busId;
      let busDetails = busCache.get(data.busId);

      // Try to get friendly name
      if (busDetails) {
        busName = busDetails.busNumber;
      } else {
        // If cache miss, finding it might be slow for log, but we do it anyway for "busDetails" logic below
        // For now, we use ID until cache is populated
      }

      logger.info(
        `Bus ${busName} coordinate - ${data.location.lat.toFixed(
          5
        )}, ${data.location.lng.toFixed(5)}`
      );

      // Check for nearby stops and notify users
      try {
        // Apply rate limiting per socket ID
        await rateLimiter.consume(socket.id);

        if (busDetails) {
          if (busDetails.routeId) {
            checkAndNotifyBusNearby(
              data.busId,
              busDetails.busNumber,
              data.location.lat,
              data.location.lng,
              busDetails.routeId
            );
          }
        } else {
          // Correctly handle the promise and update cache
          const bus = await Bus.findById(data.busId);
          if (bus) {
            busDetails = {
              busNumber: bus.busNumber,
              routeId: bus.routeId ? bus.routeId.toString() : null,
            };
            busCache.set(data.busId, busDetails);

            // Should verify if we want to re-log with name now, but simplicity suggests keeping previous log

            if (busDetails.routeId) {
              checkAndNotifyBusNearby(
                data.busId,
                busDetails.busNumber,
                data.location.lat,
                data.location.lng,
                busDetails.routeId
              );
            }
          }
        }
      } catch (error) {
        if (error instanceof Error) {
          logger.error(`Error in update_location: ${error.message}`);
        } else {
          // This is likely a rate limit rejection
          logger.info(`Rate limit exceeded for socket ${socket.id}`);
        }
      }
    });

    socket.on("disconnect", () => {
      if (user) {
        logger.info(`${user.fullName || "User"} logout`);
      } else {
        logger.info(`User disconnected: ${socket.id}`);
      }

      if (user && user.role === "driver" && user.collegeId) {
        socket.to(user.collegeId).emit("driver_status_update", {
          driverId: user.id,
          status: "offline",
        });
        logger.info(`${user.fullName || "Driver"} is OFFLINE`);
      }
    });
  });
};
