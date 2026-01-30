import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { register } from "../../src/controllers/auth/register";
import User from "../../src/models/User";

// Mock dependencies
jest.mock("../../../src/models/User");
jest.mock("bcryptjs");
jest.mock("jsonwebtoken");
jest.mock("crypto", () => ({
  randomUUID: () => "mock-uuid-123",
}));
jest.mock("../../../src/utils/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const mockUser = User as jest.Mocked<typeof User>;
const mockBcrypt = bcrypt as jest.Mocked<typeof bcrypt>;
const mockJwt = jwt as jest.Mocked<typeof jwt>;

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
  });

  // Test 1: Missing email for non-parent roles
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

  // Test 2: Duplicate email
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

  // Test 3: Parent registration without phone
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

  // Test 4: Duplicate phone number for parent
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

  // Test 5: Successful student registration
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

  // Test 6: Parent auto-approved
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
      approved: true, // Parents are auto-approved
      save: saveMock,
    }));

    await register(mockReq as Request, mockRes as Response);

    expect(statusMock).toHaveBeenCalledWith(201);
  });

  // Test 7: Server error handling
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
