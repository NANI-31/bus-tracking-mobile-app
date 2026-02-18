import { Request, Response } from "express";
import Razorpay from "razorpay";
import crypto from "crypto";
import dotenv from "dotenv";
import User from "../../models/User.model";
import Transaction from "../../models/Transaction.model";
import { AuthRequest } from "../../middleware/authMiddleware";

dotenv.config();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || "",
  key_secret: process.env.RAZORPAY_KEY_SECRET || "",
});

export const createOrder = async (req: Request, res: Response) => {
  if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
    console.error("RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET is not set in .env");
    return res.status(500).json({
      message:
        "Razorpay keys are not configured on the server. Please check .env file.",
    });
  }
  try {
    const { amount, currency = "INR", plan } = req.body;

    const options = {
      amount: amount * 100, // Amount in paise
      currency,
      receipt: `receipt_order_${Date.now()}`,
      notes: {
        plan: plan || "monthly", // Default to monthly if not specified
      },
    };

    const order = await razorpay.orders.create(options);

    console.log("Razorpay Order Created:", order);

    res.status(200).json({
      ...order,
      key_id: process.env.RAZORPAY_KEY_ID,
    });
  } catch (error) {
    console.error("Error creating Razorpay order:", error);
    res.status(500).json({ message: "Something went wrong", error });
  }
};

export const verifyPayment = async (req: Request, res: Response) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } =
      req.body;

    const body = razorpay_order_id + "|" + razorpay_payment_id;

    const expectedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET || "")
      .update(body.toString())
      .digest("hex");

    if (expectedSignature === razorpay_signature) {
      // --- NEW: Update User to Premium ---
      const authReq = req as AuthRequest;
      if (authReq.user) {
        // Fetch order to get the plan from notes
        const order = await razorpay.orders.fetch(razorpay_order_id);
        const plan = order.notes?.plan as string;

        let monthsToAdd = 1;
        if (plan === "semester") {
          monthsToAdd = 4;
        }

        const premiumUntil = new Date();
        premiumUntil.setMonth(premiumUntil.getMonth() + monthsToAdd);

        await User.findByIdAndUpdate(authReq.user.id, {
          isPremium: true,
          premiumUntil: premiumUntil,
        });

        // Create Transaction record
        await Transaction.create({
          userId: authReq.user.id,
          collegeId: authReq.user.collegeId,
          orderId: razorpay_order_id,
          paymentId: razorpay_payment_id,
          amount: (order.amount as any) / 100, // paise to rupees
          currency: order.currency,
          plan: plan,
          premiumUntil: premiumUntil,
          status: "captured",
        });

        console.log(
          `User ${authReq.user.id} updated to Premium (${plan}) until ${premiumUntil}. Transaction logged.`,
        );
      }
      // -----------------------------------

      res
        .status(200)
        .json({ message: "Payment verified successfully", success: true });
    } else {
      res.status(400).json({ message: "Invalid signature", success: false });
    }
  } catch (error) {
    console.error("Error verifying payment:", error);
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const getTransactions = async (req: Request, res: Response) => {
  try {
    const authReq = req as any;
    const { role, collegeId: userCollegeId } = authReq.user;
    const { plan, startDate, endDate, collegeId } = req.query;

    let query: any = {};

    // Role-based filtering
    if (role === "collegeAdmin") {
      query.collegeId = userCollegeId;
    } else if (role === "superAdmin" && collegeId) {
      query.collegeId = collegeId;
    }

    // Plan filtering
    if (plan) {
      query.plan = plan;
    }

    // Date range filtering
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        query.createdAt.$gte = new Date(startDate as string);
      }
      if (endDate) {
        query.createdAt.$lte = new Date(endDate as string);
      }
    }

    const transactions = await Transaction.find(query)
      .populate("userId", "fullName email")
      .sort({ createdAt: -1 });

    res.status(200).json(transactions);
  } catch (error) {
    console.error("Error fetching transactions:", error);
    res.status(500).json({ message: "Internal server error", error });
  }
};
