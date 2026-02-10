import mongoose, { Document, Schema } from "mongoose";

export interface IIncident extends Document {
  collegeId: string;
  busId?: string;
  driverId?: string;
  reporterId: string;
  type: "accident" | "breakdown" | "delay" | "behavior" | "other";
  description: string;
  severity: "low" | "medium" | "high" | "critical";
  status: "open" | "investigating" | "resolved";
  location?: {
    lat: number;
    lng: number;
  };
  createdAt: Date;
  updatedAt: Date;
}

const IncidentSchema: Schema = new Schema(
  {
    collegeId: { type: String, required: true, ref: "College" },
    busId: { type: String, ref: "Bus" },
    driverId: { type: String, ref: "User" },
    reporterId: { type: String, required: true, ref: "User" },
    type: {
      type: String,
      enum: ["accident", "breakdown", "delay", "behavior", "other"],
      required: true,
    },
    description: { type: String, required: true },
    severity: {
      type: String,
      enum: ["low", "medium", "high", "critical"],
      default: "medium",
    },
    status: {
      type: String,
      enum: ["open", "investigating", "resolved"],
      default: "open",
    },
    location: {
      lat: Number,
      lng: Number,
    },
  },
  { timestamps: true }
);

export const Incident = mongoose.model<IIncident>("Incident", IncidentSchema);
