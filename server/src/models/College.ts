import mongoose, { Document, Schema } from "mongoose";

export interface ICollege extends Document {
  name: string;
  allowedDomains: string[];
  verified: boolean;
  busNumbers: string[];
  createdBy: string;
  createdAt: Date;
  updatedAt?: Date;
}

const CollegeSchema: Schema = new Schema({
  name: { type: String, required: true },
  allowedDomains: [{ type: String }],
  verified: { type: Boolean, default: false },
  busNumbers: [{ type: String, default: [] }],
  createdBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

export default mongoose.model<ICollege>("College", CollegeSchema);
