import { Request, Response } from "express";
import { BusAssignmentLog } from "../models/BusAssignmentLog";

export const getAssignmentLogsByBus = async (req: Request, res: Response) => {
  try {
    const logs = await BusAssignmentLog.find({ busId: req.params.busId })
      .populate("driverId", "fullName email")
      .populate("routeId", "routeName")
      .sort({ assignedAt: -1 });
    res.status(200).json(logs);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getAssignmentLogsByDriver = async (
  req: Request,
  res: Response
) => {
  try {
    const logs = await BusAssignmentLog.find({ driverId: req.params.driverId })
      .populate("busId", "busNumber")
      .populate("routeId", "routeName")
      .sort({ assignedAt: -1 });
    res.status(200).json(logs);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
