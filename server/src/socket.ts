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

// ============================================================
// WRITE-BEHIND BUFFER: Accumulate location updates in memory
// and flush to database periodically to reduce DB write load.
// ============================================================
interface BufferedLocation {
  busId: string;
  lat: number;
  lng: number;
  speed: number;
  heading: number;
  timestamp: Date;
}
const locationBuffer = new Map<string, BufferedLocation>();
const DB_FLUSH_INTERVAL_MS = 10000; // Flush every 10 seconds

// Flush buffer to database
async function flushLocationBuffer() {
  if (locationBuffer.size === 0) return;

  const entries = Array.from(locationBuffer.values());
  locationBuffer.clear();

  logger.info(`[Socket] Flushing ${entries.length} buffered locations to DB`);

  // Use bulkWrite for efficiency
  const ops = entries.map((loc) => ({
    insertOne: {
      document: {
        busId: loc.busId,
        currentLocation: { lat: loc.lat, lng: loc.lng },
        speed: loc.speed,
        heading: loc.heading,
        timestamp: loc.timestamp,
      },
    },
  }));

  try {
    await BusLocation.bulkWrite(ops, { ordered: false });
  } catch (err) {
    logger.error(`[Socket] Error flushing location buffer: ${err}`);
  }
}

// Start the flush interval
setInterval(flushLocationBuffer, DB_FLUSH_INTERVAL_MS);

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
        const busIdSet = new Set(busIds);

        if (busIds.length > 0) {
          // 1. Get Buffered Locations (RAM) - These are the most "live"
          const liveLocations: any[] = [];
          const processedBusIds = new Set<string>();

          locationBuffer.forEach((loc, bid) => {
            if (busIdSet.has(bid)) {
              liveLocations.push({
                busId: bid,
                collegeId: collegeId,
                location: { lat: loc.lat, lng: loc.lng },
                // Double check these fields match client expectation
                currentLocation: { lat: loc.lat, lng: loc.lng },
                speed: loc.speed,
                heading: loc.heading,
                timestamp: loc.timestamp,
              });
              processedBusIds.add(bid);
            }
          });
          logger.info(
            `[Socket] Found ${liveLocations.length} buffered locations.`
          );

          // 2. Get DB Locations (Disk) - Only recent ones to ensure "live" feel
          // Filter for only locations in the last 15 minutes
          const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);

          const dbLocations = await BusLocation.aggregate([
            {
              $match: {
                busId: { $in: busIds },
                timestamp: { $gte: fifteenMinutesAgo }, // Strictly "live"
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
          logger.info(
            `[Socket] Found ${dbLocations.length} recent DB locations.`
          );

          // 3. Merge: Add DB location only if we don't have a buffered one (or DB is somehow newer)
          dbLocations.forEach((l) => {
            const locData = l.latestLocation;
            if (!processedBusIds.has(locData.busId)) {
              const payload = {
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
              };
              liveLocations.push(payload);
            }
          });

          if (liveLocations.length > 0) {
            logger.info(
              `[Socket] Sending ${liveLocations.length} live locations to ${socket.id}`
            );
            liveLocations.forEach((payload) => {
              socket.emit("location_updated", payload);
            });
          }
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

    socket.on("user_list_updated", () => {
      if (user && user.collegeId) {
        logger.info(
          `[Socket] Received user_list_updated from ${user.fullName}. Broadcasting to room ${user.collegeId}`
        );
        socket.to(user.collegeId.toString()).emit("user_list_updated");
      } else {
        logger.info(
          `[Socket] user_list_updated received but user or collegeId missing. User: ${user?.id}`
        );
      }
    });

    socket.on("update_location", async (data) => {
      // data: { busId, collegeId, location: { lat, lng }, speed, heading }
      const { collegeId, busId } = data;

      // Round coordinates to 5 decimal places (~1m precision) for efficiency
      const lat = parseFloat(data.location.lat.toFixed(5));
      const lng = parseFloat(data.location.lng.toFixed(5));

      // Broadcast to everyone in the same college room (instant)
      socket.to(collegeId).emit("location_updated", {
        ...data,
        location: { lat, lng },
      });

      // Add to write-behind buffer instead of direct DB write
      locationBuffer.set(busId, {
        busId,
        lat,
        lng,
        speed: data.speed ?? 0,
        heading: data.heading ?? 0,
        timestamp: new Date(),
      });

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
