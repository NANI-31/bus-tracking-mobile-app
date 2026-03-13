import dotenv from "dotenv";
import path from "path";
dotenv.config();

import mongoose from "mongoose";
import jwt from "jsonwebtoken";
import fs from "fs";
import User, { UserRole } from "../../src/models/User.model";
import { Bus } from "../../src/models/Bus.model";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error("JWT_SECRET is not defined in .env file!");
  process.exit(1);
}
console.log("Using JWT_SECRET for token generation.");
const OUTPUT_FILE = path.join(__dirname, "tokens.csv");
const NUM_DRIVERS = 20;
const NUM_STUDENTS = 100;

async function generateTokens() {
  try {
    const mongoUri = process.env.MONGO_URI;
    if (!mongoUri) throw new Error("MONGO_URI is missing");

    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB...");

    // Fetch drivers and their associated college/bus info
    const drivers = await User.find({ role: UserRole.Driver } as any).limit(NUM_DRIVERS);
    const students = await User.find({ role: UserRole.Student } as any).limit(NUM_STUDENTS);

    if (drivers.length === 0 || students.length === 0) {
      console.warn("Not enough drivers/students found in DB. Please run seeding first.");
      process.exit(1);
    }

    const csvLines: string[] = ["token,role,collegeId,busId"];

    // Generate tokens for drivers
    for (const driver of drivers) {
      const bus = await Bus.findOne({ driverId: driver._id.toString() } as any);
      const payload = {
        id: driver._id.toString(),
        role: driver.role,
        collegeId: (driver.collegeId as any).toString(),
      };
      const token = jwt.sign(payload, JWT_SECRET as string);
      csvLines.push(`${token},driver,${(driver.collegeId as any).toString()},${bus ? bus._id.toString() : ""}`);
    }

    // Generate tokens for students
    for (const student of students) {
      const payload = {
        id: student._id.toString(),
        role: student.role,
        collegeId: (student.collegeId as any).toString(),
      };
      const token = jwt.sign(payload, JWT_SECRET as string);
      csvLines.push(`${token},student,${(student.collegeId as any).toString()},`);
    }

    fs.writeFileSync(OUTPUT_FILE, csvLines.join("\n"));
    console.log(`Successfully generated ${csvLines.length - 1} tokens in ${OUTPUT_FILE}`);

    await mongoose.disconnect();
  } catch (err) {
    console.error("Error generating tokens:", err);
    process.exit(1);
  }
}

generateTokens();
