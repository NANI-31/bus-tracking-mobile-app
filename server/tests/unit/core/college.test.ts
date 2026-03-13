import { Request, Response } from "express";
import College from "@/models/College.model";
import { Bus } from "@/models/Bus.model";
import { createCollege, getCollege, getAllColleges, addBusNumber } from "@/controllers/core/college.controller";

// Mock dependencies
jest.mock("@/models/College.model");
jest.mock("@/models/Bus.model");
jest.mock("@/services/collegeService", () => ({
  getCollegeService: jest.fn(() => ({
    addBusNumber: jest.fn().mockResolvedValue(["B1", "B2"]),
    removeBusNumber: jest.fn().mockResolvedValue(["B1"]),
    renameBusNumber: jest.fn().mockResolvedValue(["B1", "B3"]),
  })),
}));

const mockCollege = College as jest.Mocked<typeof College>;

describe("Core Controller - College", () => {
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
      user: { id: "user123", role: "superAdmin" },
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

  describe("createCollege", () => {
    it("should create a new college and return 201", async () => {
      mockReq.body = { name: "Test College", address: "Localhost" };
      const savedCollege = { _id: "college123", name: "Test College" };
      const saveMock = jest.fn().mockResolvedValue(savedCollege);
      (mockCollege as any).mockImplementation(() => ({
        ...mockReq.body,
        save: saveMock,
      }));

      await createCollege(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(jsonMock).toHaveBeenCalledWith(savedCollege);
    });
  });

  describe("getCollege", () => {
    it("should return college if found", async () => {
      mockReq.params.id = "college123";
      mockCollege.findById.mockResolvedValue({ _id: "college123", name: "Test College" } as any);

      await getCollege(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "college123" }));
    });

    it("should return 404 if college not found", async () => {
      mockReq.params.id = "nonexistent";
      mockCollege.findById.mockResolvedValue(null);

      await getCollege(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(404);
    });
  });

  describe("getAllColleges", () => {
    it("should return all colleges", async () => {
      mockCollege.find.mockResolvedValue([{ name: "C1" }, { name: "C2" }] as any);

      await getAllColleges(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith([{ name: "C1" }, { name: "C2" }]);
    });
  });

  describe("addBusNumber", () => {
    it("should add a bus number to a college", async () => {
      mockReq.body = { collegeId: "college123", busNumber: "B2" };
      
      await addBusNumber(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(["B1", "B2"]);
    });
  });
});
