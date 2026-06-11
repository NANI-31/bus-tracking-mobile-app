import { Request, Response } from "express";
import User from "@/models/User.model";
import { IAuthRequest } from "@/types";
import College from "@/models/College.model";
import { AuditService } from "@/services/AuditService";
import * as ExcelJS from "exceljs";
import path from "path";
import fs from "fs";
import { sendEmail } from "@/utils/emailService";
import { getOtpEmailTemplate } from "@/utils/emailTemplates";

export const createUser = async (req: Request, res: Response) => {
  try {
    console.log("Creating user with body:", req.body); // Debug log
    const newUser = new User(req.body);
    const savedUser = await newUser.save();

    // Audit Log (if performed by an admin, though usually self-reg)
    if ((req as IAuthRequest).user) {
      await AuditService.log({
        req: req as IAuthRequest,
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

export const getAllUsers = async (req: IAuthRequest, res: Response) => {
  try {
    let query = {};

    console.log(`[getAllUsers] v2 - role=${req.user?.role}, id=${req.user?.id}`);

    // Multi-tenancy: College admins and coordinators only see their own college's users
    if (
      req.user?.role === "collegeAdmin" ||
      req.user?.role === "busCoordinator"
    ) {
      query = { collegeId: req.user.collegeId };
    } else if (req.user?.role !== "superAdmin" && req.user?.role !== "admin") {
      console.warn(`[getAllUsers] Unauthorized role: ${req.user?.role}`);
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
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });

    const { email, ...otherData } = req.body;
    let verificationRequired = false;

    // Handle email change logic
    if (email && email !== user.email) {
      // Check if email is already taken
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ message: "Email already in use" });
      }

      // Generate OTP for email change
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      user.otp = otp;
      user.otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
      user.pendingEmail = email;
      verificationRequired = true;

      // Send OTP to NEW email
      await sendEmail(
        email,
        "Verify your new email address",
        `Your verification code is: ${otp}. It expires in 10 minutes.`,
        getOtpEmailTemplate(user.fullName, otp),
      ).catch((err) =>
        console.error("[UserController] Email change verification error:", err),
      );
    }

    // Update other fields
    Object.assign(user, otherData);
    await user.save();

    // Emit socket event for real-time updates
    const io = req.app.get("io");
    if (user.collegeId) {
      io.to(user.collegeId.toString()).emit("user_list_updated");
    }

    res.status(200).json({
      success: true,
      user,
      verificationRequired,
      message: verificationRequired
        ? "Verification OTP sent to your new email."
        : "Profile updated successfully",
    });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const deleteUser = async (req: IAuthRequest, res: Response) => {
  try {
    const userToDelete = await User.findById(req.params.id);
    if (!userToDelete)
      return res.status(404).json({ message: "User not found" });

    // Security Check: CollegeAdmin and busCoordinator can only delete users from their own college
    if (
      req.user?.role === "collegeAdmin" ||
      req.user?.role === "busCoordinator"
    ) {
      if (
        !userToDelete.collegeId ||
        userToDelete.collegeId.toString() !== req.user.collegeId.toString()
      ) {
        return res.status(403).json({
          message: `Access denied. ${
            req.user.role === "busCoordinator" ? "Coordinators" : "Admins"
          } can only delete users from their own college.`,
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
      { returnDocument: 'after' },
    );
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: "Error verifying email", error });
  }
};

export const activateManualPremium = async (
  req: IAuthRequest,
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
      expiry = new Date(now.getTime() + 1 * 60 * 1000); // 1 minute for testing
    } else if (planType === "semesterly") {
      expiry = new Date(now.getTime() + 1.5 * 60 * 1000); // 1.5 minutes for testing
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

export const bulkActivatePremium = async (req: IAuthRequest, res: Response) => {
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

    // Read Excel using exceljs
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(req.file.buffer as any);
    const worksheet = workbook.getWorksheet(1); // Use the first sheet

    if (!worksheet) {
      return res
        .status(400)
        .json({ message: "Worksheet not found in Excel file" });
    }

    const results = {
      success: 0,
      failed: 0,
      errors: [] as string[],
    };

    const now = new Date();
    const msToAdd = planType === "semesterly" ? 1.5 * 60 * 1000 : 1 * 60 * 1000;

    // Helper to find column index (1-based for exceljs)
    const findColumnIndex = (
      row: ExcelJS.Row,
      searchNames: string[],
    ): number => {
      let foundIndex = -1;
      row.eachCell((cell, colNumber) => {
        const val = cell.value?.toString().toLowerCase().replace(/\s/g, "");
        if (
          val &&
          searchNames.some((name) =>
            val.includes(name.toLowerCase().replace(/\s/g, "")),
          )
        ) {
          foundIndex = colNumber;
        }
      });
      return foundIndex;
    };

    // Get header row (first row)
    const headerRow = worksheet.getRow(1);
    const rollNumberIdx = findColumnIndex(headerRow, [
      "rollnumber",
      "roll number",
    ]);
    const emailIdx = findColumnIndex(headerRow, ["email"]);

    if (rollNumberIdx === -1 && emailIdx === -1) {
      return res.status(400).json({
        message: "Could not find 'Roll Number' or 'Email' column in Excel file",
      });
    }

    // Iterate through rows starting from row 2
    for (let i = 2; i <= worksheet.rowCount; i++) {
      const row = worksheet.getRow(i);
      try {
        const rollNumberValue =
          rollNumberIdx !== -1
            ? row.getCell(rollNumberIdx).value?.toString().trim()
            : "";
        const emailValue =
          emailIdx !== -1 ? row.getCell(emailIdx).value?.toString().trim() : "";

        const identifier = rollNumberValue || emailValue || "";
        if (!identifier) continue;

        const targetUser = await User.findOne({
          collegeId,
          $or: [{ rollNumber: identifier }, { email: identifier }],
        });

        if (targetUser) {
          let expiry = new Date(now.getTime() + msToAdd);

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
        results.errors.push(
          `Error processing row ${i}: ${(err as Error).message}`,
        );
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
