import mongoose from "mongoose";
import dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.join(__dirname, ".env") });

const MONGO_URI =
  process.env.MONGO_URI || "mongodb://localhost:27017/bus-tracking";

async function checkColleges() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("Connected to MongoDB");

    const collection = mongoose.connection.collection("colleges");
    const colleges = await collection.find({}).toArray();

    console.log("Colleges count:", colleges.length);
    if (colleges.length > 0) {
      console.log("Sample college:", JSON.stringify(colleges[0], null, 2));
    }

    await mongoose.connection.close();
  } catch (err) {
    console.error("Error:", err);
  }
}

checkColleges();
