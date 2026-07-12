import mongoose, { Document, Schema } from "mongoose";

export interface ITeacherOverrideRequest extends Document {
  teacherId: string;
  busId: any;
  collegeId: any;
  status: "pending" | "approved" | "rejected" | "ended";
  createdAt: Date;
  updatedAt?: Date;
}

const TeacherOverrideRequestSchema: Schema = new Schema({
  teacherId: { type: String, ref: "User", required: true },
  busId: { type: Schema.Types.ObjectId, ref: "Bus", required: true },
  collegeId: { type: Schema.Types.ObjectId, ref: "College", required: true },
  status: {
    type: String,
    enum: ["pending", "approved", "rejected", "ended"],
    default: "pending",
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
});

export const TeacherOverrideRequest = mongoose.model<ITeacherOverrideRequest>(
  "TeacherOverrideRequest",
  TeacherOverrideRequestSchema,
);
