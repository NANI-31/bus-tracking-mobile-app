import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User, { IUser } from "@/models/User.model";
import College from "@/models/College.model";
import mongoose from "mongoose";
import crypto from "crypto";
import logger from "@/utils/logger";

const JWT_SECRET =
  process.env.JWT_SECRET || "your_jwt_secret_key_change_in_production";

export const register = async (req: Request, res: Response) => {
  try {
    const {
      email,
      password,
      fullName,
      role,
      collegeId,
      phoneNumber,
      rollNumber,
      referrerCode,
    } = req.body;

    // Register Logic
    if (role === "parent") {
      if (!phoneNumber) {
        return res
          .status(400)
          .json({ message: "Phone number is required for parents" });
      }
      // Check if user exists by phone
      const userByPhone = await User.findOne({ phoneNumber });
      if (userByPhone) {
        return res
          .status(400)
          .json({ message: "User with this phone number already exists" });
      }
      // Check if user exists by email (if provided)
      if (email) {
        const userByEmail = await User.findOne({ email });
        if (userByEmail) {
          return res
            .status(400)
            .json({ message: "User with this email already exists" });
        }
      }
    } else {
      // For other roles, email is required
      if (!email) {
        return res.status(400).json({ message: "Email is required" });
      }
      // Check if user exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ message: "User already exists" });
      }
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    let finalCollegeId = collegeId;

    // Special logic for Bus Coordinators: Create a new college if the ID is not a valid ObjectId
    if (
      role === "busCoordinator" &&
      collegeId &&
      !mongoose.Types.ObjectId.isValid(collegeId)
    ) {
      try {
        logger.info(`Creating new college for coordinator: ${collegeId}`);
        const newCollege = new College({
          name: collegeId
            .split("_")
            .map((word: string) => word.charAt(0).toUpperCase() + word.slice(1))
            .join(" "),
          allowedDomains: email ? [email.split("@")[1]] : [],
          createdBy: "system_registration",
          verified: false,
        });
        const savedCollege = await newCollege.save();
        finalCollegeId = savedCollege._id;
        logger.info(`New college created with ID: ${finalCollegeId}`);
      } catch (collegeError) {
        logger.error(
          "Error creating college during registration:",
          collegeError,
        );
        // Fallback or re-throw? Let's re-throw to prevent inconsistent user state
        throw collegeError;
      }
    }

    // Referral Logic
    let referredBy: string | undefined;
    if (referrerCode) {
      const referrer = await User.findOne({
        referralCode: referrerCode.toUpperCase(),
      });
      if (referrer) {
        referredBy = referrer._id.toString();
      }
    }

    const referralCode = crypto.randomBytes(3).toString("hex").toUpperCase();

    // Create user
    const newUser = new User({
      _id: crypto.randomUUID(),
      email, // Can be undefined for parents
      password: hashedPassword,
      fullName,
      role,
      collegeId: finalCollegeId,
      phoneNumber,
      rollNumber,
      approved: role === "parent" || role === "driver", // Parents and drivers auto-approved
      emailVerified: false,
      needsManualApproval: role !== "parent" && role !== "driver",
      createdAt: new Date(),
      referralCode,
      referredBy,
    });

    await newUser.save();

    // Create tokens
    const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET!;
    const accessToken = jwt.sign(
      {
        id: newUser._id,
        email: newUser.email,
        fullName: newUser.fullName,
        role: newUser.role,
        collegeId: newUser.collegeId,
        approved: newUser.approved,
        tokenVersion: newUser.tokenVersion,
      },
      JWT_SECRET,
      { expiresIn: "2h" },
    );

    const refreshToken = jwt.sign(
      {
        id: newUser._id,
        tokenVersion: newUser.tokenVersion,
      },
      REFRESH_TOKEN_SECRET,
      { expiresIn: "7d" },
    );

    res.status(201).json({
      success: true,
      token: accessToken,
      refreshToken,
      user: {
        id: newUser._id,
        email: newUser.email,
        fullName: newUser.fullName,
        role: newUser.role,
        collegeId: newUser.collegeId,
        approved: newUser.approved,
      },
    });
  } catch (error) {
    logger.error("Registration error:", error);
    res.status(500).json({ message: "Server error during registration" });
  }
};
