import mongoose from "mongoose";
import dotenv from "dotenv";
import path from "path";
import Plan from "../models/Plan.model";

dotenv.config({ path: path.join(__dirname, "../../.env") });

const MONGO_URI =
  process.env.MONGO_URI || "mongodb://localhost:27017/college_bus_tracking";

const defaultPlans = [
  {
    name: "Standard Monthly",
    alias: "standard_30",
    price: 10,
    durationDays: 30,
    features: ["Live Tracking", "Basic Alerts", "Route Viewing"],
    isActive: true,
    isBestValue: false,
  },
  {
    name: "Standard Yearly",
    alias: "standard_365",
    price: 100,
    durationDays: 365,
    features: [
      "Live Tracking",
      "Basic Alerts",
      "Route Viewing",
      "Priority Support",
    ],
    isActive: true,
    isBestValue: true,
  },
  {
    name: "Premium Monthly",
    alias: "premium_30",
    price: 20,
    durationDays: 30,
    features: [
      "Live Tracking",
      "Advanced Alerts",
      "Ad-Free Experience",
      "Route Insights",
    ],
    isActive: true,
    isBestValue: false,
  },
  {
    name: "Premium Yearly",
    alias: "premium_365",
    price: 200,
    durationDays: 365,
    features: [
      "Live Tracking",
      "Advanced Alerts",
      "Ad-Free Experience",
      "Route Insights",
      "Priority Support",
      "Family Sharing",
    ],
    isActive: true,
    isBestValue: true,
  },
];

async function seed() {
  try {
    console.log("Connecting to MongoDB...");
    await mongoose.connect(MONGO_URI);
    console.log("Connected successfully.");

    console.log("Seeding payment plans...");
    for (const planData of defaultPlans) {
      const plan = await Plan.findOneAndUpdate(
        { alias: planData.alias },
        planData,
        { upsert: true, new: true },
      );
      console.log(`✅ Seeded: ${plan.name} (${plan.alias})`);
    }

    console.log("\nSuccess: All payment plans have been seeded!");
    process.exit(0);
  } catch (error) {
    console.error("Error seeding plans:", error);
    process.exit(1);
  }
}

seed();
