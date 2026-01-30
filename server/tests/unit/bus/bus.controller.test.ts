import { Request, Response } from "express";
import * as BusController from "../../../src/controllers/bus.controller";
import { Bus, BusLocation } from "../../../src/models/Bus";
import { getBusService } from "../../../src/services/busService";

// Mock dependencies
jest.mock("../../../src/models/Bus");
jest.mock("../../../src/services/busService");
jest.mock("../../../src/utils/logger", () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  debug: jest.fn(),
}));

describe("Bus Controller", () => {
  let req: Partial<Request>;
  let res: Partial<Response>;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    req = {
      body: {},
      params: {},
      app: {
        get: jest.fn().mockReturnValue({
          to: jest.fn().mockReturnValue({ emit: jest.fn() }),
        }),
      } as any,
    };
    res = {
      status: statusMock,
      json: jsonMock,
    };
    jest.clearAllMocks();
  });

  describe("createBus", () => {
    it("should create a bus successfully", async () => {
      req.body = { busNumber: "TN01" };
      const saveMock = jest.fn().mockResolvedValue(req.body);
      (Bus as any).mockImplementation(() => ({
        save: saveMock,
      }));

      await BusController.createBus(req as Request, res as Response);

      expect(Bus).toHaveBeenCalledWith(req.body);
      expect(saveMock).toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(201);
      expect(jsonMock).toHaveBeenCalledWith(req.body);
    });

    it("should return 500 on error", async () => {
      (Bus as any).mockImplementation(() => ({
        save: jest.fn().mockRejectedValue(new Error("DB Error")),
      }));

      await BusController.createBus(req as Request, res as Response);

      expect(statusMock).toHaveBeenCalledWith(500);
      expect(jsonMock).toHaveBeenCalledWith({ message: "DB Error" });
    });
  });

  describe("getBus", () => {
    it("should return a bus if found", async () => {
      req.params = { id: "123" };
      const mockBus = { _id: "123", busNumber: "TN01" };
      (Bus.findById as jest.Mock).mockResolvedValue(mockBus);

      await BusController.getBus(req as Request, res as Response);

      expect(Bus.findById).toHaveBeenCalledWith("123");
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(mockBus);
    });

    it("should return 404 if bus not found", async () => {
      req.params = { id: "123" };
      (Bus.findById as jest.Mock).mockResolvedValue(null);

      await BusController.getBus(req as Request, res as Response);

      expect(statusMock).toHaveBeenCalledWith(404);
      expect(jsonMock).toHaveBeenCalledWith({ message: "Bus not found" });
    });
  });

  describe("getAllBuses", () => {
    it("should return all buses", async () => {
      const mockBuses = [
        { _id: "1", busNumber: "A" },
        { _id: "2", busNumber: "B" },
      ];
      (Bus.find as jest.Mock).mockResolvedValue(mockBuses);

      await BusController.getAllBuses(req as Request, res as Response);

      expect(Bus.find).toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(mockBuses);
    });
  });

  describe("updateBus", () => {
    it("should update bus using service", async () => {
      req.params = { id: "123" };
      req.body = { status: "running" };
      (req as any).user = { fullName: "Admin" };

      const mockUpdatedBus = { _id: "123", status: "running" };
      const updateBusMock = jest.fn().mockResolvedValue(mockUpdatedBus);
      (getBusService as jest.Mock).mockReturnValue({
        updateBus: updateBusMock,
      });

      await BusController.updateBus(req as Request, res as Response);

      expect(getBusService).toHaveBeenCalled();
      expect(updateBusMock).toHaveBeenCalledWith("123", req.body, "Admin");
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(mockUpdatedBus);
    });

    it("should handle Bus Not Found from service", async () => {
      req.params = { id: "123" };
      const updateBusMock = jest
        .fn()
        .mockRejectedValue(new Error("Bus not found"));
      (getBusService as jest.Mock).mockReturnValue({
        updateBus: updateBusMock,
      });

      await BusController.updateBus(req as Request, res as Response);

      expect(statusMock).toHaveBeenCalledWith(404);
      expect(jsonMock).toHaveBeenCalledWith({ message: "Bus not found" });
    });
  });

  describe("deleteBus", () => {
    it("should delete bus and broadcast update", async () => {
      req.params = { id: "123" };
      const mockBus = { _id: "123", collegeId: "col1" };
      (Bus.findByIdAndDelete as jest.Mock).mockResolvedValue(mockBus);

      await BusController.deleteBus(req as Request, res as Response);

      expect(Bus.findByIdAndDelete).toHaveBeenCalledWith("123");
      expect(req.app.get).toHaveBeenCalledWith("io");
      // Verify broadcast logic
      // io.to().emit()
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({
        message: "Bus deleted successfully",
      });
    });

    it("should return 404 if bus to delete is not found", async () => {
      req.params = { id: "123" };
      (Bus.findByIdAndDelete as jest.Mock).mockResolvedValue(null);

      await BusController.deleteBus(req as Request, res as Response);

      expect(statusMock).toHaveBeenCalledWith(404);
      expect(jsonMock).toHaveBeenCalledWith({ message: "Bus not found" });
    });
  });

  describe("getCollegeBusLocations", () => {
    it("should return locations for college buses", async () => {
      req.params = { collegeId: "col1" };
      const mockBuses = [{ _id: "b1" }, { _id: "b2" }];
      (Bus.find as jest.Mock).mockResolvedValue(mockBuses);

      const mockAggregatedLocations = [
        { _id: "b1", latestLocation: { lat: 10, lng: 10 } },
      ];
      (BusLocation.aggregate as jest.Mock).mockResolvedValue(
        mockAggregatedLocations,
      );

      await BusController.getCollegeBusLocations(
        req as Request,
        res as Response,
      );

      expect(Bus.find).toHaveBeenCalledWith({
        collegeId: "col1",
        isActive: true,
      });
      expect(BusLocation.aggregate).toHaveBeenCalled();
      expect(statusMock).toHaveBeenCalledWith(200);

      const expectedResponse = [{ lat: 10, lng: 10, busId: "b1" }];
      expect(jsonMock).toHaveBeenCalledWith(expectedResponse);
    });
  });
});
