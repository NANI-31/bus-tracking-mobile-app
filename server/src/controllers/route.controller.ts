import { Request, Response } from "express";
import Route from "../models/Route";

export const createRoute = async (req: Request, res: Response) => {
  try {
    const newRoute = new Route(req.body);
    const savedRoute = await newRoute.save();
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
  try {
    const routes = await Route.find({ collegeId: req.params.collegeId });
    res.status(200).json(routes);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const updateRoute = async (req: Request, res: Response) => {
  try {
    const route = await Route.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    if (!route) return res.status(404).json({ message: "Route not found" });

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
    const route = await Route.findByIdAndDelete(req.params.id);
    if (!route) return res.status(404).json({ message: "Route not found" });

    // Broadcast update to college room
    const io = req.app.get("io");
    io.to(route.collegeId.toString()).emit("route_list_updated");

    res.status(200).json({ message: "Route deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
