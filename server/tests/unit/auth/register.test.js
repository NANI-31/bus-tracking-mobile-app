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
const register_1 = require("@/controllers/auth/register");
const User_model_1 = __importDefault(require("@/models/User.model"));
const College_model_1 = __importDefault(require("@/models/College.model"));
// Mock dependencies
jest.mock("@/models/User.model");
jest.mock("@/models/College.model");
jest.mock("bcryptjs");
jest.mock("jsonwebtoken");
jest.mock("crypto", () => ({
    randomUUID: () => "mock-uuid-123",
    randomBytes: () => ({
        toString: () => "MOCKCODE",
    }),
}));
jest.mock("@/utils/logger", () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
}));
const mockUser = User_model_1.default;
const mockBcrypt = bcryptjs_1.default;
const mockJwt = jsonwebtoken_1.default;
const mockCollege = College_model_1.default;
describe("Auth Controller - Register", () => {
    let mockReq;
    let mockRes;
    let jsonMock;
    let statusMock;
    beforeEach(() => {
        jsonMock = jest.fn();
        statusMock = jest.fn().mockReturnValue({ json: jsonMock });
        mockReq = {
            body: {},
        };
        mockRes = {
            json: jsonMock,
            status: statusMock,
        };
        jest.clearAllMocks();
        process.env.JWT_SECRET = "test-secret";
        process.env.REFRESH_TOKEN_SECRET = "test_refresh_secret";
    });
    it("should return 400 if email is missing for student role", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = {
            password: "password123",
            fullName: "Test User",
            role: "student",
            collegeId: "college123",
        };
        yield (0, register_1.register)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({ message: "Email is required" });
    }));
    it("should return 400 if user already exists", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = {
            email: "existing@test.com",
            password: "password123",
            fullName: "Test User",
            role: "student",
            collegeId: "college123",
        };
        mockUser.findOne.mockResolvedValue({
            email: "existing@test.com",
        });
        yield (0, register_1.register)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({ message: "User already exists" });
    }));
    it("should return 400 if parent registers without phone number", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = {
            email: "parent@test.com",
            password: "password123",
            fullName: "Parent User",
            role: "parent",
        };
        yield (0, register_1.register)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({
            message: "Phone number is required for parents",
        });
    }));
    it("should return 400 if parent phone number already exists", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = {
            password: "password123",
            fullName: "Parent User",
            role: "parent",
            phoneNumber: "+911234567890",
        };
        mockUser.findOne.mockResolvedValue({
            phoneNumber: "+911234567890",
        });
        yield (0, register_1.register)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(400);
        expect(jsonMock).toHaveBeenCalledWith({
            message: "User with this phone number already exists",
        });
    }));
    it("should successfully register a new student", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = {
            email: "newstudent@test.com",
            password: "password123",
            fullName: "New Student",
            role: "student",
            collegeId: "college123",
            rollNumber: "STU001",
        };
        mockUser.findOne.mockResolvedValue(null);
        mockBcrypt.genSalt.mockResolvedValue("salt");
        mockBcrypt.hash.mockResolvedValue("hashedpassword");
        mockJwt.sign.mockReturnValue("mock-jwt-token");
        const saveMock = jest.fn().mockResolvedValue(undefined);
        mockUser.mockImplementation(() => ({
            _id: "mock-uuid-123",
            email: "newstudent@test.com",
            fullName: "New Student",
            role: "student",
            collegeId: "college123",
            approved: false,
            tokenVersion: 0,
            save: saveMock,
        }));
        yield (0, register_1.register)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(201);
        expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({
            success: true,
            token: "mock-jwt-token",
        }));
    }));
    it("should auto-approve parent on registration", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = {
            password: "password123",
            fullName: "Parent User",
            role: "parent",
            phoneNumber: "+911234567890",
        };
        mockUser.findOne.mockResolvedValue(null);
        mockBcrypt.genSalt.mockResolvedValue("salt");
        mockBcrypt.hash.mockResolvedValue("hashedpassword");
        mockJwt.sign.mockReturnValue("mock-jwt-token");
        const saveMock = jest.fn().mockResolvedValue(undefined);
        mockUser.mockImplementation(() => ({
            _id: "mock-uuid-123",
            fullName: "Parent User",
            role: "parent",
            approved: true,
            tokenVersion: 0,
            save: saveMock,
        }));
        yield (0, register_1.register)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(201);
    }));
    it("should return 500 on server error", () => __awaiter(void 0, void 0, void 0, function* () {
        mockReq.body = {
            email: "user@test.com",
            password: "password123",
            fullName: "Test User",
            role: "student",
            collegeId: "college123",
        };
        mockUser.findOne.mockRejectedValue(new Error("DB Error"));
        yield (0, register_1.register)(mockReq, mockRes);
        expect(statusMock).toHaveBeenCalledWith(500);
        expect(jsonMock).toHaveBeenCalledWith({
            message: "Server error during registration",
        });
    }));
});
