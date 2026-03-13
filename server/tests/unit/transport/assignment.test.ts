import { Request, Response } from "express";
import { BusAssignmentLog } from "@/models/BusAssignmentLog.model";
import { getAssignmentLogsByBus, getAssignmentLogsByDriver } from "@/controllers/transport/assignment.controller";

// Mock dependencies
jest.mock("@/models/BusAssignmentLog.model");

const mockLog = BusAssignmentLog as jest.Mocked<typeof BusAssignmentLog>;

describe("Transport Controller - Assignment", () => {
  let mockReq: any;
  let mockRes: any;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      params: {},
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };
    jest.clearAllMocks();
  });

  describe("getAssignmentLogsByBus", () => {
    it("should return logs for a bus", async () => {
      mockReq.params.busId = "bus123";
      const mockResult = {
        populate: jest.fn().mockReturnThis(),
        sort: jest.fn().mockResolvedValue([{ busId: "bus123" }]),
      };
      (mockLog.find as jest.Mock).mockReturnValue(mockResult);

      await getAssignmentLogsByBus(mockReq, mockRes);

      expect(jsonMock).toHaveBeenCalledWith([{ busId: "bus123" }]);
    });
  });

  describe("getAssignmentLogsByDriver", () => {
    it("should return logs for a driver", async () => {
      mockReq.params.driverId = "driver123";
      const mockResult = {
        populate: jest.fn().mockReturnThis(),
        sort: jest.fn().mockResolvedValue([{ driverId: "driver123" }]),
      };
      (mockLog.find as jest.Mock).mockReturnValue(mockResult);

      await getAssignmentLogsByDriver(mockReq, mockRes);

      expect(jsonMock).toHaveBeenCalledWith([{ driverId: "driver123" }]);
    });
  });
});
