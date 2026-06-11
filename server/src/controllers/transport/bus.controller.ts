import { Request, Response } from "express";
import { Bus, BusLocation, IBus } from "@/models/Bus.model";
import { IAuthRequest } from "@/types";
import { getBusService } from "@/services/busService";
import logger from "@/utils/logger";
import { AuditService } from "@/services/AuditService";
import {
  getCache,
  setCache,
  delCache,
  delCachePattern,
} from "../../utils/cache";

const CACHE_TTL = 3600; // 1 hour

// Bus Operations
export const createBus = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;
    const { collegeId } = authReq.user || {};

    if (!collegeId) {
      return res.status(401).json({ message: "College ID missing from token" });
    }

    const newBus = new Bus({
      ...req.body,
      collegeId,
    });
    const savedBus = await newBus.save();

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "BUS_CREATE",
      resource: "Bus",
      resourceId: savedBus._id.toString(),
      resourceName: savedBus.busNumber,
      newState: savedBus.toObject(),
    });

    // Invalidate caches
    await delCache("buses:all");
    await delCache(`buses:${collegeId}`);

    res.status(201).json(savedBus);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getBusByDriver = async (req: Request, res: Response) => {
  try {
    const { driverId } = req.params;
    const bus = await Bus.findOne({ driverId });
    // Return 200 with null if no bus found to match Flutter's expected behavior
    res.status(200).json(bus);
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
    const authReq = req as IAuthRequest;
    const { role, collegeId: userCollegeId } = authReq.user || {};
    const { collegeId: queryCollegeId } = req.query;

    let query: any = {};

    // Multi-tenancy: College admins only see their own college's buses
    if (role === "collegeAdmin") {
      query.collegeId = userCollegeId;
    } else if (role === "superAdmin" || role === "admin") {
      if (queryCollegeId) {
        query.collegeId = queryCollegeId;
      }
    } else if (role) {
      // Regular users/others shouldn't ideally use this, but if they do, restrict them
      // In many cases, students might need to see buses for their college.
      // For now, let's keep it consistent with the admin requirements.
      if (userCollegeId) {
        query.collegeId = userCollegeId;
      } else {
        return res.status(403).json({ message: "Not authorized" });
      }
    } else {
      return res.status(401).json({ message: "Not authenticated" });
    }

    const cacheKey = query.collegeId ? `buses:${query.collegeId}` : "buses:all";

    // 1. Check cache
    const cachedBuses = await getCache<any[]>(cacheKey);
    if (cachedBuses) {
      logger.info(`CACHE: Hit for ${cacheKey}`);
      return res.status(200).json(cachedBuses);
    }

    // 2. Fetch from DB
    const buses = await Bus.find(query);
    logger.info(
      `BUS: Found ${buses.length} buses for query: ${JSON.stringify(query)}`,
    );

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
import { AuthenticatedRequest } from "@/types/authenticatedRequest";

export const updateBus = async (req: Request, res: Response) => {
  try {
    const io = req.app.get("io");
    const busService = getBusService(io);

    const requestingUserName = (req as AuthenticatedRequest).user?.fullName;

    const updatedBus = await busService.updateBus(
      req.params.id as string,
      req.body,
      requestingUserName,
    );

    // Audit Log
    await AuditService.log({
      req: req as IAuthRequest,
      action: "BUS_UPDATE",
      resource: "Bus",
      resourceId: updatedBus._id.toString(),
      resourceName: updatedBus.busNumber,
      newState: updatedBus.toObject(),
    });

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
    const authReq = req as IAuthRequest;
    const { role, collegeId } = authReq.user || {};

    const query: any = { _id: req.params.id };

    // Enforce multi-tenancy: College admins can only delete their own buses
    if (role === "collegeAdmin" && collegeId) {
      query.collegeId = collegeId;
    } else if (role !== "superAdmin" && role !== "admin") {
      // If not superAdmin or collegeAdmin, maybe coordinator but let's stick to these for now
      // Or if coordinator, they should also have a collegeId
      if (collegeId) {
        query.collegeId = collegeId;
      }
    }

    const bus = await Bus.findOneAndDelete(query);
    if (!bus) {
      return res.status(404).json({
        message: "Bus not found or you don't have permission to delete it",
      });
    }

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "BUS_DELETE",
      resource: "Bus",
      resourceId: bus._id.toString(),
      resourceName: bus.busNumber,
      previousState: bus.toObject(),
    });

    // Invalidate caches
    await delCache("buses:all");
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

    const io = req.app.get("io");
    const busService = getBusService(io);

    await busService.updateBusLocation({
      busId,
      location: currentLocation,
      speed,
      heading,
    });

    res.status(200).json({ message: "Location updated successfully" });
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

