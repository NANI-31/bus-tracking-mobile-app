import mongoose, { Document, Schema } from "mongoose";

export interface IMetricSnapshot extends Document {
  collegeId: mongoose.Types.ObjectId;
  date: Date;
  counts: {
    users: number;
    buses: number;
    transactions: number;
    notifications: number;
    auditLogs: number;
  };
  estimatedStorageMB: number;
  createdAt: Date;
}

const MetricSnapshotSchema: Schema = new Schema({
  collegeId: {
    type: Schema.Types.ObjectId,
    ref: "College",
    required: true,
    index: true,
  },
  date: {
    type: Date,
    required: true,
    index: true,
  },
  counts: {
    users: { type: Number, default: 0 },
    buses: { type: Number, default: 0 },
    transactions: { type: Number, default: 0 },
    notifications: { type: Number, default: 0 },
    auditLogs: { type: Number, default: 0 },
  },
  estimatedStorageMB: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
});

// Compound index for efficient range queries per college
MetricSnapshotSchema.index({ collegeId: 1, date: 1 });

export default mongoose.model<IMetricSnapshot>(
  "MetricSnapshot",
  MetricSnapshotSchema,
);
