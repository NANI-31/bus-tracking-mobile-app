import mongoose, { Schema, Document } from "mongoose";

export interface IBusNumber extends Document {
  collegeId: string;
  busNumber: string;
  createdAt: Date;
}

const BusNumberSchema: Schema = new Schema({
  collegeId: { type: String, required: true },
  busNumber: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

// Compound index to ensure unique bus numbers per college
BusNumberSchema.index({ collegeId: 1, busNumber: 1 }, { unique: true });

export default mongoose.model<IBusNumber>("BusNumber", BusNumberSchema);
