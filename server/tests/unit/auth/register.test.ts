import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { register } from "@/controllers/auth/register";
import User from "@/models/User.model";
import College from "@/models/College.model";

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

const mockUser = User as jest.Mocked<typeof User>;
const mockBcrypt = bcrypt as jest.Mocked<typeof bcrypt>;
const mockJwt = jwt as jest.Mocked<typeof jwt>;
const mockCollege = College as jest.Mocked<typeof College>;

describe("Auth Controller - Register", () => {
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
    process.env.REFRESH_TOKEN_SECRET = "test_refresh_secret";
  });

  it("should return 400 if email is missing for student role", async () => {
    mockReq.body = {
      password: "password123",
      fullName: "Test User",
      role: "student",
      collegeId: "college123",
    };

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "Email is required" });
  });

  it("should return 400 if user already exists", async () => {
    mockReq.body = {
      email: "existing@test.com",
      password: "password123",
      fullName: "Test User",
      role: "student",
      collegeId: "college123",
    };
    (mockUser.findOne as jest.Mock).mockResolvedValue({
      email: "existing@test.com",
    });

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({ message: "User already exists" });
  });

  it("should return 400 if parent registers without phone number", async () => {
    mockReq.body = {
      email: "parent@test.com",
      password: "password123",
      fullName: "Parent User",
      role: "parent",
    };

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({
      message: "Phone number is required for parents",
    });
  });

  it("should return 400 if parent phone number already exists", async () => {
    mockReq.body = {
      password: "password123",
      fullName: "Parent User",
      role: "parent",
      phoneNumber: "+911234567890",
    };
    (mockUser.findOne as jest.Mock).mockResolvedValue({
      phoneNumber: "+911234567890",
    });

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(400);
    expect(jsonMock).toHaveBeenCalledWith({
      message: "User with this phone number already exists",
    });
  });

  it("should successfully register a new student", async () => {
    mockReq.body = {
      email: "newstudent@test.com",
      password: "password123",
      fullName: "New Student",
      role: "student",
      collegeId: "college123",
      rollNumber: "STU001",
    };
    (mockUser.findOne as jest.Mock).mockResolvedValue(null);
    (mockBcrypt.genSalt as jest.Mock).mockResolvedValue("salt");
    (mockBcrypt.hash as jest.Mock).mockResolvedValue("hashedpassword");
    (mockJwt.sign as jest.Mock).mockReturnValue("mock-jwt-token");

    const saveMock = jest.fn().mockResolvedValue(undefined);
    (mockUser as any).mockImplementation(() => ({
      _id: "mock-uuid-123",
      email: "newstudent@test.com",
      fullName: "New Student",
      role: "student",
      collegeId: "college123",
      approved: false,
      tokenVersion: 0,
      save: saveMock,
    }));

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(201);
    expect(jsonMock).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        token: "mock-jwt-token",
      }),
    );
  });

  it("should auto-approve parent on registration", async () => {
    mockReq.body = {
      password: "password123",
      fullName: "Parent User",
      role: "parent",
      phoneNumber: "+911234567890",
    };
    (mockUser.findOne as jest.Mock).mockResolvedValue(null);
    (mockBcrypt.genSalt as jest.Mock).mockResolvedValue("salt");
    (mockBcrypt.hash as jest.Mock).mockResolvedValue("hashedpassword");
    (mockJwt.sign as jest.Mock).mockReturnValue("mock-jwt-token");

    const saveMock = jest.fn().mockResolvedValue(undefined);
    (mockUser as any).mockImplementation(() => ({
      _id: "mock-uuid-123",
      fullName: "Parent User",
      role: "parent",
      approved: true,
      tokenVersion: 0,
      save: saveMock,
    }));

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(201);
  });

  it("should return 500 on server error", async () => {
    mockReq.body = {
      email: "user@test.com",
      password: "password123",
      fullName: "Test User",
      role: "student",
      collegeId: "college123",
    };
    (mockUser.findOne as jest.Mock).mockRejectedValue(new Error("DB Error"));

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(500);
    expect(jsonMock).toHaveBeenCalledWith({
      message: "Server error during registration",
    });
  });
});
