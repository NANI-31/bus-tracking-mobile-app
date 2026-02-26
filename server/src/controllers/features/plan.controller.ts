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
    const defaultPlans = [
      {
        name: "Monthly Premium",
        alias: "monthly",
        price: 10,
        durationDays: 30,
        features: ["Live Tracking", "Basic Alerts"],
        isActive: true,
        isBestValue: false,
      },
      {
        name: "Extended Premium (4 Months)",
        alias: "semester",
        price: 20,
        durationDays: 120,
        features: ["Priority Support", "Route Insights", "Ad-Free"],
        isActive: true,
        isBestValue: true,
      },
    ];

    for (const planData of defaultPlans) {
      await Plan.findOneAndUpdate({ alias: planData.alias }, planData, {
        upsert: true,
        new: true,
      });
    }
    res
      .status(201)
      .json({ message: "Default plans seeded/updated successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
