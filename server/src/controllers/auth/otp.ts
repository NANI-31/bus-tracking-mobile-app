import { Request, Response } from "express";
import User from "../../models/User";
import { sendEmail } from "../../utils/emailService";
import { getOtpEmailTemplate } from "../../utils/emailTemplates";

export const sendOtp = async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    user.otp = otp;
    user.otpExpires = otpExpires;
    await user.save();

    await sendEmail(
      email,
      "Your OTP Code",
      `Your verification code is: ${otp}. It expires in 10 minutes.`,
      getOtpEmailTemplate(user.fullName, otp)
    );

    res.json({ message: "OTP sent to email" });
  } catch (error) {
    console.error("Send OTP error:", error);
    res.status(500).json({ message: "Error sending OTP" });
  }
};

export const verifyOtp = async (req: Request, res: Response) => {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.otp || !user.otpExpires) {
      return res.status(400).json({ message: "Invalid Request" });
    }

    if (user.otp !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (user.otpExpires < new Date()) {
      return res.status(400).json({ message: "OTP Expired" });
    }

    // OTP is valid
    user.emailVerified = true;
    user.otp = undefined;
    user.otpExpires = undefined;
    await user.save();

    res.json({ message: "Email verified successfully", success: true });
  } catch (error) {
    console.error("Verify OTP error:", error);
    res.status(500).json({ message: "Error verifying OTP" });
  }
};
