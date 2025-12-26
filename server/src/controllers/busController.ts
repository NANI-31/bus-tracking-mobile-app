import { Request, Response } from "express";
import { Bus, BusLocation, IBus } from "../models/Bus";
import { BusAssignmentLog } from "../models/BusAssignmentLog";
import User from "../models/User";
import { sendTemplatedNotificationHelper } from "./notificationController";
import { NOTIFICATION_TYPES } from "../constants/notificationTypes";
import logger from "../utils/logger";

// Bus Operations
export const createBus = async (req: Request, res: Response) => {
  try {
    const newBus = new Bus(req.body);
    const savedBus = await newBus.save();
    res.status(201).json(savedBus);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getBus = async (req: Request, res: Response) => {
  try {
    const bus = await Bus.findById(req.params.id);
    if (!bus) return res.status(404).json({ message: "Bus not found" });
    res.status(200).json(bus);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getAllBuses = async (req: Request, res: Response) => {
  try {
    const buses = await Bus.find();
    res.status(200).json(buses);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const updateBus = async (req: Request, res: Response) => {
  try {
    const oldBus = await Bus.findById(req.params.id);
    if (!oldBus) return res.status(404).json({ message: "Bus not found" });

    const updatedBus: any = await Bus.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
      }
    );

    if (updatedBus) {
      const body = req.body as any;
      // Check if driver assignment changed to pending
      const isNewAssignment =
        body.assignmentStatus === "pending" &&
        (oldBus.assignmentStatus !== "pending" ||
          oldBus.driverId !== body.driverId);

      if (isNewAssignment && updatedBus.driverId) {
        // Send notification to the newly assigned driver
        logger.info(
          `[BusController] Driver assignment detected for bus ${updatedBus.busNumber} to driver ${updatedBus.driverId}`
        );
        await sendTemplatedNotificationHelper(
          updatedBus.driverId,
          NOTIFICATION_TYPES.DRIVER_ASSIGNED,
          { busNumber: updatedBus.busNumber }
        );

        // Create a new log entry
        const newLog = new BusAssignmentLog({
          busId: updatedBus._id,
          driverId: updatedBus.driverId,
          routeId: updatedBus.routeId,
          status: "pending",
        });
        await newLog.save();
      }

      // Check if assignment was accepted
      const isAccepted =
        body.assignmentStatus === "accepted" &&
        oldBus.assignmentStatus === "pending";

      if (isAccepted) {
        // Update the log entry
        await BusAssignmentLog.findOneAndUpdate(
          {
            busId: updatedBus._id,
            driverId: updatedBus.driverId,
            status: "pending",
          },
          { status: "accepted", acceptedAt: new Date() },
          { sort: { assignedAt: -1 } }
        );
      }

      // Check if assignment was rejected/removed
      const isRemoved =
        body.assignmentStatus === "unassigned" &&
        oldBus.assignmentStatus === "pending";

      if (isRemoved) {
        // Update the log entry or mark as rejected
        await BusAssignmentLog.findOneAndUpdate(
          { busId: oldBus._id, driverId: oldBus.driverId, status: "pending" },
          { status: "rejected", completedAt: new Date() },
          { sort: { assignedAt: -1 } }
        );
      }
    }

    res.status(200).json(updatedBus);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const deleteBus = async (req: Request, res: Response) => {
  try {
    const bus = await Bus.findByIdAndDelete(req.params.id);
    if (!bus) return res.status(404).json({ message: "Bus not found" });
    res.status(200).json({ message: "Bus deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

// Location Operations
export const updateBusLocation = async (req: Request, res: Response) => {
  try {
    const { busId, currentLocation, speed, heading } = req.body;
    const newLocation = new BusLocation({
      busId,
      currentLocation,
      speed,
      heading,
    });
    await newLocation.save();

    // Optionally update latest location cache or trigger socket event here

    res.status(201).json(newLocation);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getBusLocation = async (req: Request, res: Response) => {
  try {
    const location = await BusLocation.findOne({
      busId: req.params.busId,
    }).sort({ timestamp: -1 });
    if (!location)
      return res.status(404).json({ message: "Location not found" });
    res.status(200).json(location);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getCollegeBusLocations = async (req: Request, res: Response) => {
  try {
    const { collegeId } = req.params;
    // 1. Get all active buses for this college
    const buses = await Bus.find({ collegeId, isActive: true });

    // 2. Get latest location for each bus using aggregation
    const busIds = buses.map((bus) => bus._id);
    const locations = await BusLocation.aggregate([
      { $match: { busId: { $in: busIds } } },
      { $sort: { timestamp: -1 } },
      {
        $group: {
          _id: "$busId",
          latestLocation: { $first: "$$ROOT" },
        },
      },
    ]);

    // 3. Map back to include busId consistently
    const validLocations = locations.map((l) => ({
      ...l.latestLocation,
      busId: l._id,
    }));

    res.status(200).json(validLocations);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
