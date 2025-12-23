console.log("Starting seed script...");
import mongoose from "mongoose";
import dotenv from "dotenv";
import College from "./models/College";

dotenv.config();

const seedColleges = async () => {
  try {
    const mongoUri =
      "mongodb+srv://nani:nani@cluster0.nkgeayy.mongodb.net/college_bus_tracking?retryWrites=true&w=majority";
    console.log("Connecting to MongoDB...");
    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB");

    // Clear existing colleges
    await College.deleteMany({});
    console.log("Cleared existing colleges");

    const colleges = [
      {
        name: "R.V.R. & J.C. College of Engineering",
        allowedDomains: ["rvrjc.ac.in", "rvrjcce.ac.in"],
        verified: true,
        createdBy: "SYSTEM_SEED",
      },
      {
        name: "Vignan's University",
        allowedDomains: ["vignan.ac.in"],
        verified: true,
        createdBy: "SYSTEM_SEED",
      },
      {
        name: "Vasireddy Venkatadri Institute of Technology",
        allowedDomains: ["vvit.net"],
        verified: true,
        createdBy: "SYSTEM_SEED",
      },
    ];

    await College.insertMany(colleges);
    console.log("Colleges seeded successfully");
    process.exit(0);
  } catch (error) {
    console.error("Error seeding colleges:", error);
    process.exit(1);
  }
};

seedColleges();
