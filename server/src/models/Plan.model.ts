import mongoose, { Schema, Document } from "mongoose";

export interface IPlan extends Document {
  name: string;
  alias: string; // unique identifier (e.g., 'monthly', 'semester')
  price: number; // in INR
  durationDays: number;
  features: string[];
  isActive: boolean;
  isBestValue: boolean;
  originalPrice?: number; // for showing discounts
}

const PlanSchema: Schema = new Schema(
  {
    name: { type: String, required: true },
    alias: { type: String, required: true, unique: true },
    price: { type: Number, required: true },
    durationDays: { type: Number, required: true },
    features: { type: [String], default: [] },
    isActive: { type: Boolean, default: true },
    isBestValue: { type: Boolean, default: false },
    originalPrice: { type: Number },
  },
  { timestamps: true },
);

export default mongoose.model<IPlan>("Plan", PlanSchema);
