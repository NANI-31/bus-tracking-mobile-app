import express from "express";
import rateLimit from "express-rate-limit";
import {
  register,
  login,
  sendOtp,
  verifyOtp,
  verifyEmailChange,
  resetPassword,
  logout,
  refreshToken,
} from "../controllers/auth";
// import { AuthController } from "@/controllers/auth";

import { protect } from "@/middleware/authMiddleware";

const router = express.Router();

// Rate limiter for auth endpoints (brute-force protection)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 attempts per 15 minutes
  message: { message: "Too many attempts. Please try again in 15 minutes." },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Only count failed attempts
});

// Stricter limiter for OTP/password reset (anti-abuse)
const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per 15 minutes
  message: { message: "Too many OTP requests. Please try again later." },
  standardHeaders: true,
  legacyHeaders: false,
});

// router.post("/login", AuthController.loginUser);
router.post("/register", authLimiter, register);
router.post("/login", authLimiter, login);
router.post("/logout", protect, logout);
router.post("/send-otp", otpLimiter, sendOtp);
router.post("/verify-otp", otpLimiter, verifyOtp);
router.post("/verify-email-change", authLimiter, verifyEmailChange);
router.post("/reset-password", otpLimiter, resetPassword);
router.post("/refresh-token", otpLimiter, refreshToken);

export default router;
