import mongoose from "mongoose";
import dotenv from "dotenv";
import Transaction from "./models/Transaction.model";

dotenv.config({ path: "./.env" }); // Running from server root

const MONGO_URI = process.env.MONGO_URI || "";

async function seed() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("Connected to MongoDB for seeding");

    const college1 = new mongoose.Types.ObjectId();
    const college2 = new mongoose.Types.ObjectId();
    const user1 = new mongoose.Types.ObjectId();

    const transactions = [
      {
        userId: user1,
        collegeId: college1,
        orderId: "order_001",
        paymentId: "pay_001",
        amount: 1,
        plan: "monthly",
        premiumUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        status: "captured",
      },
      {
        userId: user1,
        collegeId: college1,
        orderId: "order_002",
        paymentId: "pay_002",
        amount: 2,
        plan: "semester",
        premiumUntil: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000),
        status: "captured",
      },
      {
        userId: user1,
        collegeId: college2,
        orderId: "order_003",
        paymentId: "pay_003",
        amount: 1,
        plan: "monthly",
        premiumUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        status: "captured",
      },
    ];

    await Transaction.deleteMany({
      orderId: { $in: ["order_001", "order_002", "order_003"] },
    });
    await Transaction.insertMany(transactions);
    console.log("Seeded 3 test transactions.");

    await mongoose.disconnect();
  } catch (error) {
    console.error("Seeding failed:", error);
    process.exit(1);
  }
}

seed();
