import { Request, Response } from "express";
import Route from "@/models/Route.model";
import { createRoute, getRoute, getRoutesByCollege, updateRoute, deleteRoute } from "@/controllers/transport/route.controller";
import { AuditService } from "@/services/AuditService";
import * as cache from "@/utils/cache";

// Mock dependencies
jest.mock("@/models/Route.model");
jest.mock("@/services/AuditService", () => ({
  AuditService: {
    log: jest.fn().mockResolvedValue(undefined),
  },
}));
jest.mock("@/utils/cache", () => ({
  getCache: jest.fn(),
  setCache: jest.fn(),
  delCache: jest.fn(),
}));
jest.mock("@/utils/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
}));

const mockRoute = Route as jest.Mocked<typeof Route>;

describe("Transport Controller - Route", () => {
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

  describe("createRoute", () => {
    it("should create a new route and return 201", async () => {
      mockReq.body = { routeName: "Route A", stops: [] };
      const savedRoute = {
        _id: "route123",
        routeName: "Route A",
        toObject: jest.fn().mockReturnValue({ routeName: "Route A" }),
      };
      
      const saveMock = jest.fn().mockResolvedValue(savedRoute);
      (mockRoute as any).mockImplementation(() => ({
        ...mockReq.body,
        save: saveMock,
      }));

      await createRoute(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(saveMock).toHaveBeenCalled();
      expect(AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "ROUTE_CREATE" }));
    });
  });

  describe("getRoute", () => {
    it("should return a route if found", async () => {
      mockReq.params.id = "route123";
      mockRoute.findById.mockResolvedValue({ _id: "route123", routeName: "Route A" } as any);

      await getRoute(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "route123" }));
    });
  });

  describe("getRoutesByCollege", () => {
    it("should return routes from cache if available", async () => {
      mockReq.params.collegeId = "college123";
      (cache.getCache as jest.Mock).mockResolvedValue([{ routeName: "CachedRoute" }]);

      await getRoutesByCollege(mockReq, mockRes);

      expect(jsonMock).toHaveBeenCalledWith([{ routeName: "CachedRoute" }]);
    });
  });

  describe("updateRoute", () => {
    it("should update route and return 200", async () => {
      mockReq.params.id = "route123";
      mockReq.body = { routeName: "Updated Route" };
      const updatedRoute = {
        _id: "route123",
        routeName: "Updated Route",
        collegeId: "college123",
        toObject: jest.fn().mockReturnValue({}),
      };
      mockRoute.findOneAndUpdate.mockResolvedValue(updatedRoute as any);

      await updateRoute(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "ROUTE_UPDATE" }));
    });
  });

  describe("deleteRoute", () => {
    it("should delete route and return 200", async () => {
      mockReq.params.id = "route123";
      const deletedRoute = {
        _id: "route123",
        routeName: "Route A",
        collegeId: "college123",
        toObject: jest.fn().mockReturnValue({}),
      };
      mockRoute.findOneAndDelete.mockResolvedValue(deletedRoute as any);

      await deleteRoute(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith({ message: "Route deleted successfully" });
    });
  });
});
