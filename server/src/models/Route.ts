import mongoose, { Document, Schema } from "mongoose";

export interface IRoute extends Document {
  routeName: string;
  routeType: string;
  startPoint: string;
  endPoint: string;
  stopPoints: string[];
  collegeId: string;
  createdBy: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt?: Date;
}

const RouteSchema: Schema = new Schema({
  routeName: { type: String, required: true },
  routeType: { type: String, enum: ["pickup", "drop"], default: "pickup" },
  startPoint: { type: String, required: true },
  endPoint: { type: String, required: true },
  stopPoints: [{ type: String }],
  collegeId: { type: String, required: true },
  createdBy: { type: String, required: true },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

export default mongoose.model<IRoute>("Route", RouteSchema);
