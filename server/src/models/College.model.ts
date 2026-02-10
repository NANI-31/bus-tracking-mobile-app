import mongoose, { Document, Schema } from "mongoose";

export interface ICollege extends Document {
  name: string;
  allowedDomains: string[];
  verified: boolean;
  busNumbers: string[];
  adminId?: string;
  suspended: boolean;
  suspensionReason?: string;
  settings?: Map<string, any>;
  shiftCount: number;
  shifts: {
    shiftId: string;
    name: string;
    pickupTime: string;
    dropTime: string;
  }[];
  createdBy: string;
  createdAt: Date;
  updatedAt?: Date;
}

const CollegeSchema: Schema = new Schema({
  name: { type: String, required: true },
  allowedDomains: [{ type: String }],
  verified: { type: Boolean, default: false },
  busNumbers: [{ type: String, default: [] }],
  adminId: { type: String, ref: "User" },
  suspended: { type: Boolean, default: false },
  suspensionReason: { type: String },
  settings: { type: Map, of: Schema.Types.Mixed, default: {} },
  shiftCount: { type: Number, default: 1 },
  shifts: [
    {
      shiftId: { type: String, required: true },
      name: { type: String, required: true },
      pickupTime: { type: String },
      dropTime: { type: String },
    },
  ],
  createdBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

export default mongoose.model<ICollege>("College", CollegeSchema);
