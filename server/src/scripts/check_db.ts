import mongoose from "mongoose";
import dotenv from "dotenv";
import User from "../models/User.model";

dotenv.config();

const run = async () => {
  try {
    const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/collegebus";
    await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 5000,
      connectTimeoutMS: 5000,
    });
    console.log("Connected to DB");

    const t1 = await User.findOne({ email: "t1@kkr.ac.in" });
    const c = await User.findOne({ email: "c@kkr.ac.in" });

    console.log("t1@kkr.ac.in:", t1 ? { id: t1._id, role: t1.role, collegeId: t1.collegeId } : "not found");
    console.log("c@kkr.ac.in:", c ? { id: c._id, role: c.role, collegeId: c.collegeId } : "not found");

    await mongoose.disconnect();
  } catch (err) {
    console.error(err);
  }
};

run();
