import { Request, Response } from "express";
import { Incident } from "../models/Incident";
import { logHistoryHelper } from "./historyController";

export const createIncident = async (req: Request, res: Response) => {
  try {
    const newIncident = new Incident(req.body);
    const savedIncident = await newIncident.save();

    // History Log
    await logHistoryHelper(
      savedIncident.collegeId,
      "incident_report",
      `New incident reported: ${savedIncident.type} - ${savedIncident.description}`,
      { incidentId: savedIncident._id, severity: savedIncident.severity },
      savedIncident.busId,
      savedIncident.driverId
    );

    res.status(201).json(savedIncident);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getIncidentsByCollege = async (req: Request, res: Response) => {
  try {
    const { collegeId } = req.params;
    const incidents = await Incident.find({ collegeId })
      .populate("busId", "busNumber")
      .populate("driverId", "fullName")
      .populate("reporterId", "fullName email")
      .sort({ createdAt: -1 });
    res.status(200).json(incidents);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const updateIncidentStatus = async (req: Request, res: Response) => {
  try {
    const { status } = req.body;
    const incident = await Incident.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );
    if (!incident)
      return res.status(404).json({ message: "Incident not found" });
    res.status(200).json(incident);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
