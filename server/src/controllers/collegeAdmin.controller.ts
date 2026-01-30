import { Response } from "express";
import { AuthRequest } from "../middleware/authMiddleware";
import User from "../models/User";
import College from "../models/College";
import { Bus } from "../models/Bus";
import Route from "../models/Route";
import AuditLog from "../models/AuditLog";

/**
 * Get statistics for the admin's college
 */
export const getCollegeStats = async (req: AuthRequest, res: Response) => {
  try {
    const collegeId = req.user?.collegeId;
    if (!collegeId) {
      return res.status(400).json({ message: "College ID missing from token" });
    }

    const [userCount, busCount, routeCount, pendingApprovals] =
      await Promise.all([
        User.countDocuments({ collegeId }),
        Bus.countDocuments({ collegeId }),
        Route.countDocuments({ collegeId }),
        User.countDocuments({
          collegeId,
          needsManualApproval: true,
          approved: false,
        }),
      ]);

    res.json({
      userCount,
      busCount,
      routeCount,
      pendingApprovals,
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Get all users belonging to the admin's college
 */
export const getCollegeUsers = async (req: AuthRequest, res: Response) => {
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
  req: AuthRequest,
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
      { new: true },
    );

    if (!college) {
      return res.status(404).json({ message: "College not found" });
    }

    // Log the action
    await AuditLog.create({
      userId: req.user?.id,
      userEmail: req.user?.email,
      userName: req.user?.fullName || "College Admin",
      action: "college.update_settings",
      resource: "college",
      resourceId: collegeId,
      collegeId: collegeId,
      newState: req.body,
    });

    res.json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
