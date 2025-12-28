import mongoose from "mongoose";
import dotenv from "dotenv";
import College from "../models/College";

dotenv.config();

const seedColleges = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI as string);
    console.log("MongoDB Connected");

    const collegeName = "KKR & KSR Institute of Technology and Sciences";
    const existingCollege = await College.findOne({ name: collegeName });

    if (!existingCollege) {
      const college = new College({
        name: collegeName,
        allowedDomains: ["kitsguntur.ac.in"],
        verified: true,
        busNumbers: ["BUS001", "BUS002", "BUS003", "BUS004", "BUS005"],
        createdBy: new mongoose.Types.ObjectId().toString(), // Dummy Admin ID
      });

      await college.save();
      console.log("College seeded successfully");
    } else {
      console.log("College already exists");
    }

    process.exit();
  } catch (error) {
    console.error("Error seeding colleges:", error);
    process.exit(1);
  }
};

seedColleges();
