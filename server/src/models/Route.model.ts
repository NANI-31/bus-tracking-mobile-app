import mongoose, { Document, Schema } from "mongoose";

export interface IRoute extends Document {
  routeName: string;
  routeType: string;
  startPoint: {
    name: string;
    location: { lat: number; lng: number };
  };
  endPoint: {
    name: string;
    location: { lat: number; lng: number };
  };
  stopPoints: {
    name: string;
    location: { lat: number; lng: number };
  }[];
  collegeId: string;
  createdBy: string;
  isActive: boolean;
  directions?: {
    polylinePoints: { latitude: number; longitude: number }[];
    totalDistanceKm: number;
    totalDurationMin: number;
    legs: {
      startAddress: string;
      endAddress: string;
      distanceKm: number;
      durationMin: number;
    }[];
  };
  createdAt: Date;
  updatedAt?: Date;
  color?: string;
}

const RouteSchema: Schema = new Schema({
  routeName: { type: String, required: true },
  routeType: { type: String, enum: ["pickup", "drop"], default: "pickup" },
  startPoint: {
    name: { type: String, required: true },
    location: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
    },
  },
  endPoint: {
    name: { type: String, required: true },
    location: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
    },
  },
  stopPoints: [
    {
      name: { type: String, required: true },
      location: {
        lat: { type: Number, required: true },
        lng: { type: Number, required: true },
      },
    },
  ],
  collegeId: { type: Schema.Types.ObjectId, required: true, ref: "College" },
  createdBy: { type: String, required: true, ref: "User" },
  isActive: { type: Boolean, default: true },
  color: { type: String, default: "#1E90FF" },
  directions: {
    polylinePoints: [
      {
        latitude: { type: Number },
        longitude: { type: Number },
        _id: false,
      },
    ],
    totalDistanceKm: { type: Number },
    totalDurationMin: { type: Number },
    legs: [
      {
        startAddress: { type: String },
        endAddress: { type: String },
        distanceKm: { type: Number },
        durationMin: { type: Number },
        _id: false,
      },
    ],
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

export default mongoose.model<IRoute>("Route", RouteSchema);
