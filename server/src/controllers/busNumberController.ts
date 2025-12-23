import { Request, Response } from "express";
import BusNumber from "../models/BusNumber";

export const addBusNumber = async (req: Request, res: Response) => {
  try {
    const { collegeId, busNumber } = req.body;
    const newBusNumber = new BusNumber({ collegeId, busNumber });
    await newBusNumber.save();
    res.status(201).json(newBusNumber);
  } catch (error) {
    res.status(500).json({ message: "Error adding bus number", error });
  }
};

export const getBusNumbers = async (req: Request, res: Response) => {
  try {
    const busNumbers = await BusNumber.find({
      collegeId: req.params.collegeId,
    });
    res.json(busNumbers.map((b) => b.busNumber));
  } catch (error) {
    res.status(500).json({ message: "Error fetching bus numbers", error });
  }
};

export const removeBusNumber = async (req: Request, res: Response) => {
  try {
    const { collegeId, busNumber } = req.params;
    await BusNumber.findOneAndDelete({ collegeId, busNumber });
    res.json({ message: "Bus number removed" });
  } catch (error) {
    res.status(500).json({ message: "Error removing bus number", error });
  }
};
