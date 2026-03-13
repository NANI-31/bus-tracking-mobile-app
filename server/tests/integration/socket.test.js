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
const socket_io_client_1 = require("socket.io-client");
const app_1 = require("../../src/app");
const mongoose_1 = __importDefault(require("mongoose"));
const mongodb_memory_server_1 = require("mongodb-memory-server");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const User_model_1 = __importDefault(require("../../src/models/User.model"));
const College_model_1 = __importDefault(require("../../src/models/College.model"));
const Bus_model_1 = require("../../src/models/Bus.model");
const socket_1 = require("../../src/socket");
// Increase timeout for MongoDB binary download
jest.setTimeout(300000);
// Mock Redis with loopback for Socket.IO adapter support
jest.mock("redis", () => {
    const pSubHandlers = [];
    const mClient = {
        on: jest.fn((event, handler) => {
            if (event === "pmessage" || event === "message") {
                pSubHandlers.push(handler);
            }
        }),
        connect: jest.fn().mockResolvedValue(undefined),
        duplicate: jest.fn(() => mClient),
        psubscribe: jest.fn(),
        punsubscribe: jest.fn(),
        pSubscribe: jest.fn((pattern, handler) => {
            // Newer redis clients might pass handler here
            if (handler)
                pSubHandlers.push(handler);
        }),
        pUnsubscribe: jest.fn(),
        publish: jest.fn((channel, message) => {
            // Loopback to pmessage/message handlers
            pSubHandlers.forEach((h) => {
                // Newer redis client (pSubscribe) expects (message, channel)
                // Older client (pmessage) expects (pattern, channel, message)
                // Socket.IO adapter detects and handles both, but we'll provide what it expects for pSubscribe
                h(message, channel);
            });
        }),
        subscribe: jest.fn(),
        unsubscribe: jest.fn(),
        quit: jest.fn().mockResolvedValue(undefined),
        off: jest.fn(),
        isOpen: true,
    };
    return {
        createClient: jest.fn().mockReturnValue(mClient),
    };
});
describe("Socket.IO Integration Tests", () => {
    let io;
    let clientSocket;
    let mongoServer;
    let httpServer;
    let app;
    let token;
    let collegeId;
    let driverId = new mongoose_1.default.Types.ObjectId().toString();
    let busId;
    beforeAll(() => __awaiter(void 0, void 0, void 0, function* () {
        // Ensure JWT secret is set for tests
        process.env.JWT_SECRET = process.env.JWT_SECRET || "test_jwt_secret";
        mongoServer = yield mongodb_memory_server_1.MongoMemoryServer.create({
            instance: {
                launchTimeout: 60000,
            },
        });
        const uri = mongoServer.getUri();
        // Ensure we disconnect from any existing connections before connecting to the test DB
        if (mongoose_1.default.connection.readyState !== 0) {
            yield mongoose_1.default.disconnect();
        }
        yield mongoose_1.default.connect(uri);
        const instances = (0, app_1.createApp)();
        app = instances.app;
        httpServer = instances.httpServer;
        io = instances.io;
        // Create a college and driver for testing
        const college = yield College_model_1.default.create({
            name: "Socket College",
            allowedDomains: ["socket.com"],
            verified: true,
            createdBy: "system",
        });
        collegeId = college._id.toString();
        const driver = yield User_model_1.default.create({
            _id: driverId,
            fullName: "Driver Joe",
            email: "driver@socket.com",
            password: "password123",
            role: "driver",
            collegeId: collegeId,
            approved: true,
            emailVerified: true,
        });
        token = jsonwebtoken_1.default.sign({ id: driverId, role: "driver", collegeId: collegeId }, process.env.JWT_SECRET || "test_jwt_secret");
        const bus = yield Bus_model_1.Bus.create({
            busNumber: "SKT-001",
            driverId: driverId,
            collegeId: collegeId,
            status: "on-time",
        });
        busId = bus._id.toString();
        yield new Promise((resolve, reject) => {
            httpServer.listen(() => {
                const port = httpServer.address().port;
                clientSocket = (0, socket_io_client_1.io)(`http://localhost:${port}`, {
                    auth: { token },
                    transports: ["websocket"],
                    forceNew: true,
                    reconnection: false,
                });
                clientSocket.on("connect", resolve);
                clientSocket.on("connect_error", (err) => {
                    console.error("Client Socket Connect Error:", err);
                    reject(err);
                });
            });
        });
    }));
    afterAll(() => __awaiter(void 0, void 0, void 0, function* () {
        (0, socket_1.stopSocketInterval)();
        if (clientSocket)
            clientSocket.disconnect();
        if (io)
            io.close();
        if (httpServer)
            httpServer.close();
        if (mongoose_1.default.connection.readyState !== 0) {
            yield mongoose_1.default.disconnect();
        }
        if (mongoServer) {
            yield mongoServer.stop();
        }
    }));
    it("should authenticate and connect", (done) => {
        expect(clientSocket.connected).toBe(true);
        done();
    });
    it("should join college room", (done) => {
        clientSocket.emit("join_college", collegeId);
        setTimeout(() => {
            done();
        }, 100);
    });
    it("should broadcast location updates to the college room", (done) => {
        const locationData = {
            busId: busId,
            collegeId: collegeId,
            location: { lat: 12.97, lng: 77.59 },
            speed: 40,
            heading: 90,
        };
        const port = httpServer.address().port;
        const secondClient = (0, socket_io_client_1.io)(`http://localhost:${port}`, {
            auth: { token },
            transports: ["websocket"],
            forceNew: true,
            reconnection: false,
        });
        secondClient.on("connect", () => {
            secondClient.emit("join_college", collegeId);
            // Wait for server to process join
            setTimeout(() => {
                secondClient.on("location_updated", (data) => {
                    expect(data.busId).toBe(busId);
                    expect(data.location.lat).toBe(12.97);
                    secondClient.disconnect();
                    done();
                });
                clientSocket.emit("update_location", locationData);
            }, 500);
        });
    });
    it("should trigger an SOS alert and propagate to coordinator room", (done) => {
        const sosData = {
            type: "medical",
            location: { lat: 12.97, lng: 77.59 },
            message: "Driver needs help",
        };
        const port = httpServer.address().port;
        const adminId = new mongoose_1.default.Types.ObjectId().toString();
        const adminToken = jsonwebtoken_1.default.sign({ id: adminId, role: "admin", collegeId: collegeId }, process.env.JWT_SECRET || "test_jwt_secret");
        const adminClient = (0, socket_io_client_1.io)(`http://localhost:${port}`, {
            auth: { token: adminToken },
            transports: ["websocket"],
            forceNew: true,
            reconnection: false,
        });
        adminClient.on("connect", () => {
            adminClient.emit("join_college", collegeId);
            // Wait for server to process join
            setTimeout(() => {
                adminClient.on("sos_alert", (data) => {
                    expect(data.type).toBe("medical");
                    expect(data.message).toBe("Driver needs help");
                    adminClient.disconnect();
                    done();
                });
                clientSocket.emit("trigger_sos", sosData);
            }, 500);
        });
    });
});
