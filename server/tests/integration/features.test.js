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
const supertest_1 = __importDefault(require("supertest"));
const mongodb_memory_server_1 = require("mongodb-memory-server");
const mongoose_1 = __importDefault(require("mongoose"));
const app_1 = require("../../src/app");
const User_model_1 = __importDefault(require("../../src/models/User.model"));
const College_model_1 = __importDefault(require("../../src/models/College.model"));
const Notification_model_1 = __importDefault(require("../../src/models/Notification.model"));
let mongoServer;
let app;
let token;
let collegeId;
let userId = "";
beforeAll(() => __awaiter(void 0, void 0, void 0, function* () {
    mongoServer = yield mongodb_memory_server_1.MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    yield mongoose_1.default.connect(uri);
    const instances = yield (0, app_1.createApp)();
    app = instances.app;
    // Create a college
    const college = yield College_model_1.default.create({
        name: "Feature College",
        allowedDomains: ["feature.com"],
        verified: true,
        createdBy: "system",
    });
    collegeId = college._id.toString();
    // Create a user
    const user = yield User_model_1.default.create({
        _id: "user_feature",
        fullName: "Feature User",
        email: "user@feature.com",
        password: "password123",
        role: "student",
        collegeId: collegeId,
        approved: true,
        emailVerified: true,
    });
    userId = user._id.toString();
    // Login
    const loginRes = yield (0, supertest_1.default)(app)
        .post("/api/auth/login")
        .send({ email: "user@feature.com", password: "password123" });
    token = loginRes.body.token;
}));
afterAll(() => __awaiter(void 0, void 0, void 0, function* () {
    yield mongoose_1.default.disconnect();
    yield mongoServer.stop();
}));
describe("Feature Integration Tests (SOS & Notifications)", () => {
    it("should trigger an SOS alert", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .post("/api/sos")
            .set("Authorization", `Bearer ${token}`)
            .send({
            type: "medical",
            location: { lat: 12.97, lng: 77.59 },
            message: "Emergency help needed",
        });
        expect(res.status).toBe(201);
        expect(res.body.status).toBe("active");
    }));
    it("should list active SOS alerts for the college", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .get("/api/sos")
            .set("Authorization", `Bearer ${token}`);
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBeGreaterThan(0);
    }));
    it("should get notifications for the user", () => __awaiter(void 0, void 0, void 0, function* () {
        // Manually create a notification first
        yield Notification_model_1.default.create({
            receiverId: userId,
            collegeId: collegeId,
            message: "Test Notification",
            type: "alert",
        });
        const res = yield (0, supertest_1.default)(app)
            .get("/api/notification")
            .set("Authorization", `Bearer ${token}`);
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.some((n) => n.message === "Test Notification")).toBe(true);
    }));
    it("should mark notification as read", () => __awaiter(void 0, void 0, void 0, function* () {
        const notif = yield Notification_model_1.default.findOne({ receiverId: userId });
        const res = yield (0, supertest_1.default)(app)
            .put(`/api/notification/${notif === null || notif === void 0 ? void 0 : notif._id}/read`)
            .set("Authorization", `Bearer ${token}`);
        expect(res.status).toBe(200);
        expect(res.body.isRead).toBe(true);
    }));
});
