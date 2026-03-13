import request from "supertest";
import { MongoMemoryServer } from "mongodb-memory-server";
import mongoose from "mongoose";
import { createApp } from "../../src/app";
import User from "../../src/models/User.model";
import College from "../../src/models/College.model";
import { Sos as SOS } from "../../src/models/Sos.model";
import Notification from "../../src/models/Notification.model";

let mongoServer: MongoMemoryServer;
let app: any;
let token: string;
let collegeId: string;
let userId: string = "";

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
  const instances = await createApp();
  app = instances.app;

  // Create a college
  const college = await College.create({
    name: "Feature College",
    allowedDomains: ["feature.com"],
    verified: true,
    createdBy: "system",
  });
  collegeId = (college._id as any).toString();

  // Create a user
  const user = await User.create({
    _id: "user_feature",
    fullName: "Feature User",
    email: "user@feature.com",
    password: "password123",
    role: "student",
    collegeId: collegeId,
    approved: true,
    emailVerified: true,
  });
  userId = (user._id as any).toString();

  // Login
  const loginRes = await request(app)
    .post("/api/auth/login")
    .send({ email: "user@feature.com", password: "password123" });
  token = loginRes.body.token;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe("Feature Integration Tests (SOS & Notifications)", () => {
  it("should trigger an SOS alert", async () => {
    const res = await request(app)
      .post("/api/sos")
      .set("Authorization", `Bearer ${token}`)
      .send({
        type: "medical",
        location: { lat: 12.97, lng: 77.59 },
        message: "Emergency help needed",
      });

    expect(res.status).toBe(201);
    expect(res.body.status).toBe("active");
  });

  it("should list active SOS alerts for the college", async () => {
    const res = await request(app)
      .get("/api/sos")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it("should get notifications for the user", async () => {
    // Manually create a notification first
    await Notification.create({
      receiverId: userId,
      collegeId: collegeId,
      message: "Test Notification",
      type: "alert",
    });

    const res = await request(app)
      .get("/api/notification")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.some((n: any) => n.message === "Test Notification")).toBe(
      true,
    );
  });

  it("should mark notification as read", async () => {
    const notif = await Notification.findOne({ receiverId: userId });
    const res = await request(app)
      .put(`/api/notification/${notif?._id}/read`)
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.isRead).toBe(true);
  });
});
