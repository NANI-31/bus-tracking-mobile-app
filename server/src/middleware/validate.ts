import { Request, Response, NextFunction } from "express";
import { ZodSchema, ZodError } from "zod";

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
        // Log validation error for debugging
        console.error(
          "Validation error details:",
          JSON.stringify(error, null, 2),
        );

        const errors = (error as any).errors || [];
        return res.status(400).json({
          message: "Validation failed",
          errors: errors.map((e: any) => ({
            field: e.path.join("."),
            message: e.message,
          })),
        });
      }
      console.error("Unexpected validation error:", error);
      return res.status(400).json({ message: "Invalid request data" });
    }
  };
