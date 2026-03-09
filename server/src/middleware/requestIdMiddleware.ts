import { Request, Response, NextFunction } from "express";
import { v4 as uuidv4 } from "uuid";

/**
 * Middleware to add a unique Request ID to each request and response.
 * This helps in tracing requests through logs and debugging.
 */
export const requestIdMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  // Use existing header or generate a new one
  const requestId = (req.headers["x-request-id"] as string) || uuidv4();

  // Attach to request object (for logging)
  (req as any).requestId = requestId;

  // Set response header
  res.setHeader("X-Request-Id", requestId);

  next();
};
