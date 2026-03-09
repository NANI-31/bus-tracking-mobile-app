import mongoose from "mongoose";
import { createClient } from "redis";
import { S3Client, ListObjectsV2Command } from "@aws-sdk/client-s3";
import dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.join(__dirname, "../.env") });

async function debugSSL() {
  console.log("--- Starting SSL Debug ---");

  // 1. Test Redis
  console.log("\n[1/3] Testing Redis...");
  try {
    const redisUrl = process.env.REDIS_URL || "";
    const useTLS = redisUrl.startsWith("rediss://");
    const redisClient = createClient({
      url: redisUrl,
      socket: useTLS ? { tls: true, rejectUnauthorized: true } : undefined,
    });
    await redisClient.connect();
    const info = await redisClient.info("memory");
    console.log("✅ Redis Connected and Info retrieved");
    await redisClient.disconnect();
  } catch (err) {
    console.error("❌ Redis Error:", err);
  }

  // 2. Test S3
  console.log("\n[2/3] Testing S3...");
  try {
    const s3Client = new S3Client({
      region: process.env.AWS_REGION || "ap-south-1",
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
      },
    });
    const command = new ListObjectsV2Command({
      Bucket: process.env.S3_BUCKET_NAME,
      MaxKeys: 1,
    });
    await s3Client.send(command);
    console.log("✅ S3 Connected and Listing successful");
  } catch (err) {
    console.error("❌ S3 Error:", err);
  }

  // 3. Test MongoDB
  console.log("\n[3/3] Testing MongoDB...");
  try {
    const uri = process.env.MONGO_URI || "";
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
    console.log("✅ MongoDB Connected");
    if (mongoose.connection.db) {
      const stats = await mongoose.connection.db.stats();
      console.log("✅ MongoDB Stats retrieved");
    }
    await mongoose.disconnect();
  } catch (err) {
    console.error("❌ MongoDB Error:", err);
  }

  console.log("\n--- Debug Finished ---");
}

debugSSL().catch(console.error);
