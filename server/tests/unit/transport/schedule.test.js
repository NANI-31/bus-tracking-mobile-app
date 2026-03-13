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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const Schedule_model_1 = __importDefault(require("@/models/Schedule.model"));
const schedule_controller_1 = require("@/controllers/transport/schedule.controller");
// Mock dependencies
jest.mock("@/models/Schedule.model");
const mockSchedule = Schedule_model_1.default;
describe("Transport Controller - Schedule", () => {
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
            user: { id: "user123", collegeId: "college123" },
        };
        mockRes = {
            json: jsonMock,
            status: statusMock,
        };
        jest.clearAllMocks();
    });
    describe("createSchedule", () => {
        it("should create a new schedule and return 201", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { busId: "bus123", shift: "Morning", tripType: "Pickup" };
            mockSchedule.findOne.mockResolvedValue(null);
            const savedSchedule = Object.assign({ _id: "sch123" }, mockReq.body);
            const saveMock = jest.fn().mockResolvedValue(savedSchedule);
            mockSchedule.mockImplementation(() => (Object.assign(Object.assign({}, mockReq.body), { save: saveMock })));
            yield (0, schedule_controller_1.createSchedule)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(201);
            expect(jsonMock).toHaveBeenCalledWith(savedSchedule);
        }));
        it("should return 409 if schedule already exists", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { busId: "bus123", shift: "Morning", tripType: "Pickup" };
            mockSchedule.findOne.mockResolvedValue({ _id: "existing" });
            yield (0, schedule_controller_1.createSchedule)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(409);
        }));
    });
    describe("getSchedule", () => {
        it("should return schedule if found", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "sch123";
            mockSchedule.findById.mockResolvedValue({ _id: "sch123" });
            yield (0, schedule_controller_1.getSchedule)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "sch123" }));
        }));
    });
    describe("deleteSchedule", () => {
        it("should delete schedule and return 200", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "sch123";
            mockSchedule.findByIdAndDelete.mockResolvedValue({ _id: "sch123" });
            yield (0, schedule_controller_1.deleteSchedule)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith({ message: "Schedule deleted successfully" });
        }));
    });
});
