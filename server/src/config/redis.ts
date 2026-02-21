import { createClient } from "redis";
import logger from "@/utils/logger";

const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";

const pubClient = createClient({ url: redisUrl });
const subClient = pubClient.duplicate();

pubClient.on("error", (err: any) =>
  logger.error("Redis Pub Client Error", err),
);
subClient.on("error", (err: any) =>
  logger.error("Redis Sub Client Error", err),
);

export const connectRedis = async () => {
  try {
    await pubClient.connect();
    await subClient.connect();
    logger.info("Connected to Redis for Socket.IO adapter");
  } catch (err) {
    logger.error("Failed to connect to Redis for Socket.IO adapter", err);
    // process.exit(1); // Optional: Exit if Redis is critical
  }
};

export { pubClient, subClient };
