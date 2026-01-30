import { Request, Response } from "express";
import User from "../models/User";
import AuditLog from "../models/AuditLog";
import { AuthRequest } from "../middleware/authMiddleware";

export const createUser = async (req: Request, res: Response) => {
  try {
    console.log("Creating user with body:", req.body); // Debug log
    const newUser = new User(req.body);
    const savedUser = await newUser.save();
    res.status(201).json(savedUser);
  } catch (error) {
    console.error("Error creating user:", error); // Debug log
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getUser = async (req: Request, res: Response) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      console.warn(`[UserController] User not found: ${req.params.id}`);
      return res.status(404).json({ message: "User not found" });
    }
    res.status(200).json(user);
  } catch (error) {
    console.error(
      `[UserController] Error fetching user ${req.params.id}:`,
      error,
    );
    res.status(500).json({ message: (error as Error).message });
  }
};

export const getAllUsers = async (req: Request, res: Response) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    console.error("GETALLUSERS ERROR:", error);
    res.status(500).json({ message: (error as Error).message });
  }
};

export const updateUser = async (req: Request, res: Response) => {
  try {
    const updatedUser = await User.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    if (!updatedUser)
      return res.status(404).json({ message: "User not found" });

    // Emit socket event for real-time updates
    const io = req.app.get("io");
    if (updatedUser.collegeId) {
      io.to(updatedUser.collegeId.toString()).emit("user_list_updated");
    }

    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const deleteUser = async (req: AuthRequest, res: Response) => {
  try {
    const userToDelete = await User.findById(req.params.id);
    if (!userToDelete)
      return res.status(404).json({ message: "User not found" });

    // Security Check: CollegeAdmin can only delete users from their own college
    if (req.user?.role === "collegeAdmin") {
      if (
        !userToDelete.collegeId ||
        userToDelete.collegeId.toString() !== req.user.collegeId.toString()
      ) {
        return res.status(403).json({
          message:
            "Access denied. You can only delete users from your own college.",
        });
      }
    }

    await User.findByIdAndDelete(req.params.id);

    // Create Audit Log
    try {
      if (req.user) {
        await AuditLog.create({
          userId: req.user.id,
          userEmail: req.user.email,
          userName: req.user.fullName || req.user.email,
          action: "DELETE_USER",
          resource: "User",
          resourceId: userToDelete._id,
          resourceName: userToDelete.fullName,
          collegeId: req.user.collegeId,
          ipAddress: req.ip,
          userAgent: req.get("User-Agent") || "Unknown",
          previousState: userToDelete.toObject(),
        });
      }
    } catch (auditError) {
      console.error(
        "Failed to create audit log for user deletion:",
        auditError,
      );
      // Don't fail the request if audit logging fails, just log the error
    }

    // Emit socket event for real-time updates
    const io = req.app.get("io");
    if (userToDelete.collegeId) {
      io.to(userToDelete.collegeId.toString()).emit("user_list_updated");
    }

    res.status(200).json({ message: "User deleted" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

// Verify email status
export const verifyEmail = async (req: Request, res: Response) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { emailVerified: true },
      { new: true },
    );
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: "Error verifying email", error });
  }
};
