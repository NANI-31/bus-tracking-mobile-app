import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import User from "../../models/User";

export const resetPassword = async (req: Request, res: Response) => {
  try {
    const { email, newPassword } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    res.json({ message: "Password reset successfully", success: true });
  } catch (error) {
    res.status(500).json({ message: "Error resetting password" });
  }
};
