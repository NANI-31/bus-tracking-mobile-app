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
  createdAt: Date;
  updatedAt?: Date;
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
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

export default mongoose.model<IRoute>("Route", RouteSchema);
