import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../../models/User.model";
import logger from "../../utils/logger";

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

    // Check if already logged in
    if (user.isLoggedIn) {
      logger.warn(`User ${email} attempted login while already logged in.`);
      return res.status(403).json({
        message:
          "You are already logged in on another device. Please logout from that device first.",
      });
    }

    // Set isLoggedIn to true
    user.isLoggedIn = true;
    await user.save();

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
