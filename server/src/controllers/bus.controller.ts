import { Request, Response } from "express";
import { Bus, BusLocation, IBus } from "../models/Bus";
import { getBusService } from "../services/busService";
import logger from "../utils/logger";
import { getCache, setCache, delCache, delCachePattern } from "../utils/cache";

const CACHE_TTL = 3600; // 1 hour

// Bus Operations
export const createBus = async (req: Request, res: Response) => {
  try {
    const newBus = new Bus(req.body);
    const savedBus = await newBus.save();

    // Invalidate caches
    await delCache("all_buses");
    await delCache(`buses:${savedBus.collegeId}`);

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
  logger.info("BUS: Entering getAllBuses");
  const cacheKey = "all_buses";

  try {
    // 1. Check cache
    const cachedBuses = await getCache<any[]>(cacheKey);
    if (cachedBuses) {
      logger.info("CACHE: Hit for all_buses");
      return res.status(200).json(cachedBuses);
    }

    // 2. Fetch from DB
    const buses = await Bus.find();
    logger.info(`BUS: Found ${buses.length} buses`);

    // 3. Set cache
    await setCache(cacheKey, buses, CACHE_TTL);

    res.status(200).json(buses);
  } catch (error) {
    logger.error(`BUS: Error in getAllBuses: ${(error as Error).message}`);
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Update bus - delegates business logic to BusService
 */
import { AuthenticatedRequest } from "../types/authenticatedRequest";

export const updateBus = async (req: Request, res: Response) => {
  try {
    const io = req.app.get("io");
    const busService = getBusService(io);

    const requestingUserName = (req as AuthenticatedRequest).user?.fullName;

    const updatedBus = await busService.updateBus(
      req.params.id,
      req.body,
      requestingUserName,
    );

    // Invalidate caches
    await delCache("all_buses");
    if (updatedBus) {
      await delCache(`buses:${updatedBus.collegeId}`);
    }

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

    // Invalidate caches
    await delCache("all_buses");
    await delCache(`buses:${bus.collegeId}`);

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
  const { collegeId } = req.params;
  logger.info(`BUS: Entering getCollegeBusLocations for college: ${collegeId}`);
  try {
    // 1. Get all active buses for this college
    const buses = await Bus.find({ collegeId, isActive: true });
    logger.info(
      `BUS: Found ${buses.length} active buses for college ${collegeId}`,
    );

    // 2. Get latest location for each bus using aggregation
    const busIds = buses.map((bus) => bus._id);
    const locations = await BusLocation.aggregate([
      { $match: { busId: { $in: busIds.map((id) => id.toString()) } } },
      { $sort: { timestamp: -1 } },
      {
        $group: {
          _id: "$busId",
          latestLocation: { $first: "$$ROOT" },
        },
      },
    ]);
    logger.info(`BUS: Aggregated ${locations.length} locations`);

    // 3. Map back to include busId consistently
    const validLocations = locations.map((l) => ({
      ...l.latestLocation,
      busId: l._id,
    }));

    res.status(200).json(validLocations);
  } catch (error) {
    logger.error(
      `BUS: Error in getCollegeBusLocations: ${(error as Error).message}`,
    );
    res.status(500).json({ message: (error as Error).message });
  }
};
