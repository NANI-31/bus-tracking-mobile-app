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
const College_model_1 = __importDefault(require("@/models/College.model"));
const college_controller_1 = require("@/controllers/core/college.controller");
// Mock dependencies
jest.mock("@/models/College.model");
jest.mock("@/models/Bus.model");
jest.mock("@/services/collegeService", () => ({
    getCollegeService: jest.fn(() => ({
        addBusNumber: jest.fn().mockResolvedValue(["B1", "B2"]),
        removeBusNumber: jest.fn().mockResolvedValue(["B1"]),
        renameBusNumber: jest.fn().mockResolvedValue(["B1", "B3"]),
    })),
}));
const mockCollege = College_model_1.default;
describe("Core Controller - College", () => {
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
            user: { id: "user123", role: "superAdmin" },
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
    describe("createCollege", () => {
        it("should create a new college and return 201", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { name: "Test College", address: "Localhost" };
            const savedCollege = { _id: "college123", name: "Test College" };
            const saveMock = jest.fn().mockResolvedValue(savedCollege);
            mockCollege.mockImplementation(() => (Object.assign(Object.assign({}, mockReq.body), { save: saveMock })));
            yield (0, college_controller_1.createCollege)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(201);
            expect(jsonMock).toHaveBeenCalledWith(savedCollege);
        }));
    });
    describe("getCollege", () => {
        it("should return college if found", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "college123";
            mockCollege.findById.mockResolvedValue({ _id: "college123", name: "Test College" });
            yield (0, college_controller_1.getCollege)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "college123" }));
        }));
        it("should return 404 if college not found", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "nonexistent";
            mockCollege.findById.mockResolvedValue(null);
            yield (0, college_controller_1.getCollege)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(404);
        }));
    });
    describe("getAllColleges", () => {
        it("should return all colleges", () => __awaiter(void 0, void 0, void 0, function* () {
            mockCollege.find.mockResolvedValue([{ name: "C1" }, { name: "C2" }]);
            yield (0, college_controller_1.getAllColleges)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith([{ name: "C1" }, { name: "C2" }]);
        }));
    });
    describe("addBusNumber", () => {
        it("should add a bus number to a college", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { collegeId: "college123", busNumber: "B2" };
            yield (0, college_controller_1.addBusNumber)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(["B1", "B2"]);
        }));
    });
});
