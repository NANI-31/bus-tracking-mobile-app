import { BusLocation } from "@/models/Bus.model";
import logger from "@/utils/logger";
import { BufferedLocation } from "./types";

export const locationBuffer = new Map<string, BufferedLocation>();
const DB_FLUSH_INTERVAL_MS = 10000; // Flush every 10 seconds

// Flush buffer to database
export async function flushLocationBuffer() {
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
const flushInterval = setInterval(flushLocationBuffer, DB_FLUSH_INTERVAL_MS);

/**
 * Stops the location buffer flush interval.
 * Used primarily for testing to prevent open handles.
 */
export const stopSocketInterval = () => {
  clearInterval(flushInterval);
};
