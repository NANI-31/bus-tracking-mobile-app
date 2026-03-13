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
const History_model_1 = require("@/models/History.model");
const history_controller_1 = require("@/controllers/transport/history.controller");
// Mock dependencies
jest.mock("@/models/History.model");
const mockHistory = History_model_1.History;
describe("Transport Controller - History", () => {
    let mockReq;
    let mockRes;
    let jsonMock;
    let statusMock;
    beforeEach(() => {
        jsonMock = jest.fn();
        statusMock = jest.fn().mockReturnValue({ json: jsonMock });
        mockReq = {
            query: {},
            params: {},
            user: { id: "user123", collegeId: "college123" },
        };
        mockRes = {
            json: jsonMock,
            status: statusMock,
        };
        jest.clearAllMocks();
    });
    describe("getHistory", () => {
        it("should return paginated history if collegeId is present", () => __awaiter(void 0, void 0, void 0, function* () {
            const mockResult = {
                populate: jest.fn().mockReturnThis(),
                sort: jest.fn().mockReturnThis(),
                skip: jest.fn().mockReturnThis(),
                limit: jest.fn().mockResolvedValue([{ description: "Test Event" }]),
            };
            mockHistory.find.mockReturnValue(mockResult);
            mockHistory.countDocuments.mockResolvedValue(1);
            yield (0, history_controller_1.getHistory)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({
                data: [{ description: "Test Event" }],
                pagination: expect.objectContaining({ total: 1 }),
            }));
        }));
        it("should return 400 if collegeId is missing", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.user = {};
            yield (0, history_controller_1.getHistory)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(400);
        }));
    });
    describe("getDriverHistory", () => {
        it("should return history for a specific driver", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "driver123";
            const mockResult = {
                populate: jest.fn().mockReturnThis(),
                sort: jest.fn().mockReturnThis(),
                skip: jest.fn().mockReturnThis(),
                limit: jest.fn().mockResolvedValue([{ eventType: "TRIP_START" }]),
            };
            mockHistory.find.mockReturnValue(mockResult);
            mockHistory.countDocuments.mockResolvedValue(1);
            yield (0, history_controller_1.getDriverHistory)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                data: [{ eventType: "TRIP_START" }],
            }));
        }));
    });
});
