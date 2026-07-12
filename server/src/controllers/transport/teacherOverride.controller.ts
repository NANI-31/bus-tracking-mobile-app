import { Request, Response } from "express";
import { Bus } from "@/models/Bus.model";
import { TeacherOverrideRequest } from "@/models/TeacherOverrideRequest.model";
import { IAuthRequest } from "@/types";
import logger from "@/utils/logger";
import { AuditService } from "@/services/AuditService";
import { delCache } from "@/utils/cache";

export const requestOverride = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;
    const { id: teacherId, collegeId, role } = authReq.user || {};
    const { busId } = req.body;

    if (role !== "teacher") {
      return res.status(403).json({ message: "Only teachers can request location override." });
    }

    if (!busId) {
      return res.status(400).json({ message: "Bus ID is required." });
    }

    const bus = await Bus.findById(busId);
    if (!bus) {
      return res.status(404).json({ message: "Bus not found." });
    }

    // Check for existing pending or approved requests for this bus
    const existingRequest = await TeacherOverrideRequest.findOne({
      busId,
      status: { $in: ["pending", "approved"] },
    });

    if (existingRequest) {
      return res.status(400).json({
        message: "An active or pending override request already exists for this bus.",
      });
    }

    const newRequest = new TeacherOverrideRequest({
      teacherId,
      busId,
      collegeId,
      status: "pending",
    });

    await newRequest.save();

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "TEACHER_OVERRIDE_REQUEST",
      resource: "TeacherOverrideRequest",
      resourceId: newRequest._id.toString(),
      resourceName: `Bus ${bus.busNumber}`,
      newState: newRequest.toObject(),
    });

    // Notify coordinator via socket
    const io = req.app.get("io");
    if (io && collegeId) {
      io.to(collegeId.toString()).emit("bus_list_updated");
    }

    res.status(201).json(newRequest);
  } catch (error) {
    logger.error(`Error requesting override: ${(error as Error).message}`);
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getOverrideRequests = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;
    const { collegeId, role, id: userId } = authReq.user || {};

    if (!collegeId) {
      return res.status(401).json({ message: "College ID is required." });
    }

    const query: any = { collegeId, status: "pending" };
    if (role === "teacher") {
      query.teacherId = userId;
    }

    const requests = await TeacherOverrideRequest.find(query)
      .populate("teacherId", "fullName email phoneNumber")
      .populate("busId", "busNumber");

    res.status(200).json(requests);
  } catch (error) {
    logger.error(`Error fetching override requests: ${(error as Error).message}`);
    res.status(500).json({ message: (error as Error).message });
  }
};

export const handleOverrideRequest = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;
    const { requestId } = req.params;
    const { status } = req.body; // 'approved' | 'rejected'

    if (!["approved", "rejected"].includes(status)) {
      return res.status(400).json({ message: "Invalid status update." });
    }

    const request = await TeacherOverrideRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({ message: "Request not found." });
    }

    request.status = status;
    request.updatedAt = new Date();
    await request.save();

    if (status === "approved") {
      const bus = await Bus.findById(request.busId);
      if (bus) {
        bus.trackingTeacherId = request.teacherId;
        bus.assignmentStatus = "accepted"; // Active accepted tracking state
        await bus.save();

        // Invalidate cache
        await delCache("buses:all");
        await delCache(`buses:${bus.collegeId}`);
      }
    }

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: status === "approved" ? "TEACHER_OVERRIDE_APPROVE" : "TEACHER_OVERRIDE_REJECT",
      resource: "TeacherOverrideRequest",
      resourceId: request._id.toString(),
      resourceName: `Request ${requestId}`,
      newState: request.toObject(),
    });

    // Notify all via socket
    const io = req.app.get("io");
    if (io && request.collegeId) {
      io.to(request.collegeId.toString()).emit("bus_list_updated");
      io.to(request.collegeId.toString()).emit("bus_updated", {
        busId: request.busId.toString(),
      });
    }

    res.status(200).json(request);
  } catch (error) {
    logger.error(`Error handling override request: ${(error as Error).message}`);
    res.status(500).json({ message: (error as Error).message });
  }
};

export const cancelOverride = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;
    const { busId } = req.body;

    if (!busId) {
      return res.status(400).json({ message: "Bus ID is required." });
    }

    const bus = await Bus.findById(busId);
    if (!bus) {
      return res.status(404).json({ message: "Bus not found." });
    }

    bus.trackingTeacherId = undefined;
    bus.driverId = "";
    bus.assignmentStatus = "unassigned";
    bus.status = "not-running";
    await bus.save();

    // Invalidate cache
    await delCache("buses:all");
    await delCache(`buses:${bus.collegeId}`);

    // End any active override requests
    await TeacherOverrideRequest.updateMany(
      { busId, status: "approved" },
      { status: "ended", updatedAt: new Date() }
    );

    // Audit Log
    await AuditService.log({
      req: authReq,
      action: "TEACHER_OVERRIDE_CANCEL",
      resource: "Bus",
      resourceId: bus._id.toString(),
      resourceName: bus.busNumber,
    });

    // Notify all via socket
    const io = req.app.get("io");
    if (io && bus.collegeId) {
      io.to(bus.collegeId.toString()).emit("bus_list_updated");
      io.to(bus.collegeId.toString()).emit("bus_updated", {
        busId: bus._id.toString(),
      });
    }

    res.status(200).json({ message: "Teacher override tracking cancelled." });
  } catch (error) {
    logger.error(`Error cancelling override: ${(error as Error).message}`);
    res.status(500).json({ message: (error as Error).message });
  }
};
