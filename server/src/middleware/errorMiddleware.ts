import { Request, Response, NextFunction } from "express";
import logger from "@/utils/logger";

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  logger.error(err.stack || err.message);

  const statusCode = err.statusCode || 500;
  const isProduction = process.env.NODE_ENV === "production";

  res.status(statusCode).json({
    success: false,
    message:
      isProduction && statusCode === 500
        ? "Internal Server Error" // Never leak internal error details in production
        : err.message || "Internal Server Error",
    stack: isProduction ? undefined : err.stack,
  });
};
