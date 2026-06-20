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

export const getAllPlans = async (req: Request, res: Response) => {
  try {
    const plans = await Plan.find({}).sort({ price: 1 });
    res.status(200).json(plans);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const createPlan = async (req: Request, res: Response) => {
  try {
    const {
      name,
      alias,
      price,
      durationDays,
      features,
      isActive,
      isBestValue,
      originalPrice,
    } = req.body;

    const existingPlan = await Plan.findOne({ alias });
    if (existingPlan) {
      return res
        .status(400)
        .json({ message: `Plan with alias '${alias}' already exists.` });
    }

    const plan = new Plan({
      name,
      alias,
      price,
      durationDays,
      features: features || [],
      isActive: isActive !== undefined ? isActive : true,
      isBestValue: isBestValue !== undefined ? isBestValue : false,
      originalPrice,
    });

    await plan.save();
    res.status(201).json(plan);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const updatePlan = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      name,
      alias,
      price,
      durationDays,
      features,
      isActive,
      isBestValue,
      originalPrice,
    } = req.body;

    const plan = await Plan.findById(id);
    if (!plan) {
      return res.status(404).json({ message: "Plan not found" });
    }

    if (alias && alias !== plan.alias) {
      const existingPlan = await Plan.findOne({ alias });
      if (existingPlan) {
        return res
          .status(400)
          .json({ message: `Plan with alias '${alias}' already exists.` });
      }
    }

    plan.name = name ?? plan.name;
    plan.alias = alias ?? plan.alias;
    plan.price = price ?? plan.price;
    plan.durationDays = durationDays ?? plan.durationDays;
    plan.features = features ?? plan.features;
    plan.isActive = isActive !== undefined ? isActive : plan.isActive;
    plan.isBestValue = isBestValue !== undefined ? isBestValue : plan.isBestValue;
    plan.originalPrice = originalPrice !== undefined ? originalPrice : plan.originalPrice;

    await plan.save();
    res.status(200).json(plan);
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

export const deletePlan = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const plan = await Plan.findByIdAndDelete(id);
    if (!plan) {
      return res.status(404).json({ message: "Plan not found" });
    }
    res.status(200).json({ message: "Plan deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: (error as Error).message });
  }
};

