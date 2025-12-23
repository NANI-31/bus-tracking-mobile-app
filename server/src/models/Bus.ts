import mongoose, { Document, Schema } from "mongoose";

export interface IBus extends Document {
  busNumber: string;
  driverId: string;
  routeId?: string;
  collegeId: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt?: Date;
}

const BusSchema: Schema = new Schema({
  busNumber: { type: String, required: true },
  driverId: { type: String, required: true },
  routeId: { type: String },
  collegeId: { type: String, required: true },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

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
