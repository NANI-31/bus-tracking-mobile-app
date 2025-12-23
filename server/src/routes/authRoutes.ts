import express from "express";
import {
  register,
  login,
  sendOtp,
  verifyOtp,
  resetPassword,
} from "../controllers/auth";
// import { AuthController } from "../controllers/auth";

const router = express.Router();

// router.post("/login", AuthController.loginUser);
router.post("/register", register);
router.post("/login", login);
router.post("/send-otp", sendOtp);
router.post("/verify-otp", verifyOtp);
router.post("/reset-password", resetPassword);

export default router;
