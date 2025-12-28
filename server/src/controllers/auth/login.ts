import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../../models/User";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error("JWT_SECRET must be set in environment variables");
}

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    // Check user by email OR phone (logic from original controller)
    let user = await User.findOne({ email });
    if (!user) {
      user = await User.findOne({ phoneNumber: email });
    }

    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // Check if email is verified
    if (user.role !== "parent" && !user.emailVerified) {
      return res.status(400).json({
        message: "Email not verified. Please verify your email.",
        requiresVerification: true,
      });
    }

    // Create token
    const token = jwt.sign(
      {
        id: user._id,
        email: user.email,
        role: user.role,
        collegeId: user.collegeId,
        approved: user.approved,
      },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    const userData = {
      id: user._id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      collegeId: user.collegeId,
      approved: user.approved,
    };

    console.log(
      `[LoginSuccess] Email: ${user.email}, Role: ${user.role}, ID: ${user._id}`
    );

    res.json({
      success: true,
      token,
      user: userData,
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Server error during login" });
  }
};
