import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { login } from "@/controllers/auth/login";
import User from "@/models/User.model";

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

const mockUser = User as jest.Mocked<typeof User>;
const mockBcrypt = bcrypt as jest.Mocked<typeof bcrypt>;
const mockJwt = jwt as jest.Mocked<typeof jwt>;

describe("Auth Controller - Login", () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      body: {},
      ip: "127.0.0.1",
      headers: { "user-agent": "test" },
      socket: { remoteAddress: "127.0.0.1" } as any,
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };
    jest.clearAllMocks();
    process.env.JWT_SECRET = "test-secret";
    process.env.REFRESH_TOKEN_SECRET = "test-refresh-secret";
  });

  it("should return 400 if email/password is missing", async () => {
    mockReq.body = { email: "", password: "" };
    (mockUser.findOne as jest.Mock).mockResolvedValue(null);

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
  });

  it("should return 400 if user does not exist", async () => {
    mockReq.body = { email: "notfound@test.com", password: "password123" };
    (mockUser.findOne as jest.Mock).mockResolvedValue(null);

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
  });

  it("should return 400 if password is incorrect", async () => {
    mockReq.body = { email: "user@test.com", password: "wrongpassword" };
    const saveMock = jest.fn().mockResolvedValue(undefined);
    (mockUser.findOne as jest.Mock).mockResolvedValue({
      _id: "user123",
      email: "user@test.com",
      password: "hashedpassword",
      role: "student",
      fullName: "Test User",
      emailVerified: true,
      loginAttempts: 0,
      save: saveMock,
    });
    (mockBcrypt.compare as jest.Mock).mockResolvedValue(false);

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
    expect(saveMock).toHaveBeenCalled();
  });

  it("should return 400 if email is not verified", async () => {
    mockReq.body = { email: "user@test.com", password: "password123" };
    (mockUser.findOne as jest.Mock).mockResolvedValue({
      _id: "user123",
      email: "user@test.com",
      password: "hashedpassword",
      role: "student",
      fullName: "Test User",
      emailVerified: false,
    });
    (mockBcrypt.compare as jest.Mock).mockResolvedValue(true);

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({
      message: "Email not verified. Please verify your email.",
      requiresVerification: true,
    });
  });

  it("should return token and user data on successful login", async () => {
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
    (mockUser.findOne as jest.Mock).mockResolvedValue(mockUserData);
    (mockBcrypt.compare as jest.Mock).mockResolvedValue(true);
    (mockJwt.sign as jest.Mock).mockReturnValue("mock-jwt-token");

    await login(mockReq as Request, mockRes as Response);

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
  });

  it("should allow login with phone number instead of email", async () => {
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
    (mockUser.findOne as jest.Mock).mockResolvedValue(mockUserData);
    (mockBcrypt.compare as jest.Mock).mockResolvedValue(true);
    (mockJwt.sign as jest.Mock).mockReturnValue("mock-jwt-token");

    await login(mockReq as Request, mockRes as Response);

    expect(mockUser.findOne).toHaveBeenCalledWith({
      $or: [{ email: "+911234567890" }, { phoneNumber: "+911234567890" }],
    });
    expect(jsonMock).toHaveBeenCalledWith(
      expect.objectContaining({ success: true }),
    );
  });

  it("should return 500 on server error", async () => {
    mockReq.body = { email: "user@test.com", password: "password123" };
    (mockUser.findOne as jest.Mock).mockRejectedValue(new Error("DB Error"));

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(500);
    expect(jsonMock).toHaveBeenCalledWith({
      message: "Server error during login",
    });
  });
});
