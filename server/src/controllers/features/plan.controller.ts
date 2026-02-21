import { Request, Response } from "express";
import Plan from "@/models/Plan.model";

export const getActivePlans = async (req: Request, res: Response) => {
  try {
    const plans = await Plan.find({ isActive: true }).sort({ price: 1 });
    res.status(200).json(plans);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const seedPlans = async (req: Request, res: Response) => {
  try {
    const count = await Plan.countDocuments();
    if (count > 0) {
      return res.status(400).json({ message: "Plans already seeded" });
    }

    const defaultPlans = [
      {
        name: "Monthly Premium",
        alias: "monthly",
        price: 1,
        durationDays: 30,
        features: ["Live Tracking", "Basic Alerts"],
        isActive: true,
        isBestValue: false,
      },
      {
        name: "Semester Premium",
        alias: "semester",
        price: 2,
        durationDays: 180,
        features: ["Priority Support", "Route Insights", "Ad-Free"],
        isActive: true,
        isBestValue: true,
      },
    ];

    await Plan.insertMany(defaultPlans);
    res.status(201).json({ message: "Default plans seeded successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
