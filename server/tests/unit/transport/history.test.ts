import { Request, Response } from "express";
import { History } from "@/models/History.model";
import { getHistory, getDriverHistory } from "@/controllers/transport/history.controller";

// Mock dependencies
jest.mock("@/models/History.model");

const mockHistory = History as jest.Mocked<typeof History>;

describe("Transport Controller - History", () => {
  let mockReq: any;
  let mockRes: any;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      query: {},
      params: {},
      user: { id: "user123", collegeId: "college123" },
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };
    jest.clearAllMocks();
  });

  describe("getHistory", () => {
    it("should return paginated history if collegeId is present", async () => {
      const mockResult = {
        populate: jest.fn().mockReturnThis(),
        sort: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue([{ description: "Test Event" }]),
      };
      (mockHistory.find as jest.Mock).mockReturnValue(mockResult);
      mockHistory.countDocuments.mockResolvedValue(1);

      await getHistory(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({
        data: [{ description: "Test Event" }],
        pagination: expect.objectContaining({ total: 1 }),
      }));
    });

    it("should return 400 if collegeId is missing", async () => {
      mockReq.user = {};
      await getHistory(mockReq, mockRes);
      expect(statusMock).toHaveBeenCalledWith(400);
    });
  });

  describe("getDriverHistory", () => {
    it("should return history for a specific driver", async () => {
      mockReq.params.id = "driver123";
      const mockResult = {
        populate: jest.fn().mockReturnThis(),
        sort: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue([{ eventType: "TRIP_START" }]),
      };
      (mockHistory.find as jest.Mock).mockReturnValue(mockResult);
      mockHistory.countDocuments.mockResolvedValue(1);

      await getDriverHistory(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        data: [{ eventType: "TRIP_START" }],
      }));
    });
  });
});
