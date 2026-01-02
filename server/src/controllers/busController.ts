import { Request, Response } from "express";
import { Bus, BusLocation, IBus } from "../models/Bus";
import { getBusService } from "../services/busService";
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

/**
 * Update bus - delegates business logic to BusService
 */
export const updateBus = async (req: Request, res: Response) => {
  try {
    const io = req.app.get("io");
    const busService = getBusService(io);

    const requestingUserName = (req as any).user?.fullName;

    const updatedBus = await busService.updateBus(
      req.params.id,
      req.body,
      requestingUserName
    );

    res.status(200).json(updatedBus);
  } catch (error) {
    const message = (error as Error).message;
    if (message === "Bus not found") {
      return res.status(404).json({ message });
    }
    res.status(500).json({ message });
  }
};

export const deleteBus = async (req: Request, res: Response) => {
  try {
    const bus = await Bus.findByIdAndDelete(req.params.id);
    if (!bus) return res.status(404).json({ message: "Bus not found" });

    // Broadcast update to college room
    const io = req.app.get("io");
    io.to(bus.collegeId.toString()).emit("bus_list_updated");

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
    // if (!location)
    // return res.status(404).json({ message: "Location not found" });
    if (!location) return res.status(200).json(null);
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
