import mongoose, { Document, Schema } from "mongoose";

export interface INotification extends Document {
  senderId?: string;
  receiverId: string;
  message: string;
  type: string;
  timestamp: Date;
  isRead: boolean;
  data?: any;
}

const NotificationSchema: Schema = new Schema({
  senderId: { type: String, ref: "User" },
  receiverId: { type: String, required: true, ref: "User" },
  message: { type: String, required: true },
  type: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  isRead: { type: Boolean, default: false },
  data: { type: Schema.Types.Mixed },
});

export default mongoose.model<INotification>(
  "Notification",
  NotificationSchema
);
