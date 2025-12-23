import { Request, Response } from "express";
import { Bus, BusLocation } from "../models/Bus";

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

    // 2. Get latest location for each bus
    // This can be optimized with aggregation but simple Promise.all is fine for N < 100
    const locations = await Promise.all(
      buses.map(async (bus) => {
        const location = await BusLocation.findOne({ busId: bus._id })
          .sort({ timestamp: -1 })
          .lean();
        return location ? { ...location, busId: bus._id } : null;
      })
    );

    // Filter out nulls
    const validLocations = locations.filter((l) => l !== null);

    res.status(200).json(validLocations);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
