import { Request, Response } from "express";
import { AuthRequest } from "../middleware/authMiddleware";
import College from "../models/College";
import User from "../models/User";
import AuditLog from "../models/AuditLog";

/**
 * Get system-wide statistics for Super Admin
 */
export const getSystemStats = async (req: AuthRequest, res: Response) => {
  try {
    const [collegeCount, userCount, activeBuses, pendingColleges] =
      await Promise.all([
        College.countDocuments(),
        User.countDocuments(),
        // Assuming 'running' is the status for active buses
        User.countDocuments({ role: "driver" }), // Simple proxy for now
        College.countDocuments({ verified: false }),
      ]);

    res.json({
      collegeCount,
      userCount,
      activeBuses,
      pendingColleges,
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Verify a college
 */
export const verifyCollege = async (req: AuthRequest, res: Response) => {
  try {
    const { collegeId } = req.params;
    const college = await College.findByIdAndUpdate(
      collegeId,
      { verified: true, updatedAt: new Date() },
      { new: true },
    );

    if (!college) {
      return res.status(404).json({ message: "College not found" });
    }

    // Log the action
    await AuditLog.create({
      userId: req.user?.id,
      userEmail: req.user?.email,
      userName: req.user?.fullName || "Super Admin",
      action: "college.verify",
      resource: "college",
      resourceId: collegeId,
      newState: { verified: true },
    });

    res.json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

/**
 * Suspend a college
 */
export const suspendCollege = async (req: AuthRequest, res: Response) => {
  try {
    const { collegeId } = req.params;
    const { reason } = req.body;

    const college = await College.findByIdAndUpdate(
      collegeId,
      {
        suspended: true,
        suspensionReason: reason,
        updatedAt: new Date(),
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
      userName: req.user?.fullName || "Super Admin",
      action: "college.suspend",
      resource: "college",
      resourceId: collegeId,
      newState: { suspended: true, reason },
    });

    res.json(college);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
