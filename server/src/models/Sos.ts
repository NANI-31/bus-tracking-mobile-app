import mongoose, { Document, Schema } from "mongoose";

/**
 * SOS Status Enum
 */
export enum SosStatus {
  ACTIVE = "ACTIVE",
  RESOLVED = "RESOLVED",
}

/**
 * SOS Interface (Business Object)
 */
export interface ISos {
  sos_id: string;
  user_id: string;
  user_role: string;
  collegeId: string;
  bus_id: string;
  bus_number: string;
  route_id: string;
  latitude: number;
  longitude: number;
  timestamp: Date;
  status: SosStatus;
}

/**
 * SOS Document Interface (Mongoose)
 */
export interface SosDocument extends ISos, Document {}

/**
 * SOS Schema
 */
const SosSchema = new Schema<SosDocument>(
  {
    sos_id: {
      type: String,
      required: true,
      unique: true,
    },
    collegeId: {
      type: String,
      required: true,
      index: true,
    },
    user_id: {
      type: String,
      required: true,
    },
    user_role: {
      type: String,
      required: true,
      enum: ["student", "driver", "busCoordinator"],
    },
    bus_id: {
      type: String,
      required: true,
    },
    bus_number: {
      type: String,
      required: true,
    },
    route_id: {
      type: String,
      required: true,
    },
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
    status: {
      type: String,
      enum: Object.values(SosStatus),
      default: SosStatus.ACTIVE,
    },
  },
  {
    collection: "sos_alerts",
    versionKey: false,
  }
);

/**
 * SOS Model
 */
export const Sos = mongoose.model<SosDocument>("Sos", SosSchema);
