import { Request, Response } from "express";
import User from "../../models/User.model";
import { AuthRequest } from "../../middleware/authMiddleware";

export const logout = async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;

    // Check if user is authenticated (should be handled by middleware, but good to double check)
    if (!authReq.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    const userId = authReq.user.id;

    // Find user and update isLoggedIn to false
    await User.findByIdAndUpdate(userId, { isLoggedIn: false });

    console.log(`LOGOUT: User ${userId} logged out successfully.`);

    res.status(200).json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (error) {
    console.error("LOGOUT ERROR:", error);
    res.status(500).json({ message: "Server error during logout" });
  }
};
