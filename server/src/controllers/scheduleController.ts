import { Request, Response } from "express";
import Schedule from "../models/Schedule";

export const createSchedule = async (req: Request, res: Response) => {
  try {
    const newSchedule = new Schedule(req.body);
    const savedSchedule = await newSchedule.save();
    res.status(201).json(savedSchedule);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getSchedule = async (req: Request, res: Response) => {
  try {
    const schedule = await Schedule.findById(req.params.id);
    if (!schedule)
      return res.status(404).json({ message: "Schedule not found" });
    res.status(200).json(schedule);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getSchedulesByRoute = async (req: Request, res: Response) => {
  try {
    const schedules = await Schedule.find({ routeId: req.params.routeId });
    res.status(200).json(schedules);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getSchedulesByCollege = async (req: Request, res: Response) => {
  try {
    const schedules = await Schedule.find({ collegeId: req.params.collegeId });
    res.status(200).json(schedules);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
