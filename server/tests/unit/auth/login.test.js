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
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const login_1 = require("@/controllers/auth/login");
const User_model_1 = __importDefault(require("@/models/User.model"));
// Mock dependencies
jest.mock("@/models/User.model");
jest.mock("bcryptjs");
jest.mock("jsonwebtoken");
jest.mock("@/utils/logger", () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
}));
jest.mock("@/services/AuditService", () => ({
    AuditService: {
        log: jest.fn().mockResolvedValue(undefined),
    },
}));
const mockUser = User_model_1.default;
const mockBcrypt = bcryptjs_1.default;
const mockJwt = jsonwebtoken_1.default;
describe("Auth Controller - Login", () => {
    let mockReq;
    let mockRes;
    let jsonMock;
    let statusMock;
    beforeEach(() => {
        jsonMock = jest.fn();
        statusMock = jest.fn().mockReturnValue({ json: jsonMock });
        mockReq = {
            body: {},
            ip: "127.0.0.1",
            headers: { "user-agent": "test" },
            socket: { remoteAddress: "127.0.0.1" },
        };
        mockRes = {
            json: jsonMock,
            status: statusMock,
        };
        jest.clearAllMocks();
        process.env.JWT_SECRET = "test-secret";
        process.env.REFRESH_TOKEN_SECRET = "test-refresh-secret";
    });
    it("should return 400 if email/password is missing", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = { email: "", password: "" };
        mockUser.findOne.mockResolvedValue(null);
        yield (0, login_1.login)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
    }));
    it("should return 400 if user does not exist", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = { email: "notfound@test.com", password: "password123" };
        mockUser.findOne.mockResolvedValue(null);
        yield (0, login_1.login)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
    }));
    it("should return 400 if password is incorrect", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = { email: "user@test.com", password: "wrongpassword" };
        const saveMock = jest.fn().mockResolvedValue(undefined);
        mockUser.findOne.mockResolvedValue({
            _id: "user123",
            email: "user@test.com",
            password: "hashedpassword",
            role: "student",
            fullName: "Test User",
            emailVerified: true,
            loginAttempts: 0,
            save: saveMock,
        });
        mockBcrypt.compare.mockResolvedValue(false);
        yield (0, login_1.login)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
        expect(saveMock).toHaveBeenCalled();
    }));
    it("should return 400 if email is not verified", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = { email: "user@test.com", password: "password123" };
        mockUser.findOne.mockResolvedValue({
            _id: "user123",
            email: "user@test.com",
            password: "hashedpassword",
            role: "student",
            fullName: "Test User",
            emailVerified: false,
        });
        mockBcrypt.compare.mockResolvedValue(true);
        yield (0, login_1.login)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({
            message: "Email not verified. Please verify your email.",
            requiresVerification: true,
        });
    }));
    it("should return token and user data on successful login", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = { email: "user@test.com", password: "password123" };
        const saveMock = jest.fn().mockResolvedValue(undefined);
        const mockUserData = {
            _id: "user123",
            email: "user@test.com",
            password: "hashedpassword",
            role: "student",
            fullName: "Test User",
            collegeId: "college123",
            approved: true,
            emailVerified: true,
            tokenVersion: 1,
            loginAttempts: 0,
            save: saveMock,
        };
        mockUser.findOne.mockResolvedValue(mockUserData);
        mockBcrypt.compare.mockResolvedValue(true);
        mockJwt.sign.mockReturnValue("mock-jwt-token");
        yield (0, login_1.login)(mockReq, mockRes);
        expect(jsonMock).toHaveBeenCalledWith({
            success: true,
            token: "mock-jwt-token",
            refreshToken: "mock-jwt-token",
            user: {
                id: "user123",
                email: "user@test.com",
                fullName: "Test User",
                role: "student",
                collegeId: "college123",
                approved: true,
            },
        });
    }));
    it("should allow login with phone number instead of email", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = { email: "+911234567890", password: "password123" };
        const saveMock = jest.fn().mockResolvedValue(undefined);
        const mockUserData = {
            _id: "user123",
            email: "user@test.com",
            phoneNumber: "+911234567890",
            password: "hashedpassword",
            role: "parent",
            fullName: "Parent User",
            collegeId: "college123",
            approved: true,
            emailVerified: true,
            tokenVersion: 1,
            loginAttempts: 0,
            save: saveMock,
        };
        mockUser.findOne.mockResolvedValue(mockUserData);
        mockBcrypt.compare.mockResolvedValue(true);
        mockJwt.sign.mockReturnValue("mock-jwt-token");
        yield (0, login_1.login)(mockReq, mockRes);
        expect(mockUser.findOne).toHaveBeenCalledWith({
            $or: [{ email: "+911234567890" }, { phoneNumber: "+911234567890" }],
        });
        expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
    }));
    it("should return 500 on server error", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = { email: "user@test.com", password: "password123" };
        mockUser.findOne.mockRejectedValue(new Error("DB Error"));
        yield (0, login_1.login)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(500);
        expect(jsonMock).toHaveBeenCalledWith({
            message: "Server error during login",
        });
    }));
});
