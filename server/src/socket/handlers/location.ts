import { Server, Socket } from "socket.io";
import { AuthenticatedSocket } from "@/utils/socketAuth";
import { Bus } from "@/models/Bus.model";
import { checkAndNotifyBusNearby } from "@/utils/busNearbyLogic";
import logger from "@/utils/logger";
import { busCache, rateLimiter } from "../config";
import { locationBuffer } from "../buffer";
import { ThrottledBroadcast } from "../types";

const throttledBroadcasts = new Map<string, ThrottledBroadcast>();
const THROTTLE_INTERVAL_MS = 3000;

export const registerLocationHandlers = (io: Server, socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;
  const user = authSocket.user;

  socket.on("update_location", async (data: any) => {
    if (!data || !data.busId || !data.collegeId || !data.location) {
      logger.warn(`[Socket] Invalid location data shape from ${socket.id}`);
      return;
    }

    if (
      typeof data.busId !== "string" ||
      typeof data.collegeId !== "string" ||
      typeof data.location.lat !== "number" ||
      typeof data.location.lng !== "number"
    ) {
      logger.warn(`[Socket] Invalid location data types from ${socket.id}`);
      return;
    }

    if (
      data.location.lat < -90 ||
      data.location.lat > 90 ||
      data.location.lng < -180 ||
      data.location.lng > 180 ||
      isNaN(data.location.lat) ||
      isNaN(data.location.lng)
    ) {
      logger.warn(
        `[Socket] Invalid coordinates from ${socket.id}: ${data.location.lat}, ${data.location.lng}`,
      );
      return;
    }

    if (!user || user.role !== "driver") {
      logger.warn(
        `[Socket] Non-driver ${user?.role || "unknown"} tried to update location: ${socket.id}`,
      );
      return;
    }

    const { collegeId, busId } = data;

    const lat = parseFloat(data.location.lat.toFixed(5));
    const lng = parseFloat(data.location.lng.toFixed(5));

    const now = Date.now();
    let throttleState = throttledBroadcasts.get(busId);
    if (!throttleState) {
      throttleState = { timeout: null, lastEmitTime: 0, latestData: null };
      throttledBroadcasts.set(busId, throttleState);
    }

    throttleState.latestData = {
      ...data,
      location: { lat, lng },
    };

    const executeEmit = () => {
      if (throttleState) {
        socket.to(collegeId).emit("location_updated", throttleState.latestData);
        throttleState.lastEmitTime = Date.now();
        if (throttleState.timeout) {
          clearTimeout(throttleState.timeout);
          throttleState.timeout = null;
        }
      }
    };

    const timeSinceLastEmit = now - throttleState.lastEmitTime;

    if (timeSinceLastEmit >= THROTTLE_INTERVAL_MS) {
      executeEmit();
    } else {
      if (throttleState.timeout) {
        clearTimeout(throttleState.timeout);
      }
      throttleState.timeout = setTimeout(
        executeEmit,
        THROTTLE_INTERVAL_MS - timeSinceLastEmit
      );
    }

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

    if (busDetails) {
      busName = busDetails.busNumber;
    }

    logger.info(
      `Bus ${busName} coordinate - ${data.location.lat.toFixed(
        5,
      )}, ${data.location.lng.toFixed(5)}`,
    );

    try {
      await rateLimiter.consume(socket.id);

      if (busDetails) {
        if (busDetails.routeId) {
          checkAndNotifyBusNearby(
            data.busId,
            busDetails.busNumber,
            data.location.lat,
            data.location.lng,
            busDetails.routeId,
          );
        }
      } else {
        const bus = await Bus.findById(data.busId);
        if (bus) {
          busDetails = {
            busNumber: bus.busNumber,
            routeId: bus.routeId ? bus.routeId.toString() : null,
          };
          busCache.set(data.busId, busDetails);

          if (busDetails.routeId) {
            checkAndNotifyBusNearby(
              data.busId,
              busDetails.busNumber,
              data.location.lat,
              data.location.lng,
              busDetails.routeId,
            );
          }
        }
      }
    } catch (error) {
      if (error instanceof Error) {
        logger.error(`Error in update_location: ${error.message}`);
      } else {
        logger.info(`Rate limit exceeded for socket ${socket.id}`);
      }
    }
  });
};
