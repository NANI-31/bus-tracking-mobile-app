import { Request, Response } from "express";
import User from "@/models/User.model";
import { createUser, getUser, getAllUsers, updateUser, deleteUser } from "@/controllers/core/user.controller";
import { AuditService } from "@/services/AuditService";
import * as emailService from "@/utils/emailService";

// Mock dependencies
jest.mock("@/models/User.model");
jest.mock("@/models/College.model");
jest.mock("@/services/AuditService", () => ({
  AuditService: {
    log: jest.fn().mockResolvedValue(undefined),
  },
}));
jest.mock("@/utils/emailService", () => ({
  sendEmail: jest.fn().mockResolvedValue(undefined),
}));
jest.mock("@/utils/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
}));

const mockUser = User as jest.Mocked<typeof User>;

describe("Core Controller - User", () => {
  let mockReq: any;
  let mockRes: any;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      body: {},
      params: {},
      query: {},
      user: { id: "admin123", role: "collegeAdmin", collegeId: "college123" },
      app: {
        get: jest.fn().mockReturnValue({
          to: jest.fn().mockReturnValue({ emit: jest.fn() }),
        }),
      },
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };
    jest.clearAllMocks();
  });

  describe("createUser", () => {
    it("should create a new user and return 201", async () => {
      mockReq.body = { email: "test@test.com", fullName: "Test User" };
      const savedUser = { _id: "user123", ...mockReq.body, toObject: jest.fn().mockReturnValue({}) };
      const saveMock = jest.fn().mockResolvedValue(savedUser);
      (mockUser as any).mockImplementation(() => ({
        ...mockReq.body,
        save: saveMock,
      }));

      await createUser(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(jsonMock).toHaveBeenCalledWith(savedUser);
    });
  });

  describe("getUser", () => {
    it("should return user if found", async () => {
      mockReq.params.id = "user123";
      mockUser.findById.mockResolvedValue({ _id: "user123", email: "test@test.com" } as any);

      await getUser(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "user123" }));
    });
  });

  describe("getAllUsers", () => {
    it("should return users for the same college (multi-tenancy)", async () => {
      mockUser.find.mockResolvedValue([{ email: "u1@test.com" }] as any);

      await getAllUsers(mockReq, mockRes);

      expect(mockUser.find).toHaveBeenCalledWith({ collegeId: "college123" });
      expect(statusMock).toHaveBeenCalledWith(200);
    });

    it("should return users for the same college when user has admin role (multi-tenancy)", async () => {
      mockReq.user.role = "admin";
      mockUser.find.mockResolvedValue([{ email: "u1@test.com" }] as any);

      await getAllUsers(mockReq, mockRes);

      expect(mockUser.find).toHaveBeenCalledWith({ collegeId: "college123" });
      expect(statusMock).toHaveBeenCalledWith(200);
    });
  });

  describe("updateUser", () => {
    it("should update user and handle email change verification", async () => {
      mockReq.params.id = "user123";
      mockReq.body = { email: "new@test.com", fullName: "Updated Name" };
      
      const existingUser = {
        _id: "user123",
        email: "old@test.com",
        fullName: "Old Name",
        save: jest.fn().mockResolvedValue(true),
        collegeId: "college123",
      };
      mockUser.findById.mockResolvedValue(existingUser as any);
      mockUser.findOne.mockResolvedValue(null); // No existing user with new email

      await updateUser(mockReq, mockRes);

      expect(emailService.sendEmail).toHaveBeenCalled();
      expect(existingUser.save).toHaveBeenCalled();
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ verificationRequired: true }));
    });
  });

  describe("deleteUser", () => {
    it("should delete user and log audit", async () => {
      mockReq.params.id = "user123";
      const userToDelete = {
        _id: "user123",
        fullName: "Delete Me",
        collegeId: "college123",
        toObject: jest.fn().mockReturnValue({}),
      };
      mockUser.findById.mockResolvedValue(userToDelete as any);

      await deleteUser(mockReq, mockRes);

      expect(mockUser.findByIdAndDelete).toHaveBeenCalledWith("user123");
      expect(AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "USER_DELETE" }));
    });

    it("should prevent cross-college deletion", async () => {
      mockReq.params.id = "user123";
      const userToDelete = {
        _id: "user123",
        collegeId: "otherCollege",
      };
      mockUser.findById.mockResolvedValue(userToDelete as any);

      await deleteUser(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(403);
    });

    it("should prevent cross-college deletion when user has admin role", async () => {
      mockReq.user.role = "admin";
      mockReq.params.id = "user123";
      const userToDelete = {
        _id: "user123",
        collegeId: "otherCollege",
      };
      mockUser.findById.mockResolvedValue(userToDelete as any);

      await deleteUser(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(403);
    });
  });
});
