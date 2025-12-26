import mongoose, { Document, Schema } from "mongoose";

export interface IBusAssignmentLog extends Document {
  busId: string;
  driverId: string;
  routeId?: string;
  assignedAt: Date;
  acceptedAt?: Date;
  completedAt?: Date;
  status: "pending" | "accepted" | "rejected" | "completed";
}

const BusAssignmentLogSchema: Schema = new Schema({
  busId: { type: String, required: true, ref: "Bus" },
  driverId: { type: String, required: true, ref: "User" },
  routeId: { type: Schema.Types.ObjectId, ref: "Route" },
  assignedAt: { type: Date, default: Date.now },
  acceptedAt: { type: Date },
  completedAt: { type: Date },
  status: {
    type: String,
    enum: ["pending", "accepted", "rejected", "completed"],
    default: "pending",
  },
});

export const BusAssignmentLog = mongoose.model<IBusAssignmentLog>(
  "BusAssignmentLog",
  BusAssignmentLogSchema
);
