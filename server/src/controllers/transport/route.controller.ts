import { Request, Response } from "express";
import Route from "../../models/Route.model";
import { getCache, setCache, delCache } from "../../utils/cache";
import { AuthRequest } from "../../middleware/authMiddleware";
import logger from "../../utils/logger";
import { AuditService } from "../../services/AuditService";

const CACHE_TTL = 3600; // 1 hour

export const createRoute = async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const { collegeId, id: userId } = authReq.user || {};

    if (!collegeId) {
      return res.status(401).json({ message: "College ID missing from token" });
    }

    const newRoute = new Route({
      ...req.body,
      collegeId,
      createdBy: userId,
    });
    const savedRoute = await newRoute.save();

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "ROUTE_CREATE",
      resource: "Route",
      resourceId: savedRoute._id.toString(),
      resourceName: savedRoute.routeName,
      newState: savedRoute.toObject(),
    });

    // Invalidate cache for this college
    await delCache(`routes:${collegeId}`);

    res.status(201).json(savedRoute);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getRoute = async (req: Request, res: Response) => {
  try {
    const route = await Route.findById(req.params.id);
    if (!route) return res.status(404).json({ message: "Route not found" });
    res.status(200).json(route);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getRoutesByCollege = async (req: Request, res: Response) => {
  const { collegeId } = req.params;
  const cacheKey = `routes:${collegeId}`;

  try {
    // 1. Check cache
    const cachedRoutes = await getCache<any[]>(cacheKey);
    if (cachedRoutes) {
      logger.info(`CACHE: Hit for ${cacheKey}`);
      return res.status(200).json(cachedRoutes);
    }

    // 2. Fetch from DB
    const routes = await Route.find({ collegeId });

    // 3. Set cache
    await setCache(cacheKey, routes, CACHE_TTL);
    logger.info(`CACHE: Miss for ${cacheKey}, set cache`);

    res.status(200).json(routes);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getAllRoutes = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    if (!user || (!user.collegeId && user.role !== "superAdmin")) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const filter =
      user.role === "superAdmin" ? {} : { collegeId: user.collegeId };
    const routes = await Route.find(filter);
    res.status(200).json(routes);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const updateRoute = async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const { role, collegeId } = authReq.user || {};

    const query: any = { _id: req.params.id };
    if (role === "collegeAdmin" && collegeId) {
      query.collegeId = collegeId;
    }

    const route = await Route.findOneAndUpdate(query, req.body, {
      new: true,
    });
    if (!route) return res.status(404).json({ message: "Route not found" });

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "ROUTE_UPDATE",
      resource: "Route",
      resourceId: route._id.toString(),
      resourceName: route.routeName,
      newState: route.toObject(),
    });

    // Invalidate cache
    await delCache(`routes:${route.collegeId}`);

    // Broadcast update to college room
    const io = req.app.get("io");
    io.to(route.collegeId.toString()).emit("route_list_updated");

    res.status(200).json(route);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const deleteRoute = async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const { role, collegeId } = authReq.user || {};

    const query: any = { _id: req.params.id };
    if (role === "collegeAdmin" && collegeId) {
      query.collegeId = collegeId;
    }

    const route = await Route.findOneAndDelete(query);
    if (!route) return res.status(404).json({ message: "Route not found" });

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "ROUTE_DELETE",
      resource: "Route",
      resourceId: route._id.toString(),
      resourceName: route.routeName,
      previousState: route.toObject(),
    });

    // Invalidate cache
    await delCache(`routes:${route.collegeId}`);

    // Broadcast update to college room
    const io = req.app.get("io");
    io.to(route.collegeId.toString()).emit("route_list_updated");

    res.status(200).json({ message: "Route deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
