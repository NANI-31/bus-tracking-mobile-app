import mongoose, { Document, Schema } from "mongoose";

export interface IStopSchedule {
  stopName: string;
  arrivalTime: string;
  departureTime: string;
}

export interface ISchedule extends Document {
  routeId: string;
  busId: string;
  shift: string;
  tripType: "pickup" | "drop";
  stopSchedules: IStopSchedule[];
  collegeId: string;
  createdBy: string;
  createdAt: Date;
  updatedAt?: Date;
  isActive: boolean;
}

const StopScheduleSchema: Schema = new Schema(
  {
    stopName: { type: String, required: true },
    arrivalTime: {
      type: String,
      required: true,
    },
    departureTime: {
      type: String,
      required: true,
    },
  },
  { _id: false },
);

const ScheduleSchema: Schema = new Schema({
  routeId: { type: Schema.Types.ObjectId, required: true, ref: "Route" },
  busId: { type: Schema.Types.ObjectId, required: true, ref: "Bus" },
  shift: { type: String, required: true },
  tripType: { type: String, enum: ["pickup", "drop"], default: "pickup" },
  stopSchedules: [StopScheduleSchema],
  collegeId: { type: Schema.Types.ObjectId, required: true, ref: "College" },
  createdBy: { type: String, required: true, ref: "User" },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
  isActive: { type: Boolean, default: true },
});

export default mongoose.model<ISchedule>("Schedule", ScheduleSchema);
