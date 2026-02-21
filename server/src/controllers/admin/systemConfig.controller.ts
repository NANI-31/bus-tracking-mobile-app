import { Request, Response } from "express";
import { IAuthRequest } from "@/types";
import SystemConfig from "@/models/SystemConfig.model";
import logger from "@/utils/logger";
import { AuditService } from "@/services/AuditService";

/**
 * Get all system configurations
 */
export const getSystemConfig = async (req: IAuthRequest, res: Response) => {
  logger.info("CONFIG: Entering getSystemConfig");
  try {
    const configs = await SystemConfig.find().sort({ category: 1, key: 1 });
    logger.info(`CONFIG: Found ${configs.length} configs`);
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
export const updateConfig = async (req: IAuthRequest, res: Response) => {
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

    // Audit Log
    await AuditService.log({
      req,
      action: "CONFIG_UPDATE",
      resource: "Config",
      resourceId: key,
      newState: { value },
    });

    res.json(config);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

