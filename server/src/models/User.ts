import mongoose, { Document, Schema } from "mongoose";

export enum UserRole {
  Student = "student",
  Teacher = "teacher",
  Driver = "driver",
  BusCoordinator = "busCoordinator",
  Admin = "admin",
  Parent = "parent", // Added
}

export interface IUser extends Document {
  fullName: string;
  email?: string; // Optional
  password: string;
  otp?: string;
  otpExpires?: Date;
  role: string;
  collegeId: string;
  approved: boolean;
  emailVerified: boolean;
  needsManualApproval: boolean;
  approverId?: string;
  createdAt: Date;
  updatedAt?: Date;
  phoneNumber?: string;
  rollNumber?: string;
}

const UserSchema: Schema = new Schema({
  _id: { type: String, required: true },
  fullName: { type: String, required: true },
  email: { type: String, required: false, unique: true, sparse: true }, // Optional & Sparse
  password: { type: String, required: true },
  otp: { type: String },
  otpExpires: { type: Date },
  role: {
    type: String,
    required: true,
    enum: ["student", "teacher", "driver", "busCoordinator", "admin", "parent"],
    default: UserRole.Student,
  },
  collegeId: { type: Schema.Types.ObjectId, required: true, ref: "College" },
  approved: { type: Boolean, default: false },
  emailVerified: { type: Boolean, default: false },
  needsManualApproval: { type: Boolean, default: false },
  approverId: { type: String, ref: "User" },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
  phoneNumber: { type: String },
  rollNumber: { type: String },
});

export default mongoose.model<IUser>("User", UserSchema);
