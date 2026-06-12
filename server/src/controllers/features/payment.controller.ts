import { Request, Response } from "express";
import Razorpay from "razorpay";
import crypto from "crypto";
import dotenv from "dotenv";
import User from "@/models/User.model";
import Transaction from "@/models/Transaction.model";
import Plan from "@/models/Plan.model";
import { sendNotificationToDevices } from "@/utils/firebase";
import { IAuthRequest } from "@/types";

dotenv.config();

const getRazorpay = () => {
  return new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID || "",
    key_secret: process.env.RAZORPAY_KEY_SECRET || "",
  });
};

export const createOrder = async (req: Request, res: Response) => {
  if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
    return res.status(500).json({
      message:
        "Razorpay keys are not configured on the server. Please check .env file.",
    });
  }
  try {
    const { amount, currency = "INR", plan } = req.body;
    const authReq = req as IAuthRequest;
    const userId = authReq.user?.id;

    // Validate Plan
    const selectedPlan = await Plan.findOne({ alias: plan, isActive: true });
    if (!selectedPlan) {
      return res
        .status(400)
        .json({ message: "Invalid or inactive plan selected" });
    }

    let finalAmount = selectedPlan.price;
    let appliedDiscount = 0;

    // 1. Early Renewal Discount (5%)
    if (userId) {
      const user = await User.findById(userId);
      if (user && user.isPremium && user.premiumUntil) {
        const threeDaysInMs = 3 * 24 * 60 * 60 * 1000;
        const timeRemaining = user.premiumUntil.getTime() - Date.now();
        if (timeRemaining > threeDaysInMs) {
          appliedDiscount += 5; // 5% discount
        }
      }
    }

    const discountMultiplier = Math.max(0, (100 - appliedDiscount) / 100);
    finalAmount = Math.round(finalAmount * discountMultiplier);

    const options = {
      amount: finalAmount * 100, // Amount in paise
      currency,
      receipt: `receipt_order_${Date.now()}`,
      notes: {
        plan: selectedPlan.alias,
        originalAmount: selectedPlan.price,
        discountApplied: `${appliedDiscount}%`,
        userId: userId,
      },
    };

    const razorpay = getRazorpay();
    const order = await razorpay.orders.create(options as any);

    res.status(200).json({
      ...order,
      key_id: process.env.RAZORPAY_KEY_ID,
      discountedAmount: finalAmount,
      discountPercentage: appliedDiscount,
    });
  } catch (error) {
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
      const authReq = req as IAuthRequest;
      if (authReq.user) {
        const razorpay = getRazorpay();
        const order = await razorpay.orders.fetch(razorpay_order_id);
        const payment = await razorpay.payments.fetch(razorpay_payment_id);

        const plan = order.notes?.plan as string;
        const paymentMethod = (payment as any).method || "unknown";

        const selectedPlan = await Plan.findOne({ alias: plan });
        const currentUser = await User.findById(authReq.user.id);
        const currentExpiry =
          currentUser &&
          currentUser.premiumUntil &&
          currentUser.premiumUntil > new Date()
            ? currentUser.premiumUntil
            : new Date();

        let premiumUntil: Date;
        let isPremium = false;
        let subscriptionPlan = plan;

        if (selectedPlan) {
          premiumUntil = new Date(
            currentExpiry.getTime() +
              selectedPlan.durationDays * 24 * 60 * 60 * 1000,
          );
          isPremium = true;
          subscriptionPlan = selectedPlan.alias;
        } else {
          premiumUntil = new Date(
            currentExpiry.getTime() + 30 * 24 * 60 * 60 * 1000,
          );
          isPremium = true;
        }

        await User.findByIdAndUpdate(authReq.user.id, {
          isPremium: isPremium,
          subscriptionPlan: subscriptionPlan,
          premiumUntil: premiumUntil,
        });

        await Transaction.create({
          userId: authReq.user.id,
          collegeId: authReq.user.collegeId,
          orderId: razorpay_order_id,
          paymentId: razorpay_payment_id,
          amount: Number(order.amount) / 100,
          currency: order.currency,
          plan: plan,
          premiumUntil: premiumUntil,
          status: "captured",
          paymentMethod: paymentMethod,
        });
      }

      res
        .status(200)
        .json({ message: "Payment verified successfully", success: true });
    } else {
      res.status(400).json({ message: "Invalid signature", success: false });
    }
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const getTransactions = async (req: Request, res: Response) => {
  try {
    const authReq = req as any;
    const { role, collegeId: userCollegeId } = authReq.user;
    const { plan, startDate, endDate, collegeId, page, limit } = req.query;

    let query: any = {};
    if (role === "collegeAdmin") {
      query.collegeId = userCollegeId;
    } else if (role === "superAdmin") {
      if (collegeId) query.collegeId = collegeId;
    } else {
      query.userId = authReq.user.id;
    }

    if (plan) query.plan = plan;

    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate as string);
      if (endDate) query.createdAt.$lte = new Date(endDate as string);
    }

    if (page && limit) {
      const pageNum = parseInt(page as string, 10);
      const limitNum = parseInt(limit as string, 10);
      const totalCount = await Transaction.countDocuments(query);
      const transactions = await Transaction.find(query)
        .populate("userId", "fullName email")
        .sort({ createdAt: -1 })
        .skip((pageNum - 1) * limitNum)
        .limit(limitNum);
      res.status(200).json({ transactions, totalCount, totalPages: Math.ceil(totalCount / limitNum) });
    } else {
      const transactions = await Transaction.find(query)
        .populate("userId", "fullName email")
        .sort({ createdAt: -1 });

      res.status(200).json(transactions);
    }
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const requestRefund = async (req: Request, res: Response) => {
  try {
    const authReq = req as any;
    const { transactionId, reason } = req.body;
    const userId = authReq.user.id;

    const transaction = await Transaction.findOne({ _id: transactionId, userId });
    if (!transaction) return res.status(404).json({ message: "Transaction not found" });

    if (transaction.status === "refund_requested") return res.status(400).json({ message: "Refund already requested" });

    transaction.status = "refund_requested";
    await transaction.save();

    try {
      const admins = await User.find({
        collegeId: transaction.collegeId,
        role: "collegeAdmin",
        fcmToken: { $exists: true, $ne: "" },
      } as any);

      const tokens = admins.map((a) => a.fcmToken!);
      if (tokens.length > 0) {
        await sendNotificationToDevices(
          tokens,
          "New Refund Request",
          `A student has requested a refund for transaction ${transaction.paymentId}.`,
          { type: "refund_request", transactionId: transaction._id.toString() },
        );
      }
    } catch (notifyError) {
      console.error("Error notifying admins about refund:", notifyError);
    }

    res.status(200).json({ message: "Refund request submitted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const getRefundRequests = async (req: Request, res: Response) => {
  try {
    const authReq = req as any;
    const { collegeId } = req.query;
    const { role, collegeId: userCollegeId } = authReq.user;

    const query: any = { status: "refund_requested" };

    if (role === "collegeAdmin") {
      query.collegeId = userCollegeId;
    } else if (role === "superAdmin") {
      if (collegeId) query.collegeId = collegeId;
    } else {
      return res.status(403).json({ message: "Access denied" });
    }

    const requests = await Transaction.find(query)
      .populate("userId", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(requests);
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const resolveRefund = async (req: Request, res: Response) => {
  try {
    const { transactionId, status, adminComment } = req.body;
    if (!["refunded", "refund_denied"].includes(status)) return res.status(400).json({ message: "Invalid status" });

    const transaction = await Transaction.findById(transactionId);
    if (!transaction) return res.status(404).json({ message: "Transaction not found" });

    transaction.status = status;
    await transaction.save();

    res.status(200).json({ message: `Refund ${status.replace("_", " ")} successfully` });
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const getSubscriptionAnalytics = async (req: Request, res: Response) => {
  try {
    const authReq = req as any;
    const { role, collegeId: userCollegeId } = authReq.user;
    const { collegeId } = req.query;

    const match: any = { status: { $in: ["captured", "success"] } };
    if (role === "collegeAdmin") match.collegeId = userCollegeId;
    else if (role === "superAdmin" && collegeId) match.collegeId = collegeId;

    const analytics = await Transaction.aggregate([
      { $match: match },
      {
        $group: {
          _id: {
            plan: "$plan",
            month: { $month: "$createdAt" },
            year: { $year: "$createdAt" },
          },
          count: { $sum: 1 },
          totalRevenue: { $sum: "$amount" },
        },
      },
      { $sort: { "_id.year": -1, "_id.month": -1 } },
    ]);

    res.status(200).json(analytics);
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const getAdvancedAnalytics = async (req: Request, res: Response) => {
  try {
    const authReq = req as any;
    const { collegeId } = req.query;
    const { role, collegeId: adminCollegeId } = authReq.user;

    const query: any = {};
    if (role === "collegeAdmin") query.collegeId = adminCollegeId;
    else if (role === "superAdmin") if (collegeId) query.collegeId = collegeId;

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const churnedUsers = await User.countDocuments({
      ...query,
      isPremium: false,
      premiumUntil: { $lt: thirtyDaysAgo },
    });

    const totalEverPremium = await User.countDocuments({
      ...query,
      premiumUntil: { $exists: true },
    });

    const churnRate = totalEverPremium > 0 ? (churnedUsers / totalEverPremium) * 100 : 0;

    const earlyRenewals = await Transaction.countDocuments({
      ...query,
      status: "captured",
      "notes.discountApplied": { $regex: /5%/ },
    });

    const totalTransactions = await Transaction.countDocuments({
      ...query,
      status: "captured",
    });

    res.status(200).json({
      churnRate: parseFloat(churnRate.toFixed(2)),
      earlyRenewalCount: earlyRenewals,
      totalTransactions,
      earlyRenewalTrend: totalTransactions > 0 ? (earlyRenewals / totalTransactions) * 100 : 0,
    });
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const handleWebhook = async (req: Request, res: Response) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!secret) return res.status(400).json({ message: "Webhook secret not configured" });

  const signature = req.headers["x-razorpay-signature"] as string;
  const body = JSON.stringify(req.body);
  const expectedSignature = crypto.createHmac("sha256", secret).update(body).digest("hex");

  if (signature !== expectedSignature) return res.status(400).json({ message: "Invalid signature" });

  const { event, payload } = req.body;
  try {
    if (event === "payment.captured" || event === "order.paid") {
      const paymentDetail = event === "payment.captured" ? payload.payment.entity : payload.order.entity;
      const orderId = event === "payment.captured" ? paymentDetail.order_id : paymentDetail.id;
      const paymentId = event === "payment.captured" ? paymentDetail.id : payload.payment?.entity?.id;

      if (!orderId) return res.status(200).json({ status: "ok" });

      const razorpay = getRazorpay();
      const order = await razorpay.orders.fetch(orderId);
      const planAlias = order.notes?.plan as string;
      const userId = order.notes?.userId as string;

      if (!planAlias || !userId) return res.status(200).json({ status: "ok" });

      const existingTx = await Transaction.findOne({ orderId, status: "captured" });
      if (existingTx) return res.status(200).json({ status: "ok" });

      const selectedPlan = await Plan.findOne({ alias: planAlias });
      const user = await User.findById(userId);

      if (!user || !selectedPlan) return res.status(200).json({ status: "ok" });

      const currentExpiry = user.premiumUntil && user.premiumUntil > new Date() ? user.premiumUntil : new Date();
      const premiumUntil = new Date(currentExpiry.getTime() + selectedPlan.durationDays * 24 * 60 * 60 * 1000);

      await User.findByIdAndUpdate(userId, { isPremium: true, subscriptionPlan: planAlias, premiumUntil });
      await Transaction.create({
        userId,
        collegeId: user.collegeId,
        orderId,
        paymentId: paymentId || "unknown",
        amount: Number(order.amount) / 100,
        currency: order.currency,
        plan: planAlias,
        premiumUntil,
        status: "captured",
        paymentMethod: paymentDetail.method || "unknown",
      });
    }
    res.status(200).json({ status: "ok" });
  } catch (error) {
    res.status(500).json({ message: "Internal server error" });
  }
};
