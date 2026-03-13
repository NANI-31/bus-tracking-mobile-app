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
Object.defineProperty(exports, "__esModule", { value: true });
const Bus_model_1 = require("@/models/Bus.model");
const bus_controller_1 = require("@/controllers/transport/bus.controller");
const AuditService_1 = require("@/services/AuditService");
const cache = __importStar(require("@/utils/cache"));
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
const mockBus = Bus_model_1.Bus;
describe("Transport Controller - Bus", () => {
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
    describe("createBus", () => {
        it("should create a new bus and return 201", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { busNumber: "KA-01-1234", capacity: 50 };
            const savedBus = {
                _id: "bus123",
                busNumber: "KA-01-1234",
                collegeId: "college123",
                toObject: jest.fn().mockReturnValue({ busNumber: "KA-01-1234" }),
            };
            const saveMock = jest.fn().mockResolvedValue(savedBus);
            mockBus.mockImplementation(() => (Object.assign(Object.assign({}, mockReq.body), { collegeId: "college123", save: saveMock })));
            yield (0, bus_controller_1.createBus)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(201);
            expect(saveMock).toHaveBeenCalled();
            expect(AuditService_1.AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "BUS_CREATE" }));
        }));
        it("should return 401 if collegeId is missing", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.user = {};
            yield (0, bus_controller_1.createBus)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(401);
        }));
    });
    describe("getBus", () => {
        it("should return a bus if found", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "bus123";
            mockBus.findById.mockResolvedValue({ _id: "bus123", busNumber: "B1" });
            yield (0, bus_controller_1.getBus)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "bus123" }));
        }));
        it("should return 404 if bus not found", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "nonexistent";
            mockBus.findById.mockResolvedValue(null);
            yield (0, bus_controller_1.getBus)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(404);
        }));
    });
    describe("getAllBuses", () => {
        it("should return buses from cache if available", () => __awaiter(void 0, void 0, void 0, function* () {
            cache.getCache.mockResolvedValue([{ busNumber: "CachedBus" }]);
            yield (0, bus_controller_1.getAllBuses)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith([{ busNumber: "CachedBus" }]);
            expect(mockBus.find).not.toHaveBeenCalled();
        }));
        it("should fetch from DB and set cache if not in cache", () => __awaiter(void 0, void 0, void 0, function* () {
            cache.getCache.mockResolvedValue(null);
            mockBus.find.mockResolvedValue([{ busNumber: "DBBus" }]);
            yield (0, bus_controller_1.getAllBuses)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(mockBus.find).toHaveBeenCalled();
            expect(cache.setCache).toHaveBeenCalled();
        }));
    });
    describe("deleteBus", () => {
        it("should delete bus and return 200", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "bus123";
            const deletedBus = {
                _id: "bus123",
                busNumber: "B1",
                collegeId: "college123",
                toObject: jest.fn().mockReturnValue({}),
            };
            mockBus.findOneAndDelete.mockResolvedValue(deletedBus);
            yield (0, bus_controller_1.deleteBus)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(AuditService_1.AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "BUS_DELETE" }));
        }));
        it("should return 404 if bus not found or no permission", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "bus123";
            mockBus.findOneAndDelete.mockResolvedValue(null);
            yield (0, bus_controller_1.deleteBus)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(404);
        }));
    });
});
