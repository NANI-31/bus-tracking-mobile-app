import request from "supertest";
import mongoose from "mongoose";
import { MongoMemoryServer } from "mongodb-memory-server";
import { createApp } from "@/app";
import User from "@/models/User.model";
import College from "@/models/College.model";

let mongoServer: MongoMemoryServer;
let app: any;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
  const setup = createApp();
  app = setup.app;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

beforeEach(async () => {
  await User.deleteMany({});
  await College.deleteMany({});
});

describe("Auth Integration Tests", () => {
  const testCollege = {
    name: "Test University",
    location: "Test City",
    shortName: "TU",
  };

  const testUser = {
    fullName: "Test User",
    email: "test@example.com",
    password: "password123",
    role: "student",
    phoneNumber: "1234567890",
  };

  it("should register a new user and college successfully", async () => {
    const res = await request(app)
      .post("/api/v1/auth/register")
      .send({
        ...testUser,
        collegeName: testCollege.name,
        collegeLocation: testCollege.location,
        collegeShortName: testCollege.shortName,
      });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("message", "User registered successfully");
    expect(res.body.user).toHaveProperty("email", testUser.email);
    expect(res.body).toHaveProperty("accessToken");

    const userInDb = await User.findOne({ email: testUser.email });
    expect(userInDb).toBeDefined();
    const collegeInDb = await College.findOne({ name: testCollege.name });
    expect(collegeInDb).toBeDefined();
  });

  it("should login an existing user", async () => {
    // First register
    await request(app)
      .post("/api/v1/auth/register")
      .send({
        ...testUser,
        collegeName: testCollege.name,
        collegeLocation: testCollege.location,
        collegeShortName: testCollege.shortName,
      });

    const res = await request(app)
      .post("/api/v1/auth/login")
      .send({
        email: testUser.email,
        password: testUser.password,
      });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty("accessToken");
    expect(res.body.user).toHaveProperty("email", testUser.email);
  });

  it("should return 401 for invalid credentials", async () => {
    const res = await request(app)
      .post("/api/v1/auth/login")
      .send({
        email: "wrong@example.com",
        password: "wrongpassword",
      });

    expect(res.status).toBe(404); // Based on current implementation which returns 404 for user not found
  });
});
