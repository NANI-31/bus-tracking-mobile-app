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
const BusAssignmentLog_model_1 = require("@/models/BusAssignmentLog.model");
const assignment_controller_1 = require("@/controllers/transport/assignment.controller");
// Mock dependencies
jest.mock("@/models/BusAssignmentLog.model");
const mockLog = BusAssignmentLog_model_1.BusAssignmentLog;
describe("Transport Controller - Assignment", () => {
    let mockReq;
    let mockRes;
    let jsonMock;
    let statusMock;
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
        it("should return logs for a bus", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.busId = "bus123";
            const mockResult = {
                populate: jest.fn().mockReturnThis(),
                sort: jest.fn().mockResolvedValue([{ busId: "bus123" }]),
            };
            mockLog.find.mockReturnValue(mockResult);
            yield (0, assignment_controller_1.getAssignmentLogsByBus)(mockReq, mockRes);
            expect(jsonMock).toHaveBeenCalledWith([{ busId: "bus123" }]);
        }));
    });
    describe("getAssignmentLogsByDriver", () => {
        it("should return logs for a driver", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.driverId = "driver123";
            const mockResult = {
                populate: jest.fn().mockReturnThis(),
                sort: jest.fn().mockResolvedValue([{ driverId: "driver123" }]),
            };
            mockLog.find.mockReturnValue(mockResult);
            yield (0, assignment_controller_1.getAssignmentLogsByDriver)(mockReq, mockRes);
            expect(jsonMock).toHaveBeenCalledWith([{ driverId: "driver123" }]);
        }));
    });
});
