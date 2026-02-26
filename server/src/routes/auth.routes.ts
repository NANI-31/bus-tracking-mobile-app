import express from "express";
import {
  register,
  login,
  sendOtp,
  verifyOtp,
  verifyEmailChange,
  resetPassword,
  logout,
} from "../controllers/auth";
// import { AuthController } from "@/controllers/auth";

import { protect } from "@/middleware/authMiddleware";

const router = express.Router();

// router.post("/login", AuthController.loginUser);
router.post("/register", register);
router.post("/login", login);
router.post("/logout", protect, logout);
router.post("/send-otp", sendOtp);
router.post("/verify-otp", verifyOtp);
router.post("/verify-email-change", verifyEmailChange);
router.post("/reset-password", resetPassword);

export default router;
