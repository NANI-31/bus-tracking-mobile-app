import mongoose from "mongoose";
import dotenv from "dotenv";
import path from "path";
import User from "./models/User";

// Explicitly load .env from current directory
dotenv.config({ path: path.resolve(__dirname, "../.env") });

const fixIndexes = async () => {
  try {
    const uri = process.env.MONGO_URI;
    if (!uri) {
      throw new Error("MONGO_URI is undefined. Check .env file.");
    }

    console.log("Connecting to MongoDB...");
    const maskedUri = uri.replace(/:([^:@]+)@/, ":****@");
    console.log(`Target Database URI: ${maskedUri}`);
    await mongoose.connect(uri);
    console.log("Connected to MongoDB");
    const db = mongoose.connection.db;
    if (!db) {
      throw new Error("MongoDB connection established but db is undefined");
    }

    // DEBUG: List all collections
    const collections = await db.listCollections().toArray();
    console.log("--- Existing Collections ---");
    collections.forEach((c) => console.log(` - ${c.name}`));
    console.log("----------------------------");

    console.log(`User model maps to collection: '${User.collection.name}'`);

    // Drop existing indexes to ensure clean slate
    try {
      await User.collection.dropIndexes();
      console.log(`Dropped all indexes on ${User.collection.name} collection`);
    } catch (e: any) {
      console.log("Drop indexes warning (might be safe to ignore):", e.message);
    }

    // Create the geospatial index explicitly
    try {
      await User.collection.createIndex({ stopLocationGeo: "2dsphere" });
      console.log("Created 2dsphere index on stopLocationGeo");
    } catch (e: any) {
      console.error("Failed to create 2dsphere index:", e);
      throw e;
    }

    // Create other necessary indexes from schema
    await User.createIndexes();
    console.log("Re-created all schema indexes");

    // Explicitly check for usersTree and alert
    if (collections.some((c) => c.name === "usersTree")) {
      console.warn(
        "\n!!! WARNING: 'usersTree' collection EXISTS in database! !!!"
      );
      console.warn(
        "If the app is querying this, but User model maps to 'users', then there is a MISMATCH."
      );
    }

    process.exit(0);
  } catch (error) {
    console.error("Index fix failed:", error);
    process.exit(1);
  }
};

fixIndexes();
