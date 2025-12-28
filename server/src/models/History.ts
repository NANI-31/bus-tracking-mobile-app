import mongoose, { Document, Schema } from "mongoose";

export interface IHistory extends Document {
  collegeId: string;
  busId?: string;
  driverId?: string;
  eventType: string; // 'assignment_update', 'incident_report', 'sos_alert', 'trip_status', 'other'
  description: string;
  metadata?: any; // Flexible JSON for specific event details
  timestamp: Date;
}

const HistorySchema: Schema = new Schema(
  {
    collegeId: { type: String, required: true, ref: "College" },
    busId: { type: String, ref: "Bus", index: true },
    driverId: { type: String, ref: "User", index: true },
    eventType: { type: String, required: true, index: true },
    description: { type: String, required: true },
    metadata: { type: Schema.Types.Mixed },
    timestamp: { type: Date, default: Date.now, index: true },
  },
  { timestamps: true }
);

// Compound indexes for common queries
HistorySchema.index({ collegeId: 1, timestamp: -1 });
HistorySchema.index({ busId: 1, timestamp: -1 });
HistorySchema.index({ driverId: 1, timestamp: -1 });

export const History = mongoose.model<IHistory>("History", HistorySchema);
