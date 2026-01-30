import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { login } from "../../../src/controllers/auth/login";
import User from "../../../src/models/User";

// Mock dependencies
jest.mock("../../../src/models/User");
jest.mock("bcryptjs");
jest.mock("jsonwebtoken");
jest.mock("../../../src/utils/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
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
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };
    jest.clearAllMocks();
    process.env.JWT_SECRET = "test-secret";
  });

  // Test 1: Missing credentials
  it("should return 400 if email/password is missing", async () => {
    mockReq.body = { email: "", password: "" };
    (mockUser.findOne as jest.Mock).mockResolvedValue(null);

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
  });

  // Test 2: User not found
  it("should return 400 if user does not exist", async () => {
    mockReq.body = { email: "notfound@test.com", password: "password123" };
    (mockUser.findOne as jest.Mock).mockResolvedValue(null);

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
  });

  // Test 3: Invalid password
  it("should return 400 if password is incorrect", async () => {
    mockReq.body = { email: "user@test.com", password: "wrongpassword" };
    (mockUser.findOne as jest.Mock).mockResolvedValue({
      _id: "user123",
      email: "user@test.com",
      password: "hashedpassword",
      role: "student",
      fullName: "Test User",
      emailVerified: true,
    });
    (mockBcrypt.compare as jest.Mock).mockResolvedValue(false);

    await login(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "Invalid credentials" });
  });

  // Test 4: Unverified email
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

  // Test 5: Successful login
  it("should return token and user data on successful login", async () => {
    mockReq.body = { email: "user@test.com", password: "password123" };
    const mockUserData = {
      _id: "user123",
      email: "user@test.com",
      password: "hashedpassword",
      role: "student",
      fullName: "Test User",
      collegeId: "college123",
      approved: true,
      emailVerified: true,
    };
    (mockUser.findOne as jest.Mock).mockResolvedValue(mockUserData);
    (mockBcrypt.compare as jest.Mock).mockResolvedValue(true);
    (mockJwt.sign as jest.Mock).mockReturnValue("mock-jwt-token");

    await login(mockReq as Request, mockRes as Response);

    expect(jsonMock).toHaveBeenCalledWith({
      success: true,
      token: "mock-jwt-token",
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

  // Test 6: Login with phone number
  it("should allow login with phone number instead of email", async () => {
    mockReq.body = { email: "+911234567890", password: "password123" };
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

  // Test 7: Server error handling
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
