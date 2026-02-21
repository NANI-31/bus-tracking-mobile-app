import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "@/models/User.model";
import logger from "@/utils/logger";
import { AuditService } from "@/services/AuditService";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error("JWT_SECRET must be set in environment variables");
}

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    console.log("LOGIN REQUEST:", { email, passwordLength: password?.length });

    // Check user by email OR phone
    const user = await User.findOne({
      $or: [{ email: email }, { phoneNumber: email }],
    });

    if (!user) {
      console.log("LOGIN FAIL: User not found");
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // --- ROLE-BASED LOGIN RESTRICTION ---
    // Students and Teachers must use Email.
    // Parents and Drivers can use Email or Phone.
    if (["student", "teacher"].includes(user.role)) {
      // If the input identifier matches the phone number but NOT the email,
      // it means they tried to login with a phone number.
      // We perform a case-insensitive comparison for email just in case.
      const userEmail = (user.email || "") as string;
      const inputEmail = (email || "") as string;
      const isEmailLogin = userEmail.toLowerCase() === inputEmail.toLowerCase();
      if (!isEmailLogin) {
        logger.warn(
          `Login blocked: ${user.role} attempted login with phone number.`,
        );
        return res.status(400).json({
          message: "Students and Teachers must log in using Email Address.",
        });
      }
    }
    // ------------------------------------

    logger.info(`${user.fullName} (${user.role}) login attempt...`);
    console.log("LOGIN: User found", { id: user._id, role: user.role });

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      console.log("LOGIN FAIL: Password mismatch");
      logger.warn(`Invalid password for user: ${email}`);
      return res.status(400).json({ message: "Invalid credentials" });
    }
    console.log("LOGIN: Password matched");

    // Check if email is verified
    if (user.role !== "parent" && !user.emailVerified) {
      logger.warn(`Email not verified for user: ${email}`);
      return res.status(400).json({
        message: "Email not verified. Please verify your email.",
        requiresVerification: true,
      });
    }

    // Increment tokenVersion and set isLoggedIn to true atomically
    const updatedUser = await User.findOneAndUpdate(
      { _id: user._id },
      {
        $inc: { tokenVersion: 1 },
        $set: { isLoggedIn: true },
      },
      { new: true },
    );

    if (!updatedUser) {
      throw new Error("Failed to update user session");
    }

    // Create token
    console.log("LOGIN: Creating token...");
    const token = jwt.sign(
      {
        id: updatedUser._id,
        email: updatedUser.email,
        fullName: updatedUser.fullName,
        role: updatedUser.role,
        collegeId: updatedUser.collegeId,
        approved: updatedUser.approved,
        tokenVersion: updatedUser.tokenVersion,
      },
      JWT_SECRET,
      { expiresIn: "30d" },
    );
    console.log("LOGIN: Token created");

    const userData = {
      id: user._id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      collegeId: user.collegeId,
      approved: user.approved,
    };

    let idPrefix = "USR";
    switch (user.role) {
      case "student":
        idPrefix = "STU";
        break;
      case "driver":
        idPrefix = "DRI";
        break;
      case "teacher":
        idPrefix = "TEA";
        break;
      case "parent":
        idPrefix = "PAR";
        break;
      case "admin":
        idPrefix = "ADM";
        break;
      case "busCoordinator":
        idPrefix = "CRD";
        break;
    }

    logger.info(`${user.fullName} (${user.role}) login successful.`);

    // Audit Log for login
    try {
      // Temporarily set req.user so AuditService can read user info
      (req as any).user = {
        id: String(user._id),
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        collegeId: user.collegeId,
      };
      await AuditService.log({
        req,
        action: "USER_LOGIN",
        resource: "User",
        resourceId: String(user._id),
        resourceName: user.fullName,
        collegeId: user.collegeId ? String(user.collegeId) : undefined,
      });
    } catch (auditErr) {
      logger.warn("Failed to create login audit log", auditErr);
    }

    res.json({
      success: true,
      token,
      user: userData,
    });
  } catch (error) {
    console.error("LOGIN CRITICAL ERROR:", error);
    logger.error("Login error details:", error);
    if (error instanceof Error) {
      logger.error(`Stack trace: ${error.stack}`);
    }
    res.status(500).json({ message: "Server error during login" });
  }
};
