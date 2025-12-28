const mongoose = require("mongoose");
const path = require("path");
const dotenv = require("dotenv");

dotenv.config({ path: path.resolve(__dirname, "../.env") });

const fixIndexesBlind = async () => {
  try {
    const uri = process.env.MONGO_URI;
    console.log("Connecting to MongoDB...");
    const maskedUri = uri.replace(/:([^:@]+)@/, ":****@");
    console.log(`URI: ${maskedUri}`);

    await mongoose.connect(uri);
    console.log("Connected.");

    const db = mongoose.connection.db;

    // 1. Fix 'usersTree' - blindly
    console.log("Attempting to create index on 'usersTree'...");
    try {
      await db
        .collection("usersTree")
        .createIndex({ stopLocationGeo: "2dsphere" });
      console.log("SUCCESS: Created index on 'usersTree'");
    } catch (e) {
      console.log("Failed usersTree:", e.message);
    }

    // 2. Fix 'users' - blindly
    console.log("Attempting to create index on 'users'...");
    try {
      await db.collection("users").createIndex({ stopLocationGeo: "2dsphere" });
      console.log("SUCCESS: Created index on 'users'");
    } catch (e) {
      console.log("Failed users:", e.message);
    }

    process.exit(0);
  } catch (error) {
    console.error("Script failed:", error);
    process.exit(1);
  }
};

fixIndexesBlind();
