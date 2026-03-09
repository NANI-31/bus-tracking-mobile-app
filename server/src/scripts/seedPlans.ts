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

    const defaultPlans = [
      {
        name: "Monthly Premium",
        alias: "monthly",
        price: 20,
        durationDays: 30,
        features: ["Live Tracking", "Basic Alerts"],
        isActive: true,
        isBestValue: false,
      },
      {
        name: "Semester Premium",
        alias: "semester",
        price: 40,
        durationDays: 120,
        features: ["Priority Support", "Route Insights", "Ad-Free"],
        isActive: true,
        isBestValue: true,
      },
    ];

    // UPDATED: UPSERT PLANS INSTEAD OF JUST INSERTING IF EMPTY
    for (const planData of defaultPlans) {
      await Plan.findOneAndUpdate({ alias: planData.alias }, planData, {
        upsert: true,
        new: true,
      });
    }
    console.log("Plans updated/seeded successfully");
    process.exit(0);
  } catch (error) {
    console.error("Error seeding plans:", error);
    process.exit(1);
  }
};

seedPlans();
