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
const Notification_model_1 = __importDefault(require("@/models/Notification.model"));
const User_model_1 = __importDefault(require("@/models/User.model"));
const notification_controller_1 = require("@/controllers/features/notification.controller");
const firebase = __importStar(require("@/utils/firebase"));
// Mock dependencies
jest.mock("@/models/Notification.model");
jest.mock("@/models/User.model");
jest.mock("@/services/s3.service", () => ({
    s3Service: {
        generatePresignedUrl: jest.fn().mockResolvedValue("https://presigned-url.com"),
        deleteFile: jest.fn().mockResolvedValue(true),
    },
}));
jest.mock("@/utils/firebase", () => ({
    sendNotificationToDevice: jest.fn().mockResolvedValue(undefined),
    sendDataOnlyNotificationToDevices: jest.fn().mockResolvedValue(undefined),
    sendDataOnlyNotificationToTopic: jest.fn().mockResolvedValue(undefined),
}));
jest.mock("@/utils/logger", () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
}));
describe("Feature Controller - Notification", () => {
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
    describe("sendNotification", () => {
        it("should create a notification and send FCM", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.body = { receiverId: "receiver123", title: "Test", message: "Hello" };
            const savedNotif = Object.assign({ _id: "notif123" }, mockReq.body);
            Notification_model_1.default.mockImplementation(() => (Object.assign(Object.assign({}, mockReq.body), { save: jest.fn().mockResolvedValue(savedNotif) })));
            User_model_1.default.findById.mockResolvedValue({ fcmToken: "token123" });
            yield (0, notification_controller_1.sendNotification)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(201);
            expect(firebase.sendNotificationToDevice).toHaveBeenCalled();
        }));
    });
    describe("getUserNotifications", () => {
        it("should return notifications with presigned URLs for voice messages", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.userId = "user123";
            const rawNotifs = [
                {
                    toObject: () => ({
                        _id: "notif1",
                        type: "VOICE_NOTIFICATION",
                        data: { voiceKey: "path/to/audio.mp3" }
                    })
                }
            ];
            Notification_model_1.default.find.mockReturnValue({
                sort: jest.fn().mockResolvedValue(rawNotifs),
            });
            yield (0, notification_controller_1.getUserNotifications)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(jsonMock).toHaveBeenCalledWith(expect.arrayContaining([expect.objectContaining({ audioUrl: "https://presigned-url.com" })]));
        }));
    });
    describe("markNotificationAsRead", () => {
        it("should update notification and emit sync event", () => __awaiter(void 0, void 0, void 0, function* () {
            mockReq.params.id = "notif123";
            const updatedNotif = { _id: "notif123", isRead: true, receiverId: "user123" };
            Notification_model_1.default.findByIdAndUpdate.mockResolvedValue(updatedNotif);
            User_model_1.default.findById.mockResolvedValue({ fcmToken: "token123" });
            yield (0, notification_controller_1.markNotificationAsRead)(mockReq, mockRes);
            expect(statusMock).toHaveBeenCalledWith(200);
            expect(firebase.sendDataOnlyNotificationToDevices).toHaveBeenCalledWith(["token123"], expect.objectContaining({ action: "dismiss" }));
        }));
    });
});
