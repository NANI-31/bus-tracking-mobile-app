import mongoose from "mongoose";
import dotenv from "dotenv";
import User from "../models/User.model";
import College from "../models/College.model";
import { Bus } from "../models/Bus.model";
import logger from "../utils/logger";

dotenv.config();

const fixCollegeIds = async () => {
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    console.error("MONGO_URI not defined");
    process.exit(1);
  }

  try {
    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB");

    const users = await User.find({ role: { $ne: "superAdmin" } });
    console.log(`Checking ${users.length} users...`);

    for (const user of users) {
      if (user.collegeId && !mongoose.Types.ObjectId.isValid(user.collegeId)) {
        console.log(
          `Found invalid collegeId for user ${user.email}: ${user.collegeId}`,
        );

        // Try to find a college with this name (formatted)
        const collegeName = user.collegeId
          .split("_")
          .map((word: string) => word.charAt(0).toUpperCase() + word.slice(1))
          .join(" ");

        let college = await College.findOne({ name: collegeName });

        if (!college) {
          console.log(`Creating new college: ${collegeName}`);
          college = new College({
            name: collegeName,
            allowedDomains: user.email ? [user.email.split("@")[1]] : [],
            createdBy: "migration_script",
            verified: true, // Auto-verify existing migrated colleges
          });
          await college.save();
        }

        user.collegeId = college._id.toString();
        await user.save();
        console.log(
          `Updated user ${user.email} with collegeId: ${college._id}`,
        );
      }
    }

    const buses = await Bus.find();
    console.log(`Checking ${buses.length} buses...`);

    for (const bus of buses) {
      if (bus.collegeId && !mongoose.Types.ObjectId.isValid(bus.collegeId)) {
        console.log(
          `Found invalid collegeId for bus ${bus.busNumber}: ${bus.collegeId}`,
        );

        const collegeName = bus.collegeId
          .split("_")
          .map((word: string) => word.charAt(0).toUpperCase() + word.slice(1))
          .join(" ");

        let college = await College.findOne({ name: collegeName });

        if (college) {
          bus.collegeId = college._id.toString();
          await bus.save();
          console.log(
            `Updated bus ${bus.busNumber} with collegeId: ${college._id}`,
          );
        } else {
          console.warn(
            `No matching college found for bus slug: ${bus.collegeId}`,
          );
        }
      }
    }

    console.log("Migration complete");
    process.exit(0);
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  }
};

fixCollegeIds();
