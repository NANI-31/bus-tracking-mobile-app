import mongoose from "mongoose";
import dotenv from "dotenv";
import User from "./models/User.model";

dotenv.config();

const checkUsers = async () => {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    console.error("MONGO_URI not found");
    process.exit(1);
  }

  try {
    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB");

    const users = await User.find({}, { fullName: 1, email: 1, role: 1 });
    console.log("USERS IN DB:", JSON.stringify(users, null, 2));

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error("Error checking users:", error);
    process.exit(1);
  }
};

checkUsers();
