import request from "supertest";
import { MongoMemoryServer } from "mongodb-memory-server";
import mongoose from "mongoose";
import { createApp } from "../../src/app";
import User from "../../src/models/User.model";
import College from "../../src/models/College.model";

let mongoServer: MongoMemoryServer;
let app: any;
let superAdminToken: string;
let collegeId: string;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
  const instances = await createApp();
  app = instances.app;

  // Create a Super Admin
  await User.create({
    _id: "superadmin123",
    fullName: "Super Admin",
    email: "superadmin@test.com",
    password: "password123",
    role: "superAdmin",
    approved: true,
    emailVerified: true,
  });

  // Login as Super Admin
  const loginRes = await request(app)
    .post("/api/auth/login")
    .send({ email: "superadmin@test.com", password: "password123" });
  superAdminToken = loginRes.body.token;

  // Create a college
  const college = await College.create({
    name: "Test College",
    allowedDomains: ["test.com"],
    verified: false,
    createdBy: "superadmin123",
  });
  collegeId = (college._id as any).toString();
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe("College Integration Tests (Super Admin)", () => {
  it("should list all colleges", async () => {
    const res = await request(app)
      .get("/api/college")
      .set("Authorization", `Bearer ${superAdminToken}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it("should get college details", async () => {
    const res = await request(app)
      .get(`/api/super-admin/college/${collegeId}`)
      .set("Authorization", `Bearer ${superAdminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.name).toBe("Test College");
  });

  it("should verify a college", async () => {
    const res = await request(app)
      .put(`/api/super-admin/college/${collegeId}/verify`)
      .set("Authorization", `Bearer ${superAdminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.verified).toBe(true);

    const updatedCollege = await College.findById(collegeId);
    expect(updatedCollege?.verified).toBe(true);
  });

  it("should reject non-superadmin access to verify", async () => {
    // Create a regular user
    await User.create({
      _id: "user123_college",
      fullName: "Regular User",
      email: "user_college@test.com",
      password: "password123",
      role: "student",
      collegeId: collegeId,
      approved: true,
      emailVerified: true,
    });

    const loginRes = await request(app)
      .post("/api/auth/login")
      .send({ email: "user_college@test.com", password: "password123" });
    const userToken = loginRes.body.token;

    const res = await request(app)
      .put(`/api/super-admin/college/${collegeId}/verify`)
      .set("Authorization", `Bearer ${userToken}`);

    expect(res.status).toBe(403);
  });
});
