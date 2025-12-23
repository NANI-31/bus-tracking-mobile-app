import mongoose from "mongoose";
import User from "./models/User";
import dotenv from "dotenv";

dotenv.config();

const testVerify = async () => {
  try {
    const mongoUri =
      process.env.MONGO_URI ||
      "mongodb+srv://nani:nani@cluster0.nkgeayy.mongodb.net/college_bus_tracking?retryWrites=true&w=majority";
    await mongoose.connect(mongoUri);

    // Create a dummy user
    const testId = "test_verification_user_" + Date.now();
    const user = new User({
      _id: testId,
      fullName: "Test User",
      email: `test${Date.now()}@example.com`,
      role: "student",
      collegeId: "test_college",
      approved: false,
      emailVerified: false,
    });
    await user.save();
    console.log("Created test user:", testId);

    // Now verify it via Mongoose direct call to simulate controller logic
    const updated = await User.findByIdAndUpdate(
      testId,
      { emailVerified: true },
      { new: true }
    );

    console.log("Updated user:", updated);

    // Cleanup
    await User.findByIdAndDelete(testId);
    console.log("Cleaned up");
    process.exit(0);
  } catch (e) {
    console.error("Error:", e);
    process.exit(1);
  }
};

testVerify();
