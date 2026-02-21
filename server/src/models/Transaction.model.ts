import mongoose, { Document, Schema } from "mongoose";

export interface ITransaction extends Document {
  userId: string;
  collegeId: mongoose.Types.ObjectId;
  orderId: string;
  paymentId: string;
  amount: number;
  currency: string;
  plan: string;
  premiumUntil: Date;
  status: string;
  paymentMethod?: string;
  createdAt: Date;
  updatedAt: Date;
}

const TransactionSchema: Schema = new Schema(
  {
    userId: {
      type: String,
      ref: "User",
      required: true,
      index: true,
    },
    collegeId: {
      type: Schema.Types.ObjectId,
      ref: "College",
      required: true,
      index: true,
    },
    orderId: { type: String, required: true, unique: true, index: true },
    paymentId: { type: String, required: true, unique: true, index: true },
    amount: { type: Number, required: true },
    currency: { type: String, default: "INR" },
    plan: { type: String, required: true },
    premiumUntil: { type: Date, required: true },
    status: { type: String, default: "captured" },
    paymentMethod: { type: String },
  },
  { timestamps: true },
);

export default mongoose.model<ITransaction>("Transaction", TransactionSchema);
