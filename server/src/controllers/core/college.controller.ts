import { Request, Response } from "express";
import College from "@/models/College.model";
import { getCollegeService } from "@/services/collegeService";

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
    const io = req.app.get("io");
    const collegeService = getCollegeService(io);

    const busNumbers = await collegeService.addBusNumber(collegeId, busNumber);
    res.status(200).json(busNumbers);
  } catch (error) {
    const message = (error as Error).message;
    if (message === "College not found") {
      return res.status(404).json({ message });
    }
    res.status(500).json({ message });
  }
};

export const removeBusNumber = async (req: Request, res: Response) => {
  try {
    const { collegeId, busNumber } = req.params;
    const io = req.app.get("io");
    const collegeService = getCollegeService(io);

    const busNumbers = await collegeService.removeBusNumber(
      collegeId,
      busNumber,
    );
    res.status(200).json(busNumbers);
  } catch (error) {
    const message = (error as Error).message;
    if (message === "College not found") {
      return res.status(404).json({ message });
    }
    res.status(500).json({ message });
  }
};

export const renameBusNumber = async (req: Request, res: Response) => {
  try {
    const { collegeId, oldBusNumber, newBusNumber } = req.body;
    const io = req.app.get("io");
    const collegeService = getCollegeService(io);

    const busNumbers = await collegeService.renameBusNumber(
      collegeId,
      oldBusNumber,
      newBusNumber,
    );
    res.status(200).json(busNumbers);
  } catch (error) {
    const message = (error as Error).message;
    if (message === "College not found") {
      return res.status(404).json({ message });
    }
    res.status(500).json({ message });
  }
};
export const updateBusDetails = async (req: Request, res: Response) => {
  try {
    const { collegeId, oldBusNumber, newBusNumber, details } = req.body;
    const college = await College.findById(collegeId);
    if (!college) return res.status(404).json({ message: "College not found" });

    // 1. Update allowlist in College (Rename if needed)
    if (newBusNumber && newBusNumber !== oldBusNumber) {
      const index = college.busNumbers.indexOf(oldBusNumber);
      if (index !== -1) {
        college.busNumbers[index] = newBusNumber;
      } else if (!college.busNumbers.includes(newBusNumber)) {
        college.busNumbers.push(newBusNumber);
      }
      await college.save();
    }

    // 2. Update/Upsert actual Bus document(s)
    const { Bus } = require("../../models/Bus");
    const targetBusNumber = newBusNumber || oldBusNumber;

    // Find if a bus document already exists for the old number
    const existingBuses = await Bus.find({
      collegeId,
      busNumber: oldBusNumber,
    });

    if (existingBuses.length > 0) {
      // Update existing bus documents
      const updateObj: any = { ...details };
      if (newBusNumber) updateObj.busNumber = newBusNumber;

      await Bus.updateMany(
        { collegeId, busNumber: oldBusNumber },
        { $set: updateObj },
      );
    } else if (details && Object.keys(details).length > 0) {
      // If no bus doc exists but we have details (like defaultRouteId), create one
      const newBusObj = {
        collegeId,
        busNumber: targetBusNumber,
        ...details,
        isActive: false, // Default to inactive until assigned
        assignmentStatus: "unassigned",
      };
      await Bus.create(newBusObj);
    }

    // Broadcast update
    const io = req.app.get("io");
    io.to(collegeId.toString()).emit("bus_list_updated");

    res.status(200).json(college.busNumbers);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const toggleManualPremium = async (req: Request, res: Response) => {
  try {
    const { collegeId } = req.params;
    const { allowManualPremium } = req.body;

    const college = await College.findByIdAndUpdate(
      collegeId,
      { allowManualPremium },
      { new: true },
    );

    if (!college) return res.status(404).json({ message: "College not found" });

    res.status(200).json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
