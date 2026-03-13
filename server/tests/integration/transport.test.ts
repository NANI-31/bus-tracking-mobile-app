import request from "supertest";
import { MongoMemoryServer } from "mongodb-memory-server";
import mongoose from "mongoose";
import { createApp } from "../../src/app";
import User from "../../src/models/User.model";
import College from "../../src/models/College.model";
import { Bus } from "../../src/models/Bus.model";
import Route from "../../src/models/Route.model";

let mongoServer: MongoMemoryServer;
let app: any;
let adminToken: string;
let collegeId: string;
let busId: string;
let routeId: string;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
  const instances = await createApp();
  app = instances.app;

  // Create a college
  const college = await College.create({
    name: "Transport College",
    allowedDomains: ["transport.com"],
    verified: true,
    createdBy: "system",
  });
  collegeId = (college._id as any).toString();

  // Create an admin
  await User.create({
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
  const loginRes = await request(app)
    .post("/api/auth/login")
    .send({ email: "admin@transport.com", password: "password123" });
  adminToken = loginRes.body.token;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe("Transport Integration Tests", () => {
  it("should create a new route", async () => {
    const res = await request(app)
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
  });

  it("should create a new bus", async () => {
    const res = await request(app)
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
  });

  it("should assign a route to a bus", async () => {
    const res = await request(app)
      .put(`/api/bus/${busId}`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ routeId: routeId });

    expect(res.status).toBe(200);
    expect(res.body.routeId).toBe(routeId);
  });

  it("should list all buses in a college", async () => {
    const res = await request(app)
      .get("/api/bus")
      .set("Authorization", `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.some((b: any) => b.busNumber === "KA-01-1234")).toBe(true);
  });

  it("should enforce multi-tenant isolation for transport", async () => {
    // Create another college and admin
    const otherCollege = await College.create({
      name: "Other Transport",
      allowedDomains: ["other-transport.com"],
      verified: true,
      createdBy: "system",
    });

    await User.create({
      _id: "otherAdmin",
      fullName: "Other Admin",
      email: "other@transport.com",
      password: "password123",
      role: "admin",
      collegeId: otherCollege._id,
      approved: true,
      emailVerified: true,
    });

    const loginRes = await request(app)
      .post("/api/auth/login")
      .send({ email: "other@transport.com", password: "password123" });
    const otherToken = loginRes.body.token;

    // Try to access first college's bus with other admin's token
    const res = await request(app)
      .get(`/api/bus/${busId}`)
      .set("Authorization", `Bearer ${otherToken}`);

    // Depending on implementation, this might be 403 or 404 (not found in tenant)
    expect([403, 404]).toContain(res.status);
  });
});
