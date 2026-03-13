import request from "supertest";
import { MongoMemoryServer } from "mongodb-memory-server";
import mongoose from "mongoose";
import { createApp } from "../../src/app";
import User from "../../src/models/User.model";
import College from "../../src/models/College.model";

let mongoServer: MongoMemoryServer;
let app: any;
let token: string;
let userId: string = "";
let collegeId: string;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
  const instances = await createApp();
  app = instances.app;

  // Create a college and user for testing
  const college = await College.create({
    name: "Test College",
    allowedDomains: ["test.com"],
    verified: true,
    createdBy: "system",
  });
  collegeId = (college._id as any).toString();

  const user = await User.create({
    _id: "user123",
    fullName: "Test User",
    email: "user@test.com",
    password: "password123",
    role: "student",
    collegeId: college._id,
    approved: true,
    emailVerified: true,
  });
  userId = (user._id as any).toString();

  // Login to get token
  const res = await request(app)
    .post("/api/auth/login")
    .send({ email: "user@test.com", password: "password123" });
  token = res.body.token;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe("User Integration Tests", () => {
  it("should get the user profile", async () => {
    const res = await request(app)
      .get("/api/user/profile")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.fullName).toBe("Test User");
    expect(res.body.email).toBe("user@test.com");
  });

  it("should update the user profile", async () => {
    const res = await request(app)
      .put("/api/user/profile")
      .set("Authorization", `Bearer ${token}`)
      .send({ fullName: "Updated Name", phoneNumber: "1234567890" });

    expect(res.status).toBe(200);
    expect(res.body.fullName).toBe("Updated Name");
    expect(res.body.phoneNumber).toBe("1234567890");

    const updatedUser = await User.findById(userId);
    expect(updatedUser?.fullName).toBe("Updated Name");
  });

  it("should return 401 when accessing profile without token", async () => {
    const res = await request(app).get("/api/user/profile");
    expect(res.status).toBe(401);
  });

  it("should enforce multi-tenant isolation", async () => {
    // Create another college and user
    const otherCollege = await College.create({
      name: "Other College",
      allowedDomains: ["other.com"],
      verified: true,
      createdBy: "system",
    });

    await User.create({
      _id: "otherUser",
      fullName: "Other User",
      email: "other@test.com",
      password: "password123",
      role: "student",
      collegeId: otherCollege._id,
      approved: true,
      emailVerified: true,
    });

    const res = await request(app)
      .get("/api/user/profile")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.collegeId).toBe(collegeId);
    expect(res.body.collegeId).not.toBe((otherCollege._id as any).toString());
  });
});
