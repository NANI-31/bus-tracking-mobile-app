"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
process.env.RAZORPAY_KEY_ID = "test_key";
process.env.RAZORPAY_KEY_SECRET = "test_secret";
const User_model_1 = __importDefault(require("@/models/User.model"));
const Transaction_model_1 = __importDefault(require("@/models/Transaction.model"));
const Plan_model_1 = __importDefault(require("@/models/Plan.model"));
const payment_controller_1 = require("@/controllers/features/payment.controller");
const razorpay_1 = __importDefault(require("razorpay"));
// Mock dependencies
jest.mock("razorpay");
jest.mock("@/models/User.model");
jest.mock("@/models/Transaction.model");
jest.mock("@/models/Plan.model");
jest.mock("@/utils/firebase", () => ({
    sendNotificationToDevices: jest.fn().mockResolvedValue(undefined),
}));
const mockRazorpay = razorpay_1.default;
describe("Feature Controller - Payment", () => {
    let mockReq;
    let mockRes;
    let jsonMock;
    let statusMock;
    let mockRazorpayInstance;
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
        razorpay_1.default.mockReturnValue(mockRazorpayInstance);
        jest.clearAllMocks();
    });
    describe("createOrder", () => {
        it("should create a razorpay order and return 200", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { plan: "standard_30" };
            Plan_model_1.default.findOne.mockResolvedValue({ alias: "standard_30", price: 100, isActive: true });
            User_model_1.default.findById.mockResolvedValue({ _id: "user123", isPremium: false });
            yield (0, payment_controller_1.createOrder)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ id: "order123" }));
        }));
        it("should apply early renewal discount if applicable", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { plan: "standard_30" };
            Plan_model_1.default.findOne.mockResolvedValue({ alias: "standard_30", price: 100, isActive: true });
            const premiumUntil = new Date();
            premiumUntil.setDate(premiumUntil.getDate() + 5); // 5 days from now (> 3 days)
            User_model_1.default.findById.mockResolvedValue({ _id: "user123", isPremium: true, premiumUntil });
            yield (0, payment_controller_1.createOrder)(mockReq, mockRes);
            // 100 * 0.95 = 95. Razorpay expects paise, so 9500.
            expect(mockRazorpayInstance.orders.create).toHaveBeenCalledWith(expect.objectContaining({
                amount: 9500
            }));
        }));
    });
    describe("verifyPayment", () => {
        it("should verify payment signature and update user premium status", () => __awaiter(void 0, void 0, void 0, function* () {
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
            jest.spyOn(crypto, "createHmac").mockReturnValue(hmacMock);
            User_model_1.default.findById.mockResolvedValue({ _id: "user123", fullName: "Test User" });
            Plan_model_1.default.findOne.mockResolvedValue({ alias: "standard_30", durationDays: 30 });
            yield (0, payment_controller_1.verifyPayment)(mockReq, mockRes);
            expect(User_model_1.default.findByIdAndUpdate).toHaveBeenCalled();
            expect(Transaction_model_1.default.create).toHaveBeenCalled();
            expect(statusMock).toHaveBeenCalledWith(200);
        }));
    });
    describe("getTransactions", () => {
        it("should return transactions for the user", () => __awaiter(void 0, void 0, void 0, function* () {
            Transaction_model_1.default.find.mockReturnValue({
                populate: jest.fn().mockReturnThis(),
                sort: jest.fn().mockResolvedValue([{ amount: 100 }]),
            });
            yield (0, payment_controller_1.getTransactions)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.arrayContaining([expect.objectContaining({ amount: 100 })]));
        }));
    });
});
