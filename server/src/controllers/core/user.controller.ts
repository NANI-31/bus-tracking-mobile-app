import { Request, Response } from "express";
import User from "../../models/User.model";
import { AuthRequest } from "../../middleware/authMiddleware";
import College from "../../models/College.model";
import { AuditService } from "../../services/AuditService";
import * as xlsx from "xlsx";
import path from "path";
import fs from "fs";

export const createUser = async (req: Request, res: Response) => {
  try {
    console.log("Creating user with body:", req.body); // Debug log
    const newUser = new User(req.body);
    const savedUser = await newUser.save();

    // Audit Log (if performed by an admin, though usually self-reg)
    if ((req as AuthRequest).user) {
      await AuditService.log({
        req: req as AuthRequest,
        action: "USER_CREATE",
        resource: "User",
        resourceId: savedUser._id.toString(),
        resourceName: savedUser.fullName,
        newState: savedUser.toObject(),
      });
    }

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

export const getAllUsers = async (req: AuthRequest, res: Response) => {
  try {
    let query = {};

    // Multi-tenancy: College admins and coordinators only see their own college's users
    if (
      req.user?.role === "collegeAdmin" ||
      req.user?.role === "busCoordinator"
    ) {
      query = { collegeId: req.user.collegeId };
    } else if (req.user?.role !== "superAdmin") {
      return res.status(403).json({ message: "Not authorized" });
    }

    const users = await User.find(query);
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

    // Audit Log
    if ((req as AuthRequest).user) {
      await AuditService.log({
        req: req as AuthRequest,
        action: "USER_UPDATE",
        resource: "User",
        resourceId: updatedUser._id.toString(),
        resourceName: updatedUser.fullName,
        newState: updatedUser.toObject(),
      });
    }

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

    // Audit Log
    await AuditService.log({
      req: req,
      action: "USER_DELETE",
      resource: "User",
      resourceId: userToDelete._id.toString(),
      resourceName: userToDelete.fullName,
      previousState: userToDelete.toObject(),
    });

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

// Dev helper: Get limited user list for login selection (No sensitive data)
export const getDevUsers = async (req: Request, res: Response) => {
  try {
    const users = await User.find(
      { role: { $in: ["collegeAdmin", "superAdmin"] } },
      "fullName email role collegeId",
    ).limit(50);
    res.status(200).json(users);
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

export const activateManualPremium = async (
  req: AuthRequest,
  res: Response,
) => {
  try {
    const { userId, planType } = req.body; // 'monthly' or 'semesterly'
    const adminId = req.user?.id;

    if (!userId || !planType) {
      return res.status(400).json({ message: "UserId and planType required" });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // Check if manual premium is allowed for this college
    const college = await College.findById(user.collegeId);
    if (!college?.allowManualPremium) {
      return res
        .status(403)
        .json({ message: "Manual premium not enabled for this college" });
    }

    // Calculate expiry
    const now = new Date();
    let expiry = new Date(user.premiumUntil || now);
    if (expiry < now) expiry = now;

    if (planType === "monthly") {
      expiry.setDate(expiry.getDate() + 30);
    } else if (planType === "semesterly") {
      expiry.setDate(expiry.getDate() + 120);
    } else {
      return res.status(400).json({ message: "Invalid planType" });
    }

    user.isPremium = true;
    user.premiumUntil = expiry;
    await user.save();

    // Audit Log
    await AuditService.log({
      req,
      action: "USER_PREMIUM_ACTIVATE",
      resource: "User",
      resourceId: user._id.toString(),
      resourceName: user.fullName,
      newState: { planType, premiumUntil: expiry },
      collegeId: String(user.collegeId),
    });

    res
      .status(200)
      .json({ message: "Premium activated", premiumUntil: expiry });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const bulkActivatePremium = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "Excel file required" });
    }

    const { planType } = req.body;
    const collegeId = req.user?.collegeId;

    if (!collegeId) return res.status(403).json({ message: "Unauthorized" });

    const college = await College.findById(collegeId);
    if (!college?.allowManualPremium) {
      return res
        .status(403)
        .json({ message: "Manual premium not enabled for this college" });
    }

    // Read Excel
    const workbook = xlsx.read(req.file.buffer, { type: "buffer" });
    const sheetName = workbook.SheetNames[0];
    const data = xlsx.utils.sheet_to_json(workbook.Sheets[sheetName]) as any[];

    const results = {
      success: 0,
      failed: 0,
      errors: [] as string[],
    };

    const now = new Date();
    const daysToAdd = planType === "semesterly" ? 120 : 30;

    for (const row of data) {
      try {
        // Support Roll Number or Email headers
        const identifier = (
          row.rollNumber ||
          row.RollNumber ||
          row.email ||
          row.Email ||
          ""
        )
          .toString()
          .trim();
        if (!identifier) continue;

        const targetUser = await User.findOne({
          collegeId,
          $or: [{ rollNumber: identifier }, { email: identifier }],
        });

        if (targetUser) {
          let expiry = new Date(targetUser.premiumUntil || now);
          if (expiry < now) expiry = now;
          expiry.setDate(expiry.getDate() + daysToAdd);

          targetUser.isPremium = true;
          targetUser.premiumUntil = expiry;
          await targetUser.save();
          results.success++;
        } else {
          results.failed++;
          results.errors.push(`User not found: ${identifier}`);
        }
      } catch (err) {
        results.failed++;
        results.errors.push(`Error processing row: ${(err as Error).message}`);
      }
    }

    // Audit Log
    await AuditService.log({
      req,
      action: "USER_PREMIUM_BULK",
      resource: "User",
      resourceId: "multiple",
      newState: {
        planType,
        successCount: results.success,
        failedCount: results.failed,
      },
    });

    res.status(200).json(results);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
