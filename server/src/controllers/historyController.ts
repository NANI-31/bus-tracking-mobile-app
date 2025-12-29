import { Request, Response } from "express";
import { History } from "../models/History";

export const getHistory = async (req: Request, res: Response) => {
  try {
    const {
      busId,
      driverId,
      startDate,
      endDate,
      eventType,
      page = 1,
      limit = 20,
    } = req.query;

    const query: any = { collegeId: (req as any).user.collegeId };

    if (busId) query.busId = busId;
    if (driverId) query.driverId = driverId;
    if (eventType) query.eventType = eventType;

    // Date Range Filter
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate as string);
      if (endDate) query.timestamp.$lte = new Date(endDate as string);
    }

    const loadLimit = parseInt(limit as string);
    const skip = (parseInt(page as string) - 1) * loadLimit;

    // Execute Query
    const history = await History.find(query)
      .populate("busId", "busNumber") // Populate basic bus info
      .populate("driverId", "fullName email") // Populate basic driver info
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(loadLimit);

    const total = await History.countDocuments(query);

    res.status(200).json({
      data: history,
      pagination: {
        total,
        page: parseInt(page as string),
        pages: Math.ceil(total / loadLimit),
      },
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

// Helper for internal use (called by other controllers)
export const logHistoryHelper = async (
  collegeId: string,
  eventType: string,
  description: string,
  metadata: any = {},
  busId?: string,
  driverId?: string
) => {
  try {
    await History.create({
      collegeId,
      eventType,
      description,
      metadata,
      busId,
      driverId,
    });
  } catch (error) {
    console.error("Failed to log history:", error);
  }
};

/**
 * Get history for a specific driver
 * GET /api/users/:id/history
 */
export const getDriverHistory = async (req: Request, res: Response) => {
  try {
    const { id: driverId } = req.params;
    const { eventType, page = 1, limit = 50 } = req.query;

    const query: any = { driverId };
    if (eventType) query.eventType = eventType;

    const loadLimit = parseInt(limit as string);
    const skip = (parseInt(page as string) - 1) * loadLimit;

    const history = await History.find(query)
      .populate("busId", "busNumber routeId")
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(loadLimit);

    const total = await History.countDocuments(query);

    res.status(200).json({
      success: true,
      data: history,
      pagination: {
        total,
        page: parseInt(page as string),
        pages: Math.ceil(total / loadLimit),
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
  }
};
