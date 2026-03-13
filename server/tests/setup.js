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
const mongodb_memory_server_1 = require("mongodb-memory-server");
const mongoose_1 = __importDefault(require("mongoose"));
process.env.RAZORPAY_KEY_ID = 'test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_secret';
process.env.JWT_SECRET = 'test_jwt_secret';
process.env.REFRESH_TOKEN_SECRET = 'test_refresh_secret';
process.env.RAZORPAY_WEBHOOK_SECRET = 'test_webhook_secret';
let mongoServer;
beforeAll(() => __awaiter(void 0, void 0, void 0, function* () {
    mongoServer = yield mongodb_memory_server_1.MongoMemoryServer.create({
        instance: {
            dbName: 'jest_test'
        }
    });
    const uri = mongoServer.getUri();
    yield mongoose_1.default.connect(uri);
}), 60000); // 60s timeout
afterAll(() => __awaiter(void 0, void 0, void 0, function* () {
    yield mongoose_1.default.disconnect();
    if (mongoServer) {
        yield mongoServer.stop();
    }
}));
beforeEach(() => __awaiter(void 0, void 0, void 0, function* () {
    if (mongoose_1.default.connection.db) {
        const collections = yield mongoose_1.default.connection.db.collections();
        for (const collection of collections) {
            yield collection.deleteMany({});
        }
    }
}));
// Global mocks
jest.mock('@/utils/logger', () => ({
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
}));
jest.mock('firebase-admin', () => ({
    initializeApp: jest.fn(),
    credential: {
        cert: jest.fn(),
    },
    messaging: jest.fn(() => ({
        send: jest.fn().mockResolvedValue('success'),
        sendEachForMulticast: jest.fn().mockResolvedValue({ successCount: 1, failureCount: 0 }),
    })),
}));
jest.mock('uuid', () => ({
    v4: jest.fn(() => 'mocked-uuid'),
}));
