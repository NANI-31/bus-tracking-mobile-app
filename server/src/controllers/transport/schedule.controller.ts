import { Request, Response } from "express";
import Schedule from "@/models/Schedule.model";

export const createSchedule = async (req: Request, res: Response) => {
  try {
    const authReq = req as any; // Cast to access user
    const { collegeId: userCollegeId } = authReq.user || {};

    const { busId, shift, collegeId: bodyCollegeId, tripType } = req.body;
    const collegeId = userCollegeId || bodyCollegeId;

    if (!collegeId) {
      return res.status(401).json({ message: "College ID missing" });
    }

    const existingSchedule = await Schedule.findOne({
      busId,
      shift,
      collegeId,
      tripType,
    });

    if (existingSchedule) {
      return res.status(409).json({
        message: `Bus is already assigned to a route in ${shift} shift.`,
      });
    }

    const newSchedule = new Schedule({
      ...req.body,
      collegeId,
      createdBy: authReq.user?.id,
    });
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

export const updateSchedule = async (req: Request, res: Response) => {
  try {
    const schedule = await Schedule.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true, runValidators: true },
    );
    if (!schedule)
      return res.status(404).json({ message: "Schedule not found" });
    res.status(200).json(schedule);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const deleteSchedule = async (req: Request, res: Response) => {
  try {
    const schedule = await Schedule.findByIdAndDelete(req.params.id);
    if (!schedule)
      return res.status(404).json({ message: "Schedule not found" });
    res.status(200).json({ message: "Schedule deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
