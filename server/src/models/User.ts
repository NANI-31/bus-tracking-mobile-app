import mongoose, { Document, Schema } from "mongoose";

export enum UserRole {
  Student = "student",
  Teacher = "teacher",
  Driver = "driver",
  BusCoordinator = "busCoordinator",
  Admin = "admin",
  Parent = "parent",
}

export enum UserLanguage {
  English = "en",
  Hindi = "hi",
  Telugu = "te",
}

export interface IUser extends Document {
  fullName: string;
  email?: string;
  password: string;
  otp?: string;
  otpExpires?: Date;
  role: string;
  collegeId: string;
  approved: boolean;
  emailVerified: boolean;
  needsManualApproval: boolean;
  approverId?: string;
  createdAt: Date;
  updatedAt?: Date;
  phoneNumber?: string;
  rollNumber?: string;
  preferredStop?: string;
  fcmToken?: string;
  language: string;
  routeId?: string;
  stopId?: string;
  stopName?: string;
  stopLocation?: {
    lat: number;
    lng: number;
  };
  lastNearbyNotifiedBusId?: string;
  stopLocationGeo?: {
    type: string;
    coordinates: number[]; // [lng, lat]
  };
}

const UserSchema: Schema = new Schema({
  _id: { type: String, required: true },
  fullName: { type: String, required: true },
  email: { type: String, required: false, unique: true, sparse: true }, // Optional & Sparse
  password: { type: String, required: true },
  otp: { type: String },
  otpExpires: { type: Date },
  role: {
    type: String,
    required: true,
    enum: ["student", "teacher", "driver", "busCoordinator", "admin", "parent"],
    default: UserRole.Student,
  },
  collegeId: { type: Schema.Types.ObjectId, required: true, ref: "College" },
  approved: { type: Boolean, default: false },
  emailVerified: { type: Boolean, default: false },
  needsManualApproval: { type: Boolean, default: false },
  approverId: { type: String, ref: "User" },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
  phoneNumber: { type: String },
  rollNumber: { type: String },
  preferredStop: { type: String },
  fcmToken: { type: String },
  language: {
    type: String,
    enum: ["en", "hi", "te"],
    default: UserLanguage.English,
  },
  routeId: { type: Schema.Types.ObjectId, ref: "Route", index: true },
  stopId: { type: String },
  stopName: { type: String },
  stopLocation: {
    lat: Number,
    lng: Number,
  },
  lastNearbyNotifiedBusId: { type: String },
  stopLocationGeo: {
    type: { type: String, enum: ["Point"] }, // Remove default to prevent partial objects
    coordinates: { type: [Number] }, // [lng, lat]
  },
});

// Index for geospatial queries
UserSchema.index({ stopLocationGeo: "2dsphere" }, { sparse: true });

// Pre-save hook to sync stopLocation -> stopLocationGeo
UserSchema.pre<IUser>("save", function (next) {
  if (this.stopLocation && this.stopLocation.lat && this.stopLocation.lng) {
    this.stopLocationGeo = {
      type: "Point",
      coordinates: [this.stopLocation.lng, this.stopLocation.lat],
    };
  } else if (!this.stopLocationGeo?.coordinates?.length) {
    // Ensure we don't save an invalid Partial object
    this.stopLocationGeo = undefined;
  }
  next();
});

export default mongoose.model<IUser>("User", UserSchema);
