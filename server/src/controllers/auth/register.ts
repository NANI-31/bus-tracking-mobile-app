import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User, { IUser } from "../../models/User";
import crypto from "crypto";

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

    // Create user
    const newUser = new User({
      _id: crypto.randomUUID(),
      email, // Can be undefined for parents
      password: hashedPassword,
      fullName,
      role,
      collegeId,
      phoneNumber,
      rollNumber,
      approved: role === "parent", // Parents auto-approved (from original logic)
      emailVerified: false,
      needsManualApproval: role !== "parent",
      createdAt: new Date(),
    });

    await newUser.save();

    // Create token
    const token = jwt.sign(
      { id: newUser._id, email: newUser.email, role: newUser.role },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    res.status(201).json({
      success: true,
      token,
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
    console.error("Registration error:", error);
    res.status(500).json({ message: "Server error during registration" });
  }
};
