import { Request, Response, NextFunction } from "express";
import { ZodSchema, ZodError } from "zod";
import logger from "@/utils/logger";

export const validate =
  (schema: ZodSchema) =>
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      return next();
    } catch (error) {
      if (error instanceof ZodError) {
        // Log validation errors only in non-production (avoid PII leakage)
        if (process.env.NODE_ENV !== "production") {
          logger.debug(`Validation error: ${JSON.stringify(error.issues)}`);
        }

        return res.status(400).json({
          message: "Validation failed",
          errors: error.issues.map((e) => ({
            field: e.path.join("."),
            message: e.message,
          })),
        });
      }
      logger.error(`Unexpected validation error: ${error}`);
      return res.status(400).json({ message: "Invalid request data" });
    }
  };
