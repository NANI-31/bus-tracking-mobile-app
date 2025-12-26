import { checkAndNotifyBusNearby } from "../src/utils/busNearbyLogic";
import User from "../src/models/User";
import mongoose from "mongoose";

// Mock Mongoose setup if needed, or just import logic to test syntax
// Ideally this spins up a test DB context, but for quick verify we check compilation
console.log("Analyzing busNearbyLogic for compilation errors...");

// Only strictly needed part;
const test = async () => {
  try {
    await checkAndNotifyBusNearby("bus123", "AP01", 17.0, 78.0, "routeId123");
    console.log("Logic executed (simulated)");
  } catch (e) {
    console.error(e);
  }
};

test();
