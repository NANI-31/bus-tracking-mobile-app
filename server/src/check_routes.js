const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

// Correct path to .env in the parent directory
dotenv.config({ path: path.join(__dirname, "..", ".env") });

const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("MONGO_URI not found in .env");
  process.exit(1);
}

async function checkRoutes() {
  try {
    console.log("Connecting to:", MONGO_URI.substring(0, 50) + "...");
    await mongoose.connect(MONGO_URI);
    console.log("Connected to MongoDB");

    const collection = mongoose.connection.collection("routes");
    const routes = await collection.find({}).toArray();

    console.log("Routes count:", routes.length);
    if (routes.length > 0) {
      console.log("Sample route fields:", Object.keys(routes[0]));
      console.log("Sample route content:", JSON.stringify(routes[0], null, 2));
    }

    await mongoose.connection.close();
  } catch (err) {
    console.error("Error:", err);
  }
}

checkRoutes();
