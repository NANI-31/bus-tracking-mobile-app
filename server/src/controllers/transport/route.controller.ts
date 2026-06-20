import { Request, Response } from "express";
import zlib from "zlib";
import Route from "@/models/Route.model";
import { getCache, setCache, delCache } from "@/utils/cache";
import { IAuthRequest } from "@/types";
import logger from "@/utils/logger";
import { AuditService } from "@/services/AuditService";
import { DirectionsService } from "@/services/DirectionsService";

const CACHE_TTL = 3600; // 1 hour

export const createRoute = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;
    const { collegeId, id: userId } = authReq.user || {};

    if (!collegeId) {
      return res.status(401).json({ message: "College ID missing from token" });
    }

    const newRoute = new Route({
      ...req.body,
      collegeId,
      createdBy: userId,
    });

    // Pre-calculate directions on route creation
    try {
      const directions = await DirectionsService.getDirectionsForRoute(newRoute);
      if (directions) {
        newRoute.directions = directions;
      }
    } catch (dirErr) {
      logger.error("[RouteController] Failed to pre-calculate directions on route creation:", dirErr);
    }

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
    const authReq = req as IAuthRequest;
    const { role, collegeId } = authReq.user || {};

    const query: any = { _id: req.params.id };
    if (role !== "superAdmin" && collegeId) {
      query.collegeId = collegeId;
    }

    const route = await Route.findOne(query);
    if (!route) return res.status(404).json({ message: "Route not found" });

    // Enforce name and properties updates
    if (req.body.routeName) route.routeName = req.body.routeName;
    if (req.body.routeType) route.routeType = req.body.routeType;
    if (req.body.isActive !== undefined) route.isActive = req.body.isActive;
    if (req.body.startPoint) route.startPoint = req.body.startPoint;
    if (req.body.endPoint) route.endPoint = req.body.endPoint;

    // Apply stops updates and automatically ensure start/end points match if not explicitly provided
    if (req.body.stopPoints) {
      route.stopPoints = req.body.stopPoints;
      if (!req.body.startPoint && !req.body.endPoint && req.body.stopPoints.length >= 2) {
        route.startPoint = {
          name: req.body.stopPoints[0].name,
          location: req.body.stopPoints[0].location,
        };
        route.endPoint = {
          name: route.stopPoints[route.stopPoints.length - 1].name,
          location: route.stopPoints[route.stopPoints.length - 1].location,
        };
      }
    }


    // Update directions caching on route update
    try {
      const directions = await DirectionsService.getDirectionsForRoute(route);
      if (directions) {
        route.directions = directions;
        await setCache(`directions:route:${route._id}`, directions, 30 * 24 * 3600); // 30 days
      } else {
        route.directions = undefined;
        await delCache(`directions:route:${route._id}`);
      }
    } catch (dirErr) {
      logger.error("[RouteController] Failed to update directions on route update:", dirErr);
    }

    const savedRoute = await route.save();

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "ROUTE_UPDATE",
      resource: "Route",
      resourceId: savedRoute._id.toString(),
      resourceName: savedRoute.routeName,
      newState: savedRoute.toObject(),
    });

    // Invalidate cache
    await delCache(`routes:${savedRoute.collegeId}`);

    // Broadcast update to college room
    const io = req.app.get("io");
    io.to(savedRoute.collegeId.toString()).emit("route_list_updated");

    res.status(200).json(savedRoute);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const deleteRoute = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;
    const { role, collegeId } = authReq.user || {};

    const query: any = { _id: req.params.id };
    if (role !== "superAdmin" && collegeId) {
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

/**
 * Utility to compress JSON response if supported by the client (Brotli or Gzip).
 */
const sendCompressedJson = (req: Request, res: Response, data: any) => {
  const jsonString = JSON.stringify(data);
  const acceptEncoding = req.headers["accept-encoding"] as string || "";

  if (acceptEncoding.includes("br")) {
    zlib.brotliCompress(jsonString, (err, buffer) => {
      if (err) {
        logger.error("[RouteController] Brotli compression failed:", err);
        return res.status(200).json(data);
      }
      res.writeHead(200, {
        "Content-Encoding": "br",
        "Content-Type": "application/json",
        "Content-Length": buffer.length,
      });
      res.end(buffer);
    });
  } else if (acceptEncoding.includes("gzip")) {
    zlib.gzip(jsonString, (err, buffer) => {
      if (err) {
        logger.error("[RouteController] Gzip compression failed:", err);
        return res.status(200).json(data);
      }
      res.writeHead(200, {
        "Content-Encoding": "gzip",
        "Content-Type": "application/json",
        "Content-Length": buffer.length,
      });
      res.end(buffer);
    });
  } else {
    res.status(200).json(data);
  }
};

/**
 * DELETE /:id/directions
 * Clears the stored polyline/directions data from MongoDB and Redis for a route.
 * Use this during testing to force a re-fetch from Google Directions API on the next tracking call.
 */
export const clearRouteDirections = async (req: Request, res: Response) => {
  const { id } = req.params;
  const authReq = req as IAuthRequest;
  const { role, collegeId } = authReq.user || {};

  try {
    const query: any = { _id: id };
    if (role !== "superAdmin" && collegeId) {
      query.collegeId = collegeId;
    }

    const route = await Route.findOne(query);
    if (!route) {
      return res.status(404).json({ message: "Route not found" });
    }

    // Clear directions field in MongoDB
    route.directions = undefined;
    await route.save();

    // Invalidate both the per-route directions cache and the college routes list cache
    await delCache(`directions:route:${id}`);
    await delCache(`routes:${route.collegeId}`);

    logger.info(`[RouteController] Cleared directions for route ${id} (${route.routeName})`);

    res.status(200).json({
      message: `Directions cleared for route "${route.routeName}". Will be re-fetched from Google on the next tracking session.`,
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getRouteDirections = async (req: Request, res: Response) => {
  const { id } = req.params;
  const cacheKey = `directions:route:${id}`;

  try {
    // 1. Check Redis cache first
    const cachedDirections = await getCache<any>(cacheKey);
    if (cachedDirections) {
      return sendCompressedJson(req, res, cachedDirections);
    }

    // 2. Fetch Route from MongoDB
    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({ message: "Route not found" });
    }

    // 3. If directions exist in MongoDB, cache in Redis and return
    if (route.directions && route.directions.polylinePoints && route.directions.polylinePoints.length > 0) {
      await setCache(cacheKey, route.directions, 30 * 24 * 3600); // 30 days
      return sendCompressedJson(req, res, route.directions);
    }

    // 4. Otherwise calculate directions via Google API
    const directions = await DirectionsService.getDirectionsForRoute(route);
    if (!directions) {
      return res.status(400).json({ message: "Failed to generate directions for this route" });
    }

    // 5. Save to MongoDB & Redis
    route.directions = directions;
    await route.save();
    await setCache(cacheKey, directions, 30 * 24 * 3600); // 30 days

    logger.info(`[RouteController] Generated & cached directions for route ${id}`);
    sendCompressedJson(req, res, directions);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

