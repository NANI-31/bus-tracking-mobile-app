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
const User_model_1 = __importDefault(require("@/models/User.model"));
const user_controller_1 = require("@/controllers/core/user.controller");
const AuditService_1 = require("@/services/AuditService");
const emailService = __importStar(require("@/utils/emailService"));
// Mock dependencies
jest.mock("@/models/User.model");
jest.mock("@/models/College.model");
jest.mock("@/services/AuditService", () => ({
    AuditService: {
        log: jest.fn().mockResolvedValue(undefined),
    },
}));
jest.mock("@/utils/emailService", () => ({
    sendEmail: jest.fn().mockResolvedValue(undefined),
}));
jest.mock("@/utils/logger", () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
}));
const mockUser = User_model_1.default;
describe("Core Controller - User", () => {
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
            user: { id: "admin123", role: "collegeAdmin", collegeId: "college123" },
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
    describe("createUser", () => {
        it("should create a new user and return 201", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { email: "test@test.com", fullName: "Test User" };
            const savedUser = Object.assign(Object.assign({ _id: "user123" }, mockReq.body), { toObject: jest.fn().mockReturnValue({}) });
            const saveMock = jest.fn().mockResolvedValue(savedUser);
            mockUser.mockImplementation(() => (Object.assign(Object.assign({}, mockReq.body), { save: saveMock })));
            yield (0, user_controller_1.createUser)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(201);
            expect(jsonMock).toHaveBeenCalledWith(savedUser);
        }));
    });
    describe("getUser", () => {
        it("should return user if found", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "user123";
            mockUser.findById.mockResolvedValue({ _id: "user123", email: "test@test.com" });
            yield (0, user_controller_1.getUser)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ _id: "user123" }));
        }));
    });
    describe("getAllUsers", () => {
        it("should return users for the same college (multi-tenancy)", () => __awaiter(void 0, void 0, void 0, function* () {
            mockUser.find.mockResolvedValue([{ email: "u1@test.com" }]);
            yield (0, user_controller_1.getAllUsers)(mockReq, mockRes);
            expect(mockUser.find).toHaveBeenCalledWith({ collegeId: "college123" });
            expect(statusMock).toHaveBeenCalledWith(200);
        }));
    });
    describe("updateUser", () => {
        it("should update user and handle email change verification", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "user123";
            mockReq.body = { email: "new@test.com", fullName: "Updated Name" };
            const existingUser = {
                _id: "user123",
                email: "old@test.com",
                fullName: "Old Name",
                save: jest.fn().mockResolvedValue(true),
                collegeId: "college123",
            };
            mockUser.findById.mockResolvedValue(existingUser);
            mockUser.findOne.mockResolvedValue(null); // No existing user with new email
            yield (0, user_controller_1.updateUser)(mockReq, mockRes);
            expect(emailService.sendEmail).toHaveBeenCalled();
            expect(existingUser.save).toHaveBeenCalled();
            expect(jsonMock).toHaveBeenCalledWith(expect.objectContaining({ verificationRequired: true }));
        }));
    });
    describe("deleteUser", () => {
        it("should delete user and log audit", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "user123";
            const userToDelete = {
                _id: "user123",
                fullName: "Delete Me",
                collegeId: "college123",
                toObject: jest.fn().mockReturnValue({}),
            };
            mockUser.findById.mockResolvedValue(userToDelete);
            yield (0, user_controller_1.deleteUser)(mockReq, mockRes);
            expect(mockUser.findByIdAndDelete).toHaveBeenCalledWith("user123");
            expect(AuditService_1.AuditService.log).toHaveBeenCalledWith(expect.objectContaining({ action: "USER_DELETE" }));
        }));
        it("should prevent cross-college deletion", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "user123";
            const userToDelete = {
                _id: "user123",
                collegeId: "otherCollege",
            };
            mockUser.findById.mockResolvedValue(userToDelete);
            yield (0, user_controller_1.deleteUser)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(403);
        }));
    });
});
