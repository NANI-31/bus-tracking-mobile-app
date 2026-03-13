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
let adminToken;
let collegeId;
let busId;
let routeId;
beforeAll(() => __awaiter(void 0, void 0, void 0, function* () {
    mongoServer = yield mongodb_memory_server_1.MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    yield mongoose_1.default.connect(uri);
    const instances = yield (0, app_1.createApp)();
    app = instances.app;
    // Create a college
    const college = yield College_model_1.default.create({
        name: "Transport College",
        allowedDomains: ["transport.com"],
        verified: true,
        createdBy: "system",
    });
    collegeId = college._id.toString();
    // Create an admin
    yield User_model_1.default.create({
        _id: "admin123",
        fullName: "Transport Admin",
        email: "admin@transport.com",
        password: "password123",
        role: "admin",
        collegeId: collegeId,
        approved: true,
        emailVerified: true,
    });
    // Login as admin
    const loginRes = yield (0, supertest_1.default)(app)
        .post("/api/auth/login")
        .send({ email: "admin@transport.com", password: "password123" });
    adminToken = loginRes.body.token;
}));
afterAll(() => __awaiter(void 0, void 0, void 0, function* () {
    yield mongoose_1.default.disconnect();
    yield mongoServer.stop();
}));
describe("Transport Integration Tests", () => {
    it("should create a new route", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .post("/api/route")
            .set("Authorization", `Bearer ${adminToken}`)
            .send({
            name: "Route 101",
            stops: [
                { name: "Stop A", location: { lat: 12.97, lng: 77.59 } },
                { name: "Stop B", location: { lat: 12.98, lng: 77.6 } },
            ],
            collegeId: collegeId,
        });
        expect(res.status).toBe(201);
        expect(res.body.name).toBe("Route 101");
        routeId = res.body._id;
    }));
    it("should create a new bus", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .post("/api/bus")
            .set("Authorization", `Bearer ${adminToken}`)
            .send({
            busNumber: "KA-01-1234",
            capacity: 50,
            collegeId: collegeId,
        });
        expect(res.status).toBe(201);
        expect(res.body.busNumber).toBe("KA-01-1234");
        busId = res.body._id;
    }));
    it("should assign a route to a bus", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .put(`/api/bus/${busId}`)
            .set("Authorization", `Bearer ${adminToken}`)
            .send({ routeId: routeId });
        expect(res.status).toBe(200);
        expect(res.body.routeId).toBe(routeId);
    }));
    it("should list all buses in a college", () => __awaiter(void 0, void 0, void 0, function* () {
        const res = yield (0, supertest_1.default)(app)
            .get("/api/bus")
            .set("Authorization", `Bearer ${adminToken}`);
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.some((b) => b.busNumber === "KA-01-1234")).toBe(true);
    }));
    it("should enforce multi-tenant isolation for transport", () => __awaiter(void 0, void 0, void 0, function* () {
        // Create another college and admin
        const otherCollege = yield College_model_1.default.create({
            name: "Other Transport",
            allowedDomains: ["other-transport.com"],
            verified: true,
            createdBy: "system",
        });
        yield User_model_1.default.create({
            _id: "otherAdmin",
            fullName: "Other Admin",
            email: "other@transport.com",
            password: "password123",
            role: "admin",
            collegeId: otherCollege._id,
            approved: true,
            emailVerified: true,
        });
        const loginRes = yield (0, supertest_1.default)(app)
            .post("/api/auth/login")
            .send({ email: "other@transport.com", password: "password123" });
        const otherToken = loginRes.body.token;
        // Try to access first college's bus with other admin's token
        const res = yield (0, supertest_1.default)(app)
            .get(`/api/bus/${busId}`)
            .set("Authorization", `Bearer ${otherToken}`);
        // Depending on implementation, this might be 403 or 404 (not found in tenant)
        expect([403, 404]).toContain(res.status);
    }));
});
