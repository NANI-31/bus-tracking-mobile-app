import { Request, Response } from "express";
import Schedule from "@/models/Schedule.model";
import { createSchedule, getSchedule, getSchedulesByRoute, deleteSchedule } from "@/controllers/transport/schedule.controller";

// Mock dependencies
jest.mock("@/models/Schedule.model");

const mockSchedule = Schedule as jest.Mocked<typeof Schedule>;

describe("Transport Controller - Schedule", () => {
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
      user: { id: "user123", collegeId: "college123" },
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };
    jest.clearAllMocks();
  });

  describe("createSchedule", () => {
    it("should create a new schedule and return 201", async () => {
      mockReq.body = { busId: "bus123", shift: "Morning", tripType: "Pickup" };
      mockSchedule.findOne.mockResolvedValue(null);
      
      const savedSchedule = { _id: "sch123", ...mockReq.body };
      const saveMock = jest.fn().mockResolvedValue(savedSchedule);
      (mockSchedule as any).mockImplementation(() => ({
        ...mockReq.body,
        save: saveMock,
      }));

      await createSchedule(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(jsonMock).toHaveBeenCalledWith(savedSchedule);
    });

    it("should return 409 if schedule already exists", async () => {
      mockReq.body = { busId: "bus123", shift: "Morning", tripType: "Pickup" };
      mockSchedule.findOne.mockResolvedValue({ _id: "existing" } as any);

      await createSchedule(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(409);
    });
  });

  describe("getSchedule", () => {
    it("should return schedule if found", async () => {
      mockReq.params.id = "sch123";
      mockSchedule.findById.mockResolvedValue({ _id: "sch123" } as any);

      await getSchedule(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "sch123" }));
    });
  });

  describe("deleteSchedule", () => {
    it("should delete schedule and return 200", async () => {
      mockReq.params.id = "sch123";
      mockSchedule.findByIdAndDelete.mockResolvedValue({ _id: "sch123" } as any);

      await deleteSchedule(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({ message: "Schedule deleted successfully" });
    });
  });
});
