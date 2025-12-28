const mongoose = require("mongoose");
const path = require("path");
const dotenv = require("dotenv");

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

    // DEBUG: List all collections
    const collections = await mongoose.connection.db
      .listCollections()
      .toArray();
    console.log("--- Existing Collections ---");
    collections.forEach((c) => console.log(` - ${c.name}`));
    console.log("----------------------------");

    // We define a temporary User model to check Mongoose mapping
    // Note: We avoid importing the TS model to prevent syntax errors in JS execution
    const userSchema = new mongoose.Schema({
      fullName: String,
      email: String,
      stopLocationGeo: {
        type: { type: String, enum: ["Point"], default: "Point" },
        coordinates: { type: [Number] },
      },
    });
    // Force naming if needed, but let's see what default does
    const User = mongoose.model("User", userSchema);

    console.log(`User model maps to collection: '${User.collection.name}'`);

    // Explicitly check for usersTree and alert
    if (collections.some((c) => c.name === "usersTree")) {
      console.warn(
        "\n!!! WARNING: 'usersTree' collection EXISTS in database! !!!"
      );
      console.warn(
        "This confirms the server error refers to a real (or view) collection."
      );

      // Try to inspect the 'usersTree' collection
      const isView =
        collections.find((c) => c.name === "usersTree").type === "view";
      console.log(`Is 'usersTree' a view? ${isView}`);

      if (!isView) {
        console.log("Attempting to fix index on 'usersTree' directly...");
        const usersTreeColl = mongoose.connection.db.collection("usersTree");
        try {
          await usersTreeColl.createIndex({ stopLocationGeo: "2dsphere" });
          console.log("SUCCESS: Created 2dsphere index on 'usersTree'!");
        } catch (e) {
          console.error("Failed to index 'usersTree':", e.message);
        }
      }
    }

    // Also fix on standard 'users' collection just in case
    if (collections.some((c) => c.name === "users")) {
      console.log("\nFixing standard 'users' collection...");
      const usersColl = mongoose.connection.db.collection("users");
      try {
        await usersColl.dropIndexes();
        console.log("Dropped indexes on 'users'");
      } catch (e) {
        console.log("Drop failed/ignored on users:", e.message);
      }

      try {
        await usersColl.createIndex({ stopLocationGeo: "2dsphere" });
        console.log("Created 2dsphere index on 'users'");
      } catch (e) {
        console.error("Create failed on users:", e.message);
      }
    }

    process.exit(0);
  } catch (error) {
    console.error("Script failed:", error);
    process.exit(1);
  }
};

fixIndexes();
