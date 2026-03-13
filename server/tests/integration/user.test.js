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
let mongoServer;
let app;
let token;
let userId = "";
let collegeId;
beforeAll(() => __awaiter(void 0, void 0, void 0, function* () {
    mongoServer = yield mongodb_memory_server_1.MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    yield mongoose_1.default.connect(uri);
    const instances = yield (0, app_1.createApp)();
    app = instances.app;
    // Create a college and user for testing
    const college = yield College_model_1.default.create({
        name: "Test College",
        allowedDomains: ["test.com"],
        verified: true,
        createdBy: "system",
    });
    collegeId = college._id.toString();
    const user = yield User_model_1.default.create({
        _id: "user123",
        fullName: "Test User",
        email: "user@test.com",
        password: "password123",
        role: "student",
        collegeId: college._id,
        approved: true,
        emailVerified: true,
    });
    userId = user._id.toString();
    // Login to get token
    const res = yield (0, supertest_1.default)(app)
        .post("/api/auth/login")
        .send({ email: "user@test.com", password: "password123" });
    token = res.body.token;
}));
afterAll(() => __awaiter(void 0, void 0, void 0, function* () {
    yield mongoose_1.default.disconnect();
    yield mongoServer.stop();
}));
describe("User Integration Tests", () => {
    it("should get the user profile", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .get("/api/user/profile")
            .set("Authorization", `Bearer ${token}`);
        expect(res.status).toBe(200);
        expect(res.body.fullName).toBe("Test User");
        expect(res.body.email).toBe("user@test.com");
    }));
    it("should update the user profile", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .put("/api/user/profile")
            .set("Authorization", `Bearer ${token}`)
            .send({ fullName: "Updated Name", phoneNumber: "1234567890" });
        expect(res.status).toBe(200);
        expect(res.body.fullName).toBe("Updated Name");
        expect(res.body.phoneNumber).toBe("1234567890");
        const updatedUser = yield User_model_1.default.findById(userId);
        expect(updatedUser === null || updatedUser === void 0 ? void 0 : updatedUser.fullName).toBe("Updated Name");
    }));
    it("should return 401 when accessing profile without token", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app).get("/api/user/profile");
        expect(res.status).toBe(401);
    }));
    it("should enforce multi-tenant isolation", () => __awaiter(void 0, void 0, void 0, function* () {
        // Create another college and user
        const otherCollege = yield College_model_1.default.create({
            name: "Other College",
            allowedDomains: ["other.com"],
            verified: true,
            createdBy: "system",
        });
        yield User_model_1.default.create({
            _id: "otherUser",
            fullName: "Other User",
            email: "other@test.com",
            password: "password123",
            role: "student",
            collegeId: otherCollege._id,
            approved: true,
            emailVerified: true,
        });
        const res = yield (0, supertest_1.default)(app)
            .get("/api/user/profile")
            .set("Authorization", `Bearer ${token}`);
        expect(res.status).toBe(200);
        expect(res.body.collegeId).toBe(collegeId);
        expect(res.body.collegeId).not.toBe(otherCollege._id.toString());
    }));
});
