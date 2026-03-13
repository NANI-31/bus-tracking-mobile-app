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
exports.getAuthHeader = exports.createTestBus = exports.createTestUser = exports.createTestCollege = exports.generateTestToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const User_model_1 = __importDefault(require("@/models/User.model"));
const College_model_1 = __importDefault(require("@/models/College.model"));
const Bus_model_1 = require("@/models/Bus.model");
const generateTestToken = (payload) => {
    return jsonwebtoken_1.default.sign(payload, process.env.JWT_SECRET || 'test-secret', { expiresIn: '1h' });
};
exports.generateTestToken = generateTestToken;
const createTestCollege = (...args_1) => __awaiter(void 0, [...args_1], void 0, function* (overrides = {}) {
    const college = new College_model_1.default(Object.assign({ name: 'Test College', busNumbers: ['B1', 'B2'], allowedDomains: ['test.edu'] }, overrides));
    return yield college.save();
});
exports.createTestCollege = createTestCollege;
const createTestUser = (...args_1) => __awaiter(void 0, [...args_1], void 0, function* (overrides = {}) {
    const user = new User_model_1.default(Object.assign({ fullName: 'Test User', email: `test-${Date.now()}@test.edu`, password: 'password123', role: 'student', emailVerified: true, approved: true }, overrides));
    return yield user.save();
});
exports.createTestUser = createTestUser;
const createTestBus = (collegeId_1, ...args_1) => __awaiter(void 0, [collegeId_1, ...args_1], void 0, function* (collegeId, overrides = {}) {
    const bus = new Bus_model_1.Bus(Object.assign({ busNumber: 'B1', collegeId, status: 'unassigned', isActive: false }, overrides));
    return yield bus.save();
});
exports.createTestBus = createTestBus;
const getAuthHeader = (token) => ({
    Authorization: `Bearer ${token}`,
});
exports.getAuthHeader = getAuthHeader;
