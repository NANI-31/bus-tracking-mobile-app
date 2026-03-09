import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "@/models/User.model";
import logger from "@/utils/logger";
import { AuditService } from "@/services/AuditService";

const JWT_SECRET = process.env.JWT_SECRET!;
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET!;

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    // 1. Find user by email OR phone
    const user = await User.findOne({
      $or: [{ email: email }, { phoneNumber: email }],
    });

    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // 2. CHECK ACCOUNT LOCKOUT
    if (user.lockUntil && user.lockUntil > new Date()) {
      const remainingMinutes = Math.ceil(
        (user.lockUntil.getTime() - Date.now()) / (60 * 1000),
      );
      logger.warn(`Locked account login attempt: ${email}`);
      return res.status(423).json({
        message: `Account is temporarily locked due to multiple failed attempts. Try again in ${remainingMinutes} minutes.`,
        code: "ACCOUNT_LOCKED",
      });
    }

    // 3. ROLE-BASED LOGIN RESTRICTION
    if (["student", "teacher"].includes(user.role)) {
      const userEmail = (user.email || "") as string;
      const inputEmail = (email || "") as string;
      const isEmailLogin = userEmail.toLowerCase() === inputEmail.toLowerCase();
      if (!isEmailLogin) {
        return res.status(400).json({
          message: "Students and Teachers must log in using Email Address.",
        });
      }
    }

    // 4. CHECK PASSWORD
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      // Increment login attempts
      user.loginAttempts += 1;
      if (user.loginAttempts >= 5) {
        user.lockUntil = new Date(Date.now() + 15 * 60 * 1000); // 15 min lockout
        logger.warn(`Account locked: ${email} for 15 minutes`);
      }
      await user.save();

      return res.status(400).json({ message: "Invalid credentials" });
    }

    // 5. CHECK EMAIL VERIFICATION
    if (user.role !== "parent" && !user.emailVerified) {
      return res.status(400).json({
        message: "Email not verified. Please verify your email.",
        requiresVerification: true,
      });
    }

    // 6. SUCCESS - RESET ATTEMPTS & UPDATE SESSION
    user.loginAttempts = 0;
    user.lockUntil = undefined;
    user.tokenVersion += 1;
    user.isLoggedIn = true;
    await user.save();

    // 7. CREATE TOKENS
    // Access Token (Short-lived: 15 minutes)
    const accessToken = jwt.sign(
      {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        collegeId: user.collegeId,
        approved: user.approved,
        tokenVersion: user.tokenVersion,
      },
      JWT_SECRET,
      { expiresIn: "15m" },
    );

    // Refresh Token (Long-lived: 7 days)
    const refreshToken = jwt.sign(
      {
        id: user._id,
        tokenVersion: user.tokenVersion,
      },
      REFRESH_TOKEN_SECRET,
      { expiresIn: "7d" },
    );

    const userData = {
      id: user._id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      collegeId: user.collegeId,
      approved: user.approved,
    };

    logger.info(`${user.fullName} (${user.role}) login successful.`);

    // Audit Log for login
    try {
      (req as any).user = { ...userData };
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
      token: accessToken, // Keep key name "token" for backward compatibility if needed, but labeled as accessToken
      refreshToken,
      user: userData,
    });
  } catch (error) {
    logger.error("Login Error:", error);
    res.status(500).json({ message: "Server error during login" });
  }
};
