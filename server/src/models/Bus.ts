import mongoose, { Document, Schema } from "mongoose";

export interface IBus extends Document {
  busNumber: string;
  driverId: string;
  routeId?: string;
  defaultRouteId?: string;
  collegeId: string;
  isActive: boolean;
  status: "on-time" | "delayed" | "not-running";
  assignmentStatus: "unassigned" | "pending" | "accepted";
  delay?: number;
  createdAt: Date;
  updatedAt?: Date;
}

const BusSchema: Schema = new Schema({
  busNumber: { type: String, required: true },
  driverId: { type: String, required: false, ref: "User" },
  routeId: { type: Schema.Types.ObjectId, ref: "Route" },
  defaultRouteId: { type: Schema.Types.ObjectId, ref: "Route" },
  collegeId: { type: Schema.Types.ObjectId, required: true, ref: "College" },
  isActive: { type: Boolean, default: true },
  status: {
    type: String,
    enum: ["on-time", "delayed", "not-running"],
    default: "on-time",
  },
  assignmentStatus: {
    type: String,
    enum: ["unassigned", "pending", "accepted"],
    default: "unassigned",
  },
  delay: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

BusSchema.index({ collegeId: 1, busNumber: 1 }, { unique: true });
export const Bus = mongoose.model<IBus>("Bus", BusSchema);

export interface IBusLocation extends Document {
  busId: string;
  currentLocation: {
    lat: number;
    lng: number;
  };
  timestamp: Date;
  speed?: number;
  heading?: number;
}

const BusLocationSchema: Schema = new Schema({
  busId: { type: String, required: true },
  currentLocation: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  timestamp: { type: Date, default: Date.now },
  speed: { type: Number },
  heading: { type: Number },
});

export const BusLocation = mongoose.model<IBusLocation>(
  "BusLocation",
  BusLocationSchema
);
