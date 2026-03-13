"use strict";
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
const sos_controller_1 = require("@/controllers/features/sos.controller");
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
        it("should trigger an SOS alert and return 201", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { location: { lat: 10, lng: 20 }, busId: "bus123" };
            yield (0, sos_controller_1.sendSOS)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(201);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
        }));
        it("should return 400 if location is missing", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = {};
            yield (0, sos_controller_1.sendSOS)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(400);
        }));
    });
    describe("resolveSos", () => {
        it("should resolve an SOS alert and return 200", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "sos123";
            mockReq.body = { resolutionNotes: "Issue fixed" };
            yield (0, sos_controller_1.resolveSos)(mockReq, mockRes);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
        }));
    });
    describe("getActiveSos", () => {
        it("should return active SOS alerts for a college", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.collegeId = "college123";
            yield (0, sos_controller_1.getActiveSos)(mockReq, mockRes);
            expect(jsonMock).toHaveBeenCalledWith(expect.arrayContaining([expect.objectContaining({ status: "active" })]));
        }));
    });
});
