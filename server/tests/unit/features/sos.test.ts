import { Response } from "express";
import { SosStatus } from "@/models/Sos.model";
import { sendSOS, resolveSos, getActiveSos } from "@/controllers/features/sos.controller";

// Mock dependencies
jest.mock("@/services/sosService", () => ({
  getSosService: jest.fn(() => ({
    triggerSos: jest.fn().mockResolvedValue({ _id: "sos123", status: "active" }),
    resolveSos: jest.fn().mockResolvedValue({ _id: "sos123", status: "resolved" }),
    getActiveSos: jest.fn().mockResolvedValue([{ _id: "sos123", status: "active" }]),
  })),
}));

jest.mock("@/utils/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
}));

describe("Feature Controller - SOS", () => {
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
      path: "/api/sos/active",
      user: { id: "user123", role: "student", collegeId: "college123" },
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

  describe("sendSOS", () => {
    it("should trigger an SOS alert and return 201", async () => {
      mockReq.body = { location: { lat: 10, lng: 20 }, busId: "bus123" };
      
      await sendSOS(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
    });

    it("should return 400 if location is missing", async () => {
      mockReq.body = {};
      await sendSOS(mockReq, mockRes);
      expect(statusMock).toHaveBeenCalledWith(400);
    });
  });

  describe("resolveSos", () => {
    it("should resolve an SOS alert and return 200", async () => {
      mockReq.params.id = "sos123";
      mockReq.body = { resolutionNotes: "Issue fixed" };

      await resolveSos(mockReq, mockRes);

      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
    });
  });

  describe("getActiveSos", () => {
    it("should return active SOS alerts for a college", async () => {
      mockReq.params.collegeId = "college123";
      
      await getActiveSos(mockReq, mockRes);

      expect(jsonMock).toHaveBeenCalledWith(expect.arrayContaining([expect.objectContaining({ status: "active" })]));
    });
  });
});
