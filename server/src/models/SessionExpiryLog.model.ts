import mongoose, { Document, Schema } from "mongoose";

// ─── Enums ────────────────────────────────────────────────────────────────────

/**
 * The root cause that triggered the session expiry event.
 * TOKEN_EXPIRED        – JWT TTL elapsed (TokenExpiredError from jsonwebtoken)
 * TOKEN_VERSION_MISMATCH – Token's tokenVersion doesn't match DB (global logout)
 * USER_DELETED         – User account no longer exists in the DB
 * REFRESH_TOKEN_FAILED – Refresh token itself was expired/invalid
 * SOCKET_AUTH_FAILED   – Socket.IO handshake rejected due to auth error
 * NO_TOKEN             – Request arrived with no Authorization header at all
 * INVALID_TOKEN        – Malformed JWT (JsonWebTokenError)
 */
export enum SessionExpiryReason {
  TokenExpired = "TOKEN_EXPIRED",
  TokenVersionMismatch = "TOKEN_VERSION_MISMATCH",
  UserDeleted = "USER_DELETED",
  RefreshTokenFailed = "REFRESH_TOKEN_FAILED",
  SocketAuthFailed = "SOCKET_AUTH_FAILED",
  NoToken = "NO_TOKEN",
  InvalidToken = "INVALID_TOKEN",
}

// ─── Interface ─────────────────────────────────────────────────────────────────

export interface ISessionExpiryLog extends Document {
  // Who
  userId?: string;
  userEmail?: string;
  userRole?: string;
  collegeId?: any;

  // Why
  reason: SessionExpiryReason;
  errorName?: string;    // e.g. "TokenExpiredError", "JsonWebTokenError"
  errorMessage?: string; // Raw error.message from jsonwebtoken

  // Token forensics
  tokenIssuedAt?: Date;   // decoded.iat → tells you how old the token was
  tokenExpiredAt?: Date;  // decoded.exp → exact expiry timestamp
  tokenAgeSeconds?: number; // convenience: expiredAt - issuedAt
  tokenVersion?: number;  // version embedded in the token
  dbTokenVersion?: number; // version stored in DB at time of rejection

  // Request context
  requestEndpoint?: string; // e.g. "/api/buses"
  requestMethod?: string;   // GET, POST, etc.
  clientIp?: string;

  // Client context (set via X-App-Platform / X-App-Version headers)
  platform?: string;  // "android" | "ios" | "web"
  appVersion?: string;

  // When
  occurredAt: Date;

  // TTL index field – documents auto-delete after 90 days
  expiresAt: Date;
}

// ─── Schema ───────────────────────────────────────────────────────────────────

const SessionExpiryLogSchema: Schema = new Schema(
  {
    // Who
    userId: { type: String, index: true },
    userEmail: { type: String },
    userRole: { type: String, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: "College", index: true },

    // Why
    reason: {
      type: String,
      required: true,
      enum: Object.values(SessionExpiryReason),
      index: true,
    },
    errorName: { type: String },
    errorMessage: { type: String },

    // Token forensics
    tokenIssuedAt: { type: Date },
    tokenExpiredAt: { type: Date },
    tokenAgeSeconds: { type: Number },
    tokenVersion: { type: Number },
    dbTokenVersion: { type: Number },

    // Request context
    requestEndpoint: { type: String },
    requestMethod: { type: String },
    clientIp: { type: String },

    // Client context
    platform: { type: String },
    appVersion: { type: String },

    // When
    occurredAt: { type: Date, default: Date.now, index: true },

    // Auto-expiry after 90 days (TTL index)
    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    },
  },
  { collection: "sessionexpirylogs" },
);

// Compound index for dashboard queries: filter by college + date range
SessionExpiryLogSchema.index({ collegeId: 1, occurredAt: -1 });
// Compound index for per-user history
SessionExpiryLogSchema.index({ userId: 1, occurredAt: -1 });
// TTL – MongoDB deletes documents automatically 90 days after occurredAt
SessionExpiryLogSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export default mongoose.model<ISessionExpiryLog>(
  "SessionExpiryLog",
  SessionExpiryLogSchema,
);
