console.log("Starting master seed script...");
import mongoose from "mongoose";
import dotenv from "dotenv";
import { kkrKsrTransportData } from "./seedData/routesData";
import { seedColleges } from "./seeds/collegeSeed";
import { seedUsers } from "./seeds/userSeed";
import { seedTransport } from "./seeds/transportSeed";
import { UserRole } from "./models/User";

dotenv.config();

const runSeed = async () => {
  const mongoUri =
    "mongodb+srv://nani:nani@cluster0.nkgeayy.mongodb.net/college_bus_tracking?retryWrites=true&w=majority";

  try {
    console.log("Connecting to MongoDB...");
    await mongoose.connect(mongoUri);

    // 1. Seed College
    const college = await seedColleges({
      name: kkrKsrTransportData.collegeName,
      domains: ["kkr.ac.in"],
    });

    // 2. Seed Users
    // Users are created with specific string UUIDs in seedUsers.ts
    const users = await seedUsers(college._id.toString());
    const coordinator = users.find((u) => u.role === UserRole.BusCoordinator);

    if (!coordinator) {
      throw new Error("Coordinator not found after seeding users");
    }

    // 3. Seed Transport (Routes, Buses, Schedules)
    await seedTransport(
      college._id.toString(),
      coordinator._id.toString(),
      kkrKsrTransportData.routes
    );

    console.log("MASTER SEED COMPLETE");
    process.exit(0);
  } catch (error) {
    console.error("Error in master seed:", error);
    process.exit(1);
  }
};

runSeed();
