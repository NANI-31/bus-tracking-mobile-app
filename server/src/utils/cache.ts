import { pubClient } from "../config/redis";
import logger from "./logger";

const DEFAULT_TTL = 3600; // 1 hour

export const getCache = async <T>(key: string): Promise<T | null> => {
  try {
    const data = await pubClient.get(key);
    if (!data) return null;
    return JSON.parse(data) as T;
  } catch (error) {
    logger.error(`CACHE: Error getting key ${key}:`, error);
    return null;
  }
};

export const setCache = async (
  key: string,
  data: any,
  ttl: number = DEFAULT_TTL,
): Promise<void> => {
  try {
    await pubClient.setEx(key, ttl, JSON.stringify(data));
  } catch (error) {
    logger.error(`CACHE: Error setting key ${key}:`, error);
  }
};

export const delCache = async (key: string): Promise<void> => {
  try {
    await pubClient.del(key);
  } catch (error) {
    logger.error(`CACHE: Error deleting key ${key}:`, error);
  }
};

export const delCachePattern = async (pattern: string): Promise<void> => {
  try {
    const keys = await pubClient.keys(pattern);
    if (keys.length > 0) {
      await pubClient.del(keys);
    }
  } catch (error) {
    logger.error(`CACHE: Error deleting pattern ${pattern}:`, error);
  }
};
