import { LRUCache } from "lru-cache";
import { RateLimiterMemory } from "rate-limiter-flexible";

// LRU cache for bus metadata (max 500 entries, 30 min TTL)
export const busCache = new LRUCache<
  string,
  { busNumber: string; routeId: string | null }
>({
  max: 500,
  ttl: 1000 * 60 * 30,
});

// Rate limiter for socket events (10 updates per 5 seconds per socket)
export const rateLimiter = new RateLimiterMemory({
  points: 10,
  duration: 5,
  blockDuration: 60, // Block for 1 minute if exceeded
});
