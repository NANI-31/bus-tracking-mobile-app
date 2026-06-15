import { createServer } from "http";
import { Server } from "socket.io";
import { io as Client, Socket as ClientSocket } from "socket.io-client";
import { createApp } from "../../src/app";
import mongoose from "mongoose";
import { MongoMemoryServer } from "mongodb-memory-server";
import jwt from "jsonwebtoken";
import User from "../../src/models/User.model";
import College from "../../src/models/College.model";
import { Bus, BusLocation } from "../../src/models/Bus.model";
import { Sos } from "../../src/models/Sos.model";
import { stopSocketInterval } from "../../src/socket/index";

// Increase timeout for MongoDB binary download
jest.setTimeout(300000);

// Mock Redis with loopback for Socket.IO adapter support
jest.mock("redis", () => {
  const pSubHandlers: any[] = [];
  const mClient: any = {
    on: jest.fn((event, handler) => {
      if (event === "pmessage" || event === "message") {
        pSubHandlers.push(handler);
      }
    }),
    connect: jest.fn().mockResolvedValue(undefined),
    duplicate: jest.fn((): any => mClient),
    psubscribe: jest.fn(),
    punsubscribe: jest.fn(),
    pSubscribe: jest.fn((pattern, handler) => {
        // Newer redis clients might pass handler here
        if (handler) pSubHandlers.push(handler);
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
  let io: Server;
  let clientSocket: ClientSocket;
  let mongoServer: MongoMemoryServer;
  let httpServer: any;
  let app: any;
  let token: string;
  let collegeId: string;
  let driverId: string = new mongoose.Types.ObjectId().toString();
  let busId: string;

  beforeAll(async () => {
    // Ensure JWT secret is set for tests
    process.env.JWT_SECRET = process.env.JWT_SECRET || "test_jwt_secret";

    mongoServer = await MongoMemoryServer.create({
      instance: {
        launchTimeout: 60000,
      },
    });
    const uri = mongoServer.getUri();
    
    // Ensure we disconnect from any existing connections before connecting to the test DB
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
    await mongoose.connect(uri);

    const instances = createApp();
    app = instances.app;
    httpServer = instances.httpServer;
    io = instances.io;

    // Create a college and driver for testing
    const college = await College.create({
      name: "Socket College",
      allowedDomains: ["socket.com"],
      verified: true,
      createdBy: "system",
    });
    collegeId = (college._id as any).toString();

    const driver = await User.create({
      _id: driverId,
      fullName: "Driver Joe",
      email: "driver@socket.com",
      password: "password123",
      role: "driver",
      collegeId: collegeId,
      approved: true,
      emailVerified: true,
    });

    token = jwt.sign(
      { id: driverId, role: "driver", collegeId: collegeId },
      process.env.JWT_SECRET || "test_jwt_secret"
    );

    const bus = await Bus.create({
      busNumber: "SKT-001",
      driverId: driverId,
      collegeId: collegeId,
      status: "on-time",
    });
    busId = (bus._id as any).toString();

    await new Promise<void>((resolve, reject) => {
      httpServer.listen(() => {
        const port = (httpServer.address() as any).port;
        clientSocket = Client(`http://localhost:${port}`, {
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
  });

  afterAll(async () => {
    stopSocketInterval();
    if (clientSocket) clientSocket.disconnect();
    if (io) io.close();
    if (httpServer) httpServer.close();
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
    if (mongoServer) {
      await mongoServer.stop();
    }
  });

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

    const port = (httpServer.address() as any).port;
    const secondClient = Client(`http://localhost:${port}`, {
      auth: { token },
      transports: ["websocket"],
      forceNew: true,
      reconnection: false,
    });

    secondClient.on("connect", () => {
      secondClient.emit("join_college", collegeId);
      
      // Wait for server to process join
      setTimeout(() => {
        secondClient.on("location_updated", (data: any) => {
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

    const port = (httpServer.address() as any).port;
    const adminId = new mongoose.Types.ObjectId().toString();
    const adminToken = jwt.sign(
      { id: adminId, role: "admin", collegeId: collegeId },
      process.env.JWT_SECRET || "test_jwt_secret"
    );
    
    const adminClient = Client(`http://localhost:${port}`, {
      auth: { token: adminToken },
      transports: ["websocket"],
      forceNew: true,
      reconnection: false,
    });

    adminClient.on("connect", () => {
      adminClient.emit("join_college", collegeId);
      
      // Wait for server to process join
      setTimeout(() => {
        adminClient.on("sos_alert", (data: any) => {
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
