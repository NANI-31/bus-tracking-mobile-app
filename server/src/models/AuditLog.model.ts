import mongoose, { Document, Schema } from "mongoose";

export interface IAuditLog extends Document {
  userId: string;
  userEmail: string;
  userName: string;
  action: string;
  resource: string;
  resourceId: string;
  resourceName?: string;
  previousState?: any;
  newState?: any;
  ipAddress?: string;
  userAgent?: string;
  collegeId?: string;
  createdAt: Date;
}

const AuditLogSchema: Schema = new Schema({
  userId: { type: String, required: true, index: true },
  userEmail: { type: String, required: true },
  userName: { type: String, required: true },
  action: { type: String, required: true, index: true },
  resource: { type: String, required: true, index: true },
  resourceId: { type: String, required: true, index: true },
  resourceName: { type: String },
  previousState: { type: Schema.Types.Mixed },
  newState: { type: Schema.Types.Mixed },
  ipAddress: { type: String },
  userAgent: { type: String },
  collegeId: { type: Schema.Types.ObjectId, ref: "College", index: true },
  createdAt: { type: Date, default: Date.now, index: true },
});

export default mongoose.model<IAuditLog>("AuditLog", AuditLogSchema);
