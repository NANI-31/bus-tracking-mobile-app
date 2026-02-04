import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config();

const MONGO_URI =
  process.env.MONGO_URI || "mongodb://localhost:27017/college_bus_tracking";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const connectDB = async (retries = 10, delayMs = 5000) => {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const conn = await mongoose.connect(MONGO_URI, {
        serverSelectionTimeoutMS: 5000, // Fail after 5 seconds
      });
      console.log(`MongoDB Connected: ${conn.connection.host}`);
      return conn;
    } catch (error) {
      console.error(
        `❌ MongoDB connection failed (${attempt}/${retries}): ${
          (error as Error).message
        }`,
      );
      if (attempt < retries) {
        console.log(
          `⏳Retrying in ${delayMs / 1000}s... (${attempt}/${retries})\n`,
        );
        await sleep(delayMs);
      } else {
        // console.error("❌ Max retries reached. Exiting...");
        console.error(`
=====================================
🚨 SERVER STOPPED 🚨

MongoDB connection failed.
Check:
• Atlas IP whitelist
• Internet connection
• MONGO_URI

👉 FIX THE ISSUE AND PRESS "r" + ENTER
=====================================
`);
        // process.stdout.write("\x07"); // terminal bell 🔔
        process.exit(1);
      }
    }
  }
};

export default connectDB;
