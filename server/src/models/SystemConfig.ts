import mongoose, { Document, Schema } from "mongoose";

export interface ISystemConfig extends Document {
  key: string;
  value: any;
  description?: string;
  dataType: string;
  isPublic: boolean;
  isEditable: boolean;
  category?: string;
  updatedAt: Date;
  updatedBy?: string;
}

const SystemConfigSchema: Schema = new Schema({
  key: { type: String, required: true, unique: true },
  value: { type: Schema.Types.Mixed, required: true },
  description: { type: String },
  dataType: {
    type: String,
    enum: ["string", "boolean", "number", "json", "email", "url"],
    default: "string",
  },
  isPublic: { type: Boolean, default: false },
  isEditable: { type: Boolean, default: true },
  category: { type: String, index: true },
  updatedAt: { type: Date, default: Date.now },
  updatedBy: { type: String, ref: "User" },
});

export default mongoose.model<ISystemConfig>(
  "SystemConfig",
  SystemConfigSchema,
);
