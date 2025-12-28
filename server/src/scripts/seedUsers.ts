import mongoose from "mongoose";
import dotenv from "dotenv";
import bcrypt from "bcryptjs";
import User, { UserRole } from "../models/User";
import College from "../models/College";

dotenv.config();

const seedUsers = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI as string);
    console.log("MongoDB Connected");

    const college = await College.findOne({
      name: "KKR & KSR Institute of Technology and Sciences",
    });

    if (!college) {
      console.error("College not found. Run seedColleges first.");
      process.exit(1);
    }

    const password = await bcrypt.hash("a", 10);

    const users = [
      {
        _id: new mongoose.Types.ObjectId().toString(),
        fullName: "Student User",
        email: "student@kitsguntur.ac.in",
        password: password,
        role: UserRole.Student,
        collegeId: college._id,
        phoneNumber: "1234567890",
        emailVerified: true,
        approved: true,
      },
      {
        _id: new mongoose.Types.ObjectId().toString(),
        fullName: "Driver User",
        email: "driver@kitsguntur.ac.in",
        password: password,
        role: UserRole.Driver,
        collegeId: college._id,
        phoneNumber: "1234567891",
        emailVerified: true,
        approved: true,
      },
      {
        _id: new mongoose.Types.ObjectId().toString(),
        fullName: "Coordinator User",
        email: "coordinator@kitsguntur.ac.in",
        password: password,
        role: UserRole.BusCoordinator, // Fixed Enum Case
        collegeId: college._id,
        phoneNumber: "1234567892",
        emailVerified: true,
        approved: true,
      },
      {
        _id: new mongoose.Types.ObjectId().toString(),
        fullName: "Admin User",
        email: "admin@kitsguntur.ac.in",
        password: password,
        role: UserRole.Admin,
        collegeId: college._id,
        phoneNumber: "1234567893",
        emailVerified: true,
        approved: true,
      },
    ];

    for (const userData of users) {
      const existingUser = await User.findOne({ email: userData.email });
      if (!existingUser) {
        await User.create(userData);
        console.log(`Created user: ${userData.email}`);
      } else {
        console.log(`User already exists: ${userData.email}`);
      }
    }

    process.exit();
  } catch (error) {
    console.error("Error seeding users:", error);
    process.exit(1);
  }
};

seedUsers();
