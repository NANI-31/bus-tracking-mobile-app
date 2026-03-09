import { createClient } from "redis";
import logger from "@/utils/logger";

const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
const isTLS = redisUrl.startsWith("rediss://");

const clientOptions: any = {
  url: redisUrl,
  socket: {
    reconnectStrategy: (retries: number) => {
      const delay = Math.min(retries * 50, 2000);
      logger.info(
        `Redis Reconnecting... Attempt: ${retries}, Delay: ${delay}ms`,
      );
      return delay;
    },
    connectTimeout: 10000, // 10 seconds timeout
  },
};

if (isTLS) {
  clientOptions.socket = {
    ...clientOptions.socket,
    tls: true,
    rejectUnauthorized: true,
  };
}

const pubClient = createClient(clientOptions);
const subClient = pubClient.duplicate();

pubClient.on("connect", () => logger.info("Redis Pub Client: Connected"));
pubClient.on("ready", () => logger.info("Redis Pub Client: Ready"));
pubClient.on("end", () => logger.warn("Redis Pub Client: Connection Closed"));
pubClient.on("reconnecting", () =>
  logger.info("Redis Pub Client: Reconnecting"),
);
pubClient.on("error", (err: any) =>
  logger.error("Redis Pub Client Error", err),
);

subClient.on("connect", () => logger.info("Redis Sub Client: Connected"));
subClient.on("ready", () => logger.info("Redis Sub Client: Ready"));
subClient.on("end", () => logger.warn("Redis Sub Client: Connection Closed"));
subClient.on("reconnecting", () =>
  logger.info("Redis Sub Client: Reconnecting"),
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
