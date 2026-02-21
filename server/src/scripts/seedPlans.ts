import mongoose from "mongoose";
import dotenv from "dotenv";
import Plan from "../models/Plan.model";

dotenv.config();

const seedPlans = async () => {
  try {
    const mongoUri = process.env.MONGO_URI || "";
    if (!mongoUri) {
      console.error("MONGO_URI not found in .env");
      process.exit(1);
    }

    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB");

    const count = await Plan.countDocuments();
    if (count > 0) {
      console.log("Plans already exist. Skipping seed.");
      process.exit(0);
    }

    const defaultPlans = [
      {
        name: "Monthly Premium",
        alias: "monthly",
        price: 1,
        durationDays: 30,
        features: ["Live Tracking", "Basic Alerts"],
        isActive: true,
        isBestValue: false,
      },
      {
        name: "Semester Premium",
        alias: "semester",
        price: 2,
        durationDays: 180,
        features: ["Priority Support", "Route Insights", "Ad-Free"],
        isActive: true,
        isBestValue: true,
      },
    ];

    await Plan.insertMany(defaultPlans);
    console.log("Default plans seeded successfully");
    process.exit(0);
  } catch (error) {
    console.error("Error seeding plans:", error);
    process.exit(1);
  }
};

seedPlans();
