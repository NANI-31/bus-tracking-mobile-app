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

export const getBusNumbers = async (req: Request, res: Response) => {
  try {
    const college = await College.findById(req.params.collegeId);
    if (!college) return res.status(404).json({ message: "College not found" });
    res.status(200).json(college.busNumbers || []);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const addBusNumber = async (req: Request, res: Response) => {
  try {
    const { collegeId, busNumber } = req.body;
    const college = await College.findById(collegeId);
    if (!college) return res.status(404).json({ message: "College not found" });

    if (!college.busNumbers.includes(busNumber)) {
      college.busNumbers.push(busNumber);
      await college.save();
    }
    res.status(200).json(college.busNumbers);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const removeBusNumber = async (req: Request, res: Response) => {
  try {
    const { collegeId, busNumber } = req.params;
    const college = await College.findById(collegeId);
    if (!college) return res.status(404).json({ message: "College not found" });

    college.busNumbers = college.busNumbers.filter((n) => n !== busNumber);
    await college.save();
    res.status(200).json(college.busNumbers);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
