import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../../models/User";
import logger from "../../utils/logger";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error("JWT_SECRET must be set in environment variables");
}

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    console.log("LOGIN REQUEST:", { email, passwordLength: password?.length });

    // Check user by email OR phone (logic from original controller)
    let user = await User.findOne({ email });
    if (!user) {
      user = await User.findOne({ phoneNumber: email });
    }

    if (!user) {
      console.log("LOGIN FAIL: User not found");
      return res.status(400).json({ message: "Invalid credentials" });
    }

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

    // Create token
    console.log("LOGIN: Creating token...");
    const token = jwt.sign(
      {
        id: user._id,
        email: user.email,
        fullName: user.fullName, // Added fullName
        role: user.role,
        collegeId: user.collegeId,
        approved: user.approved,
      },
      JWT_SECRET,
      { expiresIn: "30d" }
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
