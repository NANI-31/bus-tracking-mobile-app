console.log("Starting master seed script...");
import mongoose from "mongoose";
import dotenv from "dotenv";
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
  const mongoUri =
    "mongodb+srv://nani:nani@cluster0.nkgeayy.mongodb.net/college_bus_tracking?retryWrites=true&w=majority";

  try {
    console.log("Connecting to MongoDB...");
    await mongoose.connect(mongoUri);

    console.log("Clearing all existing data...");
    await College.deleteMany({});
    await User.deleteMany({});
    await Route.deleteMany({});
    await Bus.deleteMany({});
    await Schedule.deleteMany({});

    for (const collegeData of collegesData) {
      console.log(`\n--- Seeding ${collegeData.name} ---`);

      // 0. Pre-generate 15 Bus Numbers
      const busNumbers = Array.from(
        { length: 15 },
        (_, i) =>
          `${collegeData.shortName}-${(i + 1).toString().padStart(2, "0")}`
      );

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
        collegeData.shortName
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
        drivers
      );
    }

    console.log("\nMASTER SEED COMPLETE");
    process.exit(0);
  } catch (error) {
    console.error("Error in master seed:", error);
    process.exit(1);
  }
};

runSeed();
