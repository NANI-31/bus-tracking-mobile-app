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
let superAdminToken;
let collegeId;
beforeAll(() => __awaiter(void 0, void 0, void 0, function* () {
    mongoServer = yield mongodb_memory_server_1.MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    yield mongoose_1.default.connect(uri);
    const instances = yield (0, app_1.createApp)();
    app = instances.app;
    // Create a Super Admin
    yield User_model_1.default.create({
        _id: "superadmin123",
        fullName: "Super Admin",
        email: "superadmin@test.com",
        password: "password123",
        role: "superAdmin",
        approved: true,
        emailVerified: true,
    });
    // Login as Super Admin
    const loginRes = yield (0, supertest_1.default)(app)
        .post("/api/auth/login")
        .send({ email: "superadmin@test.com", password: "password123" });
    superAdminToken = loginRes.body.token;
    // Create a college
    const college = yield College_model_1.default.create({
        name: "Test College",
        allowedDomains: ["test.com"],
        verified: false,
        createdBy: "superadmin123",
    });
    collegeId = college._id.toString();
}));
afterAll(() => __awaiter(void 0, void 0, void 0, function* () {
    yield mongoose_1.default.disconnect();
    yield mongoServer.stop();
}));
describe("College Integration Tests (Super Admin)", () => {
    it("should list all colleges", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .get("/api/college")
            .set("Authorization", `Bearer ${superAdminToken}`);
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBeGreaterThan(0);
    }));
    it("should get college details", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .get(`/api/super-admin/college/${collegeId}`)
            .set("Authorization", `Bearer ${superAdminToken}`);
        expect(res.status).toBe(200);
        expect(res.body.name).toBe("Test College");
    }));
    it("should verify a college", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .put(`/api/super-admin/college/${collegeId}/verify`)
            .set("Authorization", `Bearer ${superAdminToken}`);
        expect(res.status).toBe(200);
        expect(res.body.verified).toBe(true);
        const updatedCollege = yield College_model_1.default.findById(collegeId);
        expect(updatedCollege === null || updatedCollege === void 0 ? void 0 : updatedCollege.verified).toBe(true);
    }));
    it("should reject non-superadmin access to verify", () => __awaiter(void 0, void 0, void 0, function* () {
        // Create a regular user
        yield User_model_1.default.create({
            _id: "user123_college",
            fullName: "Regular User",
            email: "user_college@test.com",
            password: "password123",
            role: "student",
            collegeId: collegeId,
            approved: true,
            emailVerified: true,
        });
        const loginRes = yield (0, supertest_1.default)(app)
            .post("/api/auth/login")
            .send({ email: "user_college@test.com", password: "password123" });
        const userToken = loginRes.body.token;
        const res = yield (0, supertest_1.default)(app)
            .put(`/api/super-admin/college/${collegeId}/verify`)
            .set("Authorization", `Bearer ${userToken}`);
        expect(res.status).toBe(403);
    }));
});
