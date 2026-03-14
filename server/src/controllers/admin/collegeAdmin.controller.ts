import { Response } from "express";
import { IAuthRequest } from "@/types";
import User from "@/models/User.model";
import College from "@/models/College.model";
import { Bus } from "@/models/Bus.model";
import Route from "@/models/Route.model";
import { AuditService } from "@/services/AuditService";
import { s3Service } from "@/services/s3.service";
import MetricSnapshot from "@/models/MetricSnapshot.model";

/**
 * Get statistics for the admin's college
 */
export const getCollegeStats = async (req: IAuthRequest, res: Response) => {
  try {
    const collegeId = req.user?.collegeId;
    if (!collegeId) {
      return res.status(400).json({ message: "College ID missing from token" });
    }

    const [userCount, busCount, routeCount, pendingApprovals, s3Stats] =
      await Promise.all([
        User.countDocuments({ collegeId }),
        Bus.countDocuments({ collegeId }),
        Route.countDocuments({ collegeId }),
        User.countDocuments({
          collegeId,
          needsManualApproval: true,
          approved: false,
        }),
        s3Service.getBucketStats(`voice-messages/${collegeId}`),
      ]);

    res.json({
      userCount,
      busCount,
      routeCount,
      pendingApprovals,
      s3: {
        totalSize: (s3Stats.totalSize / (1024 * 1024)).toFixed(2) + " MB",
        objectCount: s3Stats.objectCount,
      },
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Get all users belonging to the admin's college
 */
export const getCollegeUsers = async (req: IAuthRequest, res: Response) => {
  try {
    const collegeId = req.user?.collegeId;
    const { role, approved } = req.query;

    const query: any = { collegeId };
    if (role) query.role = role;
    if (approved !== undefined) query.approved = approved === "true";

    const users = await User.find(query).sort({ createdAt: -1 });
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Update college settings
 */
export const updateCollegeSettings = async (
  req: IAuthRequest,
  res: Response,
) => {
  try {
    const collegeId = req.user?.collegeId;
    const { name, allowedDomains, settings } = req.body;

    const college = await College.findByIdAndUpdate(
      collegeId,
      {
        $set: {
          ...(name && { name }),
          ...(allowedDomains && { allowedDomains }),
          ...(settings && { settings }),
          updatedAt: new Date(),
        },
      },
      { returnDocument: 'after' },
    );

    if (!college) {
      return res.status(404).json({ message: "College not found" });
    }

    // Audit Log
    await AuditService.log({
      req,
      action: "COLLEGE_UPDATE_SETTINGS",
      resource: "College",
      resourceId: String(collegeId),
      resourceName: college.name,
      newState: req.body,
    });

    res.json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Get historical storage metrics for the admin's college
 */
export const getCollegeStorageHistory = async (
  req: IAuthRequest,
  res: Response,
) => {
  try {
    const collegeId = req.user?.collegeId;
    if (!collegeId) {
      return res.status(400).json({ message: "College ID missing from token" });
    }

    const { startDate, endDate } = req.query;
    const query: any = { collegeId };

    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate as string);
      if (endDate) query.date.$lte = new Date(endDate as string);
    }

    const history = await MetricSnapshot.find(query).sort({ date: 1 });
    res.json(history);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
