import { Request, Response } from "express";
import { AuthRequest } from "../middleware/authMiddleware";
import SystemConfig from "../models/SystemConfig";
import AuditLog from "../models/AuditLog";

/**
 * Get all system configurations
 */
export const getSystemConfig = async (req: AuthRequest, res: Response) => {
  try {
    const configs = await SystemConfig.find().sort({ category: 1, key: 1 });
    res.json(configs);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Get public system configurations (visible to all users)
 */
export const getPublicConfig = async (req: Request, res: Response) => {
  try {
    const configs = await SystemConfig.find({ isPublic: true }).select(
      "key value description category",
    );
    res.json(configs);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Update system configuration
 */
export const updateConfig = async (req: AuthRequest, res: Response) => {
  try {
    const { key, value } = req.body;

    const config = await SystemConfig.findOneAndUpdate(
      { key },
      {
        value,
        updatedAt: new Date(),
        updatedBy: req.user?.id,
      },
      { new: true, upsert: true },
    );

    // Log the action
    await AuditLog.create({
      userId: req.user?.id,
      userEmail: req.user?.email,
      userName: req.user?.fullName || "Super Admin",
      action: "config.update",
      resource: "config",
      resourceId: key,
      newState: { value },
    });

    res.json(config);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
