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

// ── Server-side GPS outlier guard ─────────────────────────────────────────
// Tracks the last accepted coordinate per busId so we can reject GPS teleports
// before they are broadcast to any client. Keyed by busId (not socketId) so
// the guard persists across reconnects within the same server process.
const lastKnownPositions = new Map<
  string,
  { lat: number; lng: number }
>();

/**
 * Clear the cached last-known position for a bus when its driver disconnects
 * or ends a trip. This prevents the GPS outlier guard from rejecting the first
 * legitimate coordinate on the next trip (since the delta from a stale position
 * in a different city/area can easily exceed OUTLIER_THRESHOLD_M).
 */
export function clearLastKnownPosition(busId: string): void {
  if (lastKnownPositions.has(busId)) {
    lastKnownPositions.delete(busId);
    logger.info(`[Socket] Cleared stale GPS anchor for bus ${busId}`);
  }
}

const OUTLIER_THRESHOLD_M = 500;

/**
 * Haversine distance in metres between two lat/lng pairs.
 * Fast enough for a per-message hot path (no external dependencies).
 */
function haversineMeters(
  lat1: number, lng1: number,
  lat2: number, lng2: number,
): number {
  const R = 6_371_000; // Earth radius in metres
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}


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

    if (!user || (user.role !== "driver" && user.role !== "teacher")) {
      logger.warn(
        `[Socket] Non-driver/teacher ${user?.role || "unknown"} tried to update location: ${socket.id}`,
      );
      return;
    }

    const { collegeId, busId } = data;

    if (user.role === "teacher") {
      const bus = await Bus.findById(busId);
      if (!bus || bus.trackingTeacherId !== user.id) {
        logger.warn(
          `[Socket] Teacher ${user.id} tried to update location for bus ${busId} without authorization`,
        );
        return;
      }
    }

    const lat = parseFloat(data.location.lat.toFixed(5));
    const lng = parseFloat(data.location.lng.toFixed(5));

    // ── GPS outlier guard ────────────────────────────────────────────────────
    // Reject fixes that are implausibly far from the last accepted coordinate.
    // This prevents phantom GPS positions (provider hiccups, cold-start noise)
    // from being broadcast to students and coordinators.
    // Threshold: 500 m — buses at 80 km/h cover ~67 m/s; at a 3 s socket
    // interval that's ~200 m max legitimate movement. 500 m gives 2.5× margin.
    const prevPos = lastKnownPositions.get(busId);
    if (prevPos) {
      const jumpM = haversineMeters(prevPos.lat, prevPos.lng, lat, lng);
      if (jumpM > OUTLIER_THRESHOLD_M) {
        logger.warn(
          `[Socket] GPS outlier rejected for bus ${busId}: ` +
            `${jumpM.toFixed(0)} m jump from (${prevPos.lat},${prevPos.lng}) ` +
            `to (${lat},${lng}). Not broadcast.`,
        );
        return;
      }
    }
    // Accept this fix — slide the window forward.
    lastKnownPositions.set(busId, { lat, lng });

    const now = Date.now();
    let throttleState = throttledBroadcasts.get(busId);
    if (!throttleState) {
      throttleState = { timeout: null, lastEmitTime: 0, latestData: null };
      throttledBroadcasts.set(busId, throttleState);
    }

    throttleState.latestData = {
      ...data,
      location: { lat, lng },
      // Explicitly forward etaMinutes so the field is always present in the
      // broadcast payload. Without this, the key is missing entirely when the
      // driver app does not include it, breaking BusLocationModel.fromMap consumers.
      etaMinutes: typeof data.etaMinutes === 'number' ? data.etaMinutes : null,
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

  // ── Stop Arrival ─────────────────────────────────────────────────────────
  // The driver app emits 'stop_reached' when it detects the bus is within
  // 50 m of a route stop point. The server broadcasts it to the college room
  // so all students in that college receive it via their stopReachedStream.
  //
  // No DB write is performed — this is a transient real-time event.
  // The driver app deduplicates per session (Set<String> _arrivedStopIds)
  // so this fires at most once per stop per trip.
  socket.on("stop_reached", (data: any) => {
    if (!user || user.role !== "driver") {
      logger.warn(
        `[Socket] Non-driver tried to emit stop_reached: ${socket.id}`
      );
      return;
    }

    if (!data || !data.collegeId || !data.busId || !data.stopName) {
      logger.warn(
        `[Socket] Malformed stop_reached payload from ${socket.id}: ${JSON.stringify(data)}`
      );
      return;
    }

    logger.info(
      `[Socket] stop_reached: Bus ${data.busId} arrived at "${data.stopName}" ` +
        `(${data.distanceMeters ?? "?"}m). Broadcasting to college ${data.collegeId}`
    );

    // Broadcast to everyone in the college room (students, coordinators)
    socket.to(data.collegeId).emit("stop_reached", {
      busId: data.busId,
      collegeId: data.collegeId,
      stopId: data.stopId,
      stopName: data.stopName,
      distanceMeters: data.distanceMeters,
      timestamp: data.timestamp ?? new Date().toISOString(),
    });
  });
};
