const mongoose = require('mongoose');

const MONGO_URI = "mongodb://nani:nani@ac-qb3lmd3-shard-00-00.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-01.nkgeayy.mongodb.net:27017,ac-qb3lmd3-shard-00-02.nkgeayy.mongodb.net:27017/college_bus_tracking?ssl=true&replicaSet=atlas-gktisf-shard-0&authSource=admin&appName=Cluster0";

const planSchema = new mongoose.Schema({
  name: String,
  alias: String,
  price: Number,
  durationDays: Number,
  features: [String],
  isActive: Boolean,
  isBestValue: Boolean,
});

const Plan = mongoose.models.Plan || mongoose.model('Plan', planSchema);

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

async function seedPlans() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("Connected to DB. Seeding plans...");
    
    for (const planData of defaultPlans) {
      await Plan.findOneAndUpdate({ alias: planData.alias }, planData, {
        upsert: true,
        new: true,
      });
    }
    
    console.log("Plans seeded successfully.");
  } catch (error) {
    console.error("Error seeding plans:", error);
  } finally {
    await mongoose.disconnect();
    console.log("Disconnected from DB.");
  }
}

seedPlans();
