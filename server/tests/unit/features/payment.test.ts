process.env.RAZORPAY_KEY_ID = "test_key";
process.env.RAZORPAY_KEY_SECRET = "test_secret";

import { Request, Response } from "express";
import User from "@/models/User.model";
import Transaction from "@/models/Transaction.model";
import Plan from "@/models/Plan.model";
import { createOrder, verifyPayment, getTransactions } from "@/controllers/features/payment.controller";
import Razorpay from "razorpay";

// Mock dependencies
jest.mock("razorpay");
jest.mock("@/models/User.model");
jest.mock("@/models/Transaction.model");
jest.mock("@/models/Plan.model");
jest.mock("@/utils/firebase", () => ({
  sendNotificationToDevices: jest.fn().mockResolvedValue(undefined),
}));

const mockRazorpay = Razorpay as jest.MockedClass<typeof Razorpay>;

describe("Feature Controller - Payment", () => {
  let mockReq: any;
  let mockRes: any;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;
  let mockRazorpayInstance: any;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      body: {},
      query: {},
      user: { id: "user123", role: "student", collegeId: "college123" },
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };

    mockRazorpayInstance = {
      orders: {
        create: jest.fn().mockResolvedValue({ id: "order123", amount: 10000 }),
        fetch: jest.fn().mockResolvedValue({ id: "order123", amount: 10000, notes: { plan: "standard_30" } }),
      },
      payments: {
        fetch: jest.fn().mockResolvedValue({ id: "pay123", method: "upi" }),
      },
    };
    (Razorpay as unknown as jest.Mock).mockReturnValue(mockRazorpayInstance);

    jest.clearAllMocks();
  });

  describe("createOrder", () => {
    it("should create a razorpay order and return 200", async () => {
      mockReq.body = { plan: "standard_30" };
      (Plan.findOne as jest.Mock).mockResolvedValue({ alias: "standard_30", price: 100, isActive: true });
      (User.findById as jest.Mock).mockResolvedValue({ _id: "user123", isPremium: false });

      await createOrder(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ id: "order123" }));
    });

    it("should apply early renewal discount if applicable", async () => {
      mockReq.body = { plan: "standard_30" };
      (Plan.findOne as jest.Mock).mockResolvedValue({ alias: "standard_30", price: 100, isActive: true });
      const premiumUntil = new Date();
      premiumUntil.setDate(premiumUntil.getDate() + 5); // 5 days from now (> 3 days)
      (User.findById as jest.Mock).mockResolvedValue({ _id: "user123", isPremium: true, premiumUntil });

      await createOrder(mockReq, mockRes);

      // 100 * 0.95 = 95. Razorpay expects paise, so 9500.
      expect(mockRazorpayInstance.orders.create).toHaveBeenCalledWith(expect.objectContaining({
        amount: 9500
      }));
    });
  });

  describe("verifyPayment", () => {
    it("should verify payment signature and update user premium status", async () => {
      const razorpay_signature = "valid_sig";
      mockReq.body = {
        razorpay_order_id: "order123",
        razorpay_payment_id: "pay123",
        razorpay_signature,
      };

      // Mock signature verification
      const crypto = require("crypto");
      const hmacMock = {
        update: jest.fn().mockReturnThis(),
        digest: jest.fn().mockReturnValue(razorpay_signature),
      };
      jest.spyOn(crypto, "createHmac").mockReturnValue(hmacMock as any);

      (User.findById as jest.Mock).mockResolvedValue({ _id: "user123", fullName: "Test User" });
      (Plan.findOne as jest.Mock).mockResolvedValue({ alias: "standard_30", durationDays: 30 });

      await verifyPayment(mockReq, mockRes);

      expect(User.findByIdAndUpdate).toHaveBeenCalled();
      expect(Transaction.create).toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(200);
    });
  });

  describe("getTransactions", () => {
    it("should return transactions for the user", async () => {
      (Transaction.find as jest.Mock).mockReturnValue({
        populate: jest.fn().mockReturnThis(),
        sort: jest.fn().mockResolvedValue([{ amount: 100 }]),
      });

      await getTransactions(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.arrayContaining([expect.objectContaining({ amount: 100 })]));
    });
  });
});
