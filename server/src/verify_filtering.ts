import mongoose from "mongoose";
import dotenv from "dotenv";
import Transaction from "./models/Transaction.model";
import { getTransactions } from "./controllers/features/payment.controller";

dotenv.config({ path: "../.env" });

const MONGO_URI = process.env.MONGO_URI || "";

async function runVerification() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("Connected to MongoDB");

    // Mock Response object
    const res: any = {
      status: (code: number) => ({
        json: (data: any) => {
          console.log(`Response Status: ${code}`);
          console.log(`Transactions found: ${data.length}`);
          if (data.length > 0) {
            console.log(
              "Sample transaction:",
              JSON.stringify(data[0], null, 2),
            );
          }
        },
      }),
    };

    console.log("\n--- Testing Filter by Plan: monthly ---");
    const reqMonthly: any = {
      query: { plan: "monthly" },
      user: { role: "superAdmin" },
    };
    await getTransactions(reqMonthly, res);

    console.log("\n--- Testing Filter by Plan: semester ---");
    const reqSemester: any = {
      query: { plan: "semester" },
      user: { role: "superAdmin" },
    };
    await getTransactions(reqSemester, res);

    console.log("\n--- Testing Filter by Date Range ---");
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 7); // Last 7 days
    const reqDate: any = {
      query: { startDate: startDate.toISOString() },
      user: { role: "superAdmin" },
    };
    await getTransactions(reqDate, res);

    console.log("\n--- Testing College Admin Restriction ---");
    // Assuming we have a collegeId, but we can just test if the query is applied
    const mockCollegeId = new mongoose.Types.ObjectId();
    const reqCollegeAdmin: any = {
      query: {},
      user: { role: "collegeAdmin", collegeId: mockCollegeId },
    };
    await getTransactions(reqCollegeAdmin, res);

    await mongoose.disconnect();
    console.log("\nVerification script finished.");
  } catch (error) {
    console.error("Verification failed:", error);
    process.exit(1);
  }
}

runVerification();
