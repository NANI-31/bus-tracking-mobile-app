import { Request, Response } from "express";
import { Bus, BusLocation } from "@/models/Bus.model";
import { createBus, getBus, getAllBuses, deleteBus } from "@/controllers/transport/bus.controller";
import { AuditService } from "@/services/AuditService";
import * as cache from "@/utils/cache";

// Mock dependencies
jest.mock("@/models/Bus.model");
jest.mock("@/services/AuditService", () => ({
  AuditService: {
    log: jest.fn().mockResolvedValue(undefined),
  },
}));
jest.mock("@/utils/cache", () => ({
  getCache: jest.fn(),
  setCache: jest.fn(),
  delCache: jest.fn(),
  delCachePattern: jest.fn(),
}));
jest.mock("@/utils/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
}));

const mockBus = Bus as jest.Mocked<typeof Bus>;

describe("Transport Controller - Bus", () => {
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
      user: { id: "user123", collegeId: "college123", role: "collegeAdmin" },
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

  describe("createBus", () => {
    it("should create a new bus and return 201", async () => {
      mockReq.body = { busNumber: "KA-01-1234", capacity: 50 };
      const savedBus = {
        _id: "bus123",
        busNumber: "KA-01-1234",
        collegeId: "college123",
        toObject: jest.fn().mockReturnValue({ busNumber: "KA-01-1234" }),
      };
      
      const saveMock = jest.fn().mockResolvedValue(savedBus);
      (mockBus as any).mockImplementation(() => ({
        ...mockReq.body,
        collegeId: "college123",
        save: saveMock,
      }));

      await createBus(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(saveMock).toHaveBeenCalled();
      expect(AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "BUS_CREATE" }));
    });

    it("should return 401 if collegeId is missing", async () => {
      mockReq.user = {};
      await createBus(mockReq, mockRes);
      expect(statusMock).toHaveBeenCalledWith(401);
    });
  });

  describe("getBus", () => {
    it("should return a bus if found", async () => {
      mockReq.params.id = "bus123";
      mockBus.findById.mockResolvedValue({ _id: "bus123", busNumber: "B1" } as any);

      await getBus(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "bus123" }));
    });

    it("should return 404 if bus not found", async () => {
      mockReq.params.id = "nonexistent";
      mockBus.findById.mockResolvedValue(null);

      await getBus(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(404);
    });
  });

  describe("getAllBuses", () => {
    it("should return buses from cache if available", async () => {
      (cache.getCache as jest.Mock).mockResolvedValue([{ busNumber: "CachedBus" }]);

      await getAllBuses(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith([{ busNumber: "CachedBus" }]);
      expect(mockBus.find).not.toHaveBeenCalled();
    });

    it("should fetch from DB and set cache if not in cache", async () => {
      (cache.getCache as jest.Mock).mockResolvedValue(null);
      mockBus.find.mockResolvedValue([{ busNumber: "DBBus" }] as any);

      await getAllBuses(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(mockBus.find).toHaveBeenCalled();
      expect(cache.setCache).toHaveBeenCalled();
    });
  });

  describe("deleteBus", () => {
    it("should delete bus and return 200", async () => {
      mockReq.params.id = "bus123";
      const deletedBus = {
        _id: "bus123",
        busNumber: "B1",
        collegeId: "college123",
        toObject: jest.fn().mockReturnValue({}),
      };
      mockBus.findOneAndDelete.mockResolvedValue(deletedBus as any);

      await deleteBus(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "BUS_DELETE" }));
    });

    it("should return 404 if bus not found or no permission", async () => {
      mockReq.params.id = "bus123";
      mockBus.findOneAndDelete.mockResolvedValue(null);

      await deleteBus(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(404);
    });
  });
});
