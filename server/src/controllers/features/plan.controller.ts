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
        name: "Standard Monthly",
        alias: "standard_30",
        price: 10,
        durationDays: 30,
        features: ["Live Tracking", "Basic Alerts", "Route Viewing"],
        isActive: true,
        isBestValue: false,
      },
      {
        name: "Standard Yearly",
        alias: "standard_365",
        price: 100,
        durationDays: 365,
        features: [
          "Live Tracking",
          "Basic Alerts",
          "Route Viewing",
          "Priority Support",
        ],
        isActive: true,
        isBestValue: true,
      },
      {
        name: "Premium Monthly",
        alias: "premium_30",
        price: 20,
        durationDays: 30,
        features: [
          "Live Tracking",
          "Advanced Alerts",
          "Ad-Free Experience",
          "Route Insights",
        ],
        isActive: true,
        isBestValue: false,
      },
      {
        name: "Premium Yearly",
        alias: "premium_365",
        price: 200,
        durationDays: 365,
        features: [
          "Live Tracking",
          "Advanced Alerts",
          "Ad-Free Experience",
          "Route Insights",
          "Priority Support",
          "Family Sharing",
        ],
        isActive: true,
        isBestValue: true,
      },
    ];

    for (const planData of defaultPlans) {
      await Plan.findOneAndUpdate({ alias: planData.alias }, planData, {
        upsert: true,
        returnDocument: 'after',
      });
    }
    res
      .status(201)
      .json({ message: "Default plans seeded/updated successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};
