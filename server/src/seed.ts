require("dotenv").config();
console.log("Starting master seed script...");
import mongoose from "mongoose";
import dotenv from "dotenv";
import { pubClient } from "./config/redis";
import { kkrKsrTransportData } from "./seedData/routesData";
import { seedColleges } from "./seeds/collegeSeed";
import { seedUsers } from "./seeds/userSeed";
import { seedTransport } from "./seeds/transportSeed";
import { UserRole } from "./models/User";

import Route from "./models/Route";
import { Bus } from "./models/Bus";
import Schedule from "./models/Schedule";
import College from "./models/College";
import User from "./models/User";
import { collegesData } from "./seedData/collegesData";

dotenv.config();

const runSeed = async () => {
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    throw new Error("MONGO_URI is not defined in environment variables");
  }

  try {
    console.log("Connecting to MongoDB...");
    await mongoose.connect(mongoUri);

    console.log("Connecting to Redis and clearing cache...");
    if (!pubClient.isOpen) {
      await pubClient.connect();
    }
    await pubClient.flushAll();
    console.log("Redis cache cleared.");

    console.log("Clearing all existing data...");
    await College.deleteMany({});
    await User.deleteMany({});
    await Route.deleteMany({});
    await Bus.deleteMany({});
    await Schedule.deleteMany({});

    for (const collegeData of collegesData) {
      console.log(`\n--- Seeding ${collegeData.name} ---`);

      // 0. Pre-generate Bus Numbers from routes
      const busNumbers = collegeData.routes.map((r: any) => r.busNumber);

      // 1. Seed College
      const college = await seedColleges({
        name: collegeData.name,
        domains: [collegeData.domain],
        busNumbers: busNumbers,
      });

      // 2. Seed Users
      const users = await seedUsers(
        college._id.toString(),
        collegeData.domain,
        collegeData.shortName,
      );

      const coordinator = users.find((u) => u.role === UserRole.BusCoordinator);
      if (!coordinator) {
        console.warn(`Coordinator not found for ${collegeData.name}`);
        continue;
      }

      const drivers = users.filter((u) => u.role === UserRole.Driver);

      // 3. Seed Transport
      await seedTransport(
        college._id.toString(),
        coordinator._id.toString(),
        collegeData.routes,
        collegeData.domain,
        drivers,
      );
    }

    // 4. Seed Global Super Admin
    console.log("\n--- Seeding Global Super Admin ---");
    const password = "a"; // Fixed password for dev
    const salt = await import("bcryptjs").then((bcrypt) => bcrypt.genSalt(10));
    const passwordHash = await import("bcryptjs").then((bcrypt) =>
      bcrypt.hash(password, salt),
    );

    await User.create({
      _id: (await import("crypto")).randomUUID(),
      fullName: "System Super Admin",
      email: "super@admin.com",
      password: passwordHash,
      role: UserRole.SuperAdmin,
      approved: true,
      emailVerified: true,
    });
    console.log("Global Super Admin created: super@admin.com / password123");

    console.log("\nMASTER SEED COMPLETE");
    if (pubClient.isOpen) {
      await pubClient.disconnect();
    }
    process.exit(0);
  } catch (error) {
    console.error("Error in master seed:", error);
    if (pubClient.isOpen) {
      await pubClient.disconnect();
    }
    process.exit(1);
  }
};

runSeed();
