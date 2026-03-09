import { Request, Response } from "express";
import User from "@/models/User.model";
import { IAuthRequest } from "@/types";
import logger from "@/utils/logger";
import { AuditService } from "@/services/AuditService";

export const logout = async (req: Request, res: Response) => {
  try {
    const authReq = req as IAuthRequest;

    // Check if user is authenticated (should be handled by middleware, but good to double check)
    if (!authReq.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    const userId = authReq.user.id;
    const userFullName = authReq.user.fullName || "Unknown";
    const userCollegeId = authReq.user.collegeId;

    // Find user and update session version (invalidates all issued tokens)
    await User.findByIdAndUpdate(userId, {
      $set: { isLoggedIn: false },
      $inc: { tokenVersion: 1 },
    });

    console.log(`LOGOUT: User ${userId} logged out successfully.`);

    // Audit Log for logout
    try {
      await AuditService.log({
        req,
        action: "USER_LOGOUT",
        resource: "User",
        resourceId: userId,
        resourceName: userFullName,
        collegeId: userCollegeId ? String(userCollegeId) : undefined,
      });
    } catch (auditErr) {
      logger.warn("Failed to create logout audit log", auditErr);
    }

    res.status(200).json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (error) {
    console.error("LOGOUT ERROR:", error);
    res.status(500).json({ message: "Server error during logout" });
  }
};
