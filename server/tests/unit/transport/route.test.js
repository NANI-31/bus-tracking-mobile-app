"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const Route_model_1 = __importDefault(require("@/models/Route.model"));
const route_controller_1 = require("@/controllers/transport/route.controller");
const AuditService_1 = require("@/services/AuditService");
const cache = __importStar(require("@/utils/cache"));
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
const mockRoute = Route_model_1.default;
describe("Transport Controller - Route", () => {
    let mockReq;
    let mockRes;
    let jsonMock;
    let statusMock;
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
        it("should create a new route and return 201", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { routeName: "Route A", stops: [] };
            const savedRoute = {
                _id: "route123",
                routeName: "Route A",
                toObject: jest.fn().mockReturnValue({ routeName: "Route A" }),
            };
            const saveMock = jest.fn().mockResolvedValue(savedRoute);
            mockRoute.mockImplementation(() => (Object.assign(Object.assign({}, mockReq.body), { save: saveMock })));
            yield (0, route_controller_1.createRoute)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(201);
            expect(saveMock).toHaveBeenCalled();
            expect(AuditService_1.AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "ROUTE_CREATE" }));
        }));
    });
    describe("getRoute", () => {
        it("should return a route if found", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "route123";
            mockRoute.findById.mockResolvedValue({ _id: "route123", routeName: "Route A" });
            yield (0, route_controller_1.getRoute)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "route123" }));
        }));
    });
    describe("getRoutesByCollege", () => {
        it("should return routes from cache if available", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.collegeId = "college123";
            cache.getCache.mockResolvedValue([{ routeName: "CachedRoute" }]);
            yield (0, route_controller_1.getRoutesByCollege)(mockReq, mockRes);
            expect(jsonMock).toHaveBeenCalledWith([{ routeName: "CachedRoute" }]);
        }));
    });
    describe("updateRoute", () => {
        it("should update route and return 200", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "route123";
            mockReq.body = { routeName: "Updated Route" };
            const updatedRoute = {
                _id: "route123",
                routeName: "Updated Route",
                collegeId: "college123",
                toObject: jest.fn().mockReturnValue({}),
            };
            mockRoute.findOneAndUpdate.mockResolvedValue(updatedRoute);
            yield (0, route_controller_1.updateRoute)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(AuditService_1.AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "ROUTE_UPDATE" }));
        }));
    });
    describe("deleteRoute", () => {
        it("should delete route and return 200", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "route123";
            const deletedRoute = {
                _id: "route123",
                routeName: "Route A",
                collegeId: "college123",
                toObject: jest.fn().mockReturnValue({}),
            };
            mockRoute.findOneAndDelete.mockResolvedValue(deletedRoute);
            yield (0, route_controller_1.deleteRoute)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith({ message: "Route deleted successfully" });
        }));
    });
});
