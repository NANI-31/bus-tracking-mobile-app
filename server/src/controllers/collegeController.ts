import { Request, Response } from "express";
import College from "../models/College";

export const createCollege = async (req: Request, res: Response) => {
  try {
    const newCollege = new College(req.body);
    const savedCollege = await newCollege.save();
    res.status(201).json(savedCollege);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getCollege = async (req: Request, res: Response) => {
  try {
    const college = await College.findById(req.params.id);
    if (!college) return res.status(404).json({ message: "College not found" });
    res.status(200).json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getAllColleges = async (req: Request, res: Response) => {
  try {
    const colleges = await College.find();
    res.status(200).json(colleges);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
