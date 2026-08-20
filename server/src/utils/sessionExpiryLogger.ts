/**
 * sessionExpiryLogger.ts
 *
 * Fire-and-forget helper. Call this from authMiddleware, refresh.ts, and
 * socketAuth.ts without awaiting — it never throws and never blocks the
 * response path.
 *
 * Usage:
 *   logSessionExpiry({
 *     reason: SessionExpiryReason.TokenExpired,
 *     decoded,
 *     dbUser: user,
 *     error,
 *     req,
 *   });
 */

import { Request } from "express";
import SessionExpiryLog, {
  SessionExpiryReason,
} from "@/models/SessionExpiryLog.model";
import logger from "@/utils/logger";

// Re-export enum so callers only need one import
export { SessionExpiryReason };

export interface SessionExpiryContext {
  reason: SessionExpiryReason;
  /** Decoded JWT payload (may be partial / undefined if token is totally invalid) */
  decoded?: any;
  /** User document fetched from DB during auth check (undefined if user not found) */
  dbUser?: any;
  /** The raw error thrown by jsonwebtoken (undefined for non-error paths) */
  error?: any;
  /** Express Request object — used for endpoint, method, IP, headers */
  req?: Request;
  /** For socket events where no Express req exists */
  socketMeta?: {
    platform?: string;
    appVersion?: string;
    clientIp?: string;
  };
}

export function logSessionExpiry(ctx: SessionExpiryContext): void {
  // Intentionally not awaited — log asynchronously and never block the caller
  _writeLog(ctx).catch((err) => {
    // Log the write failure but never surface it to the caller
    logger.error(`[SessionExpiryLogger] Failed to write log: ${err.message}`);
  });
}

async function _writeLog(ctx: SessionExpiryContext): Promise<void> {
  const { reason, decoded, dbUser, error, req, socketMeta } = ctx;

  // ── Token forensics ───────────────────────────────────────────────────────
  let tokenIssuedAt: Date | undefined;
  let tokenExpiredAt: Date | undefined;
  let tokenAgeSeconds: number | undefined;

  if (decoded?.iat) {
    tokenIssuedAt = new Date(decoded.iat * 1000);
  }
  if (decoded?.exp) {
    tokenExpiredAt = new Date(decoded.exp * 1000);
  }
  if (tokenIssuedAt && tokenExpiredAt) {
    tokenAgeSeconds = Math.round(
      (tokenExpiredAt.getTime() - tokenIssuedAt.getTime()) / 1000,
    );
  }

  // ── Client context (X-App-Platform / X-App-Version headers) ──────────────
  const platform =
    socketMeta?.platform ||
    (req?.headers["x-app-platform"] as string) ||
    undefined;

  const appVersion =
    socketMeta?.appVersion ||
    (req?.headers["x-app-version"] as string) ||
    undefined;

  const clientIp =
    socketMeta?.clientIp ||
    (req?.ip) ||
    (req?.headers["x-forwarded-for"] as string) ||
    undefined;

  await SessionExpiryLog.create({
    // Who
    userId: decoded?.id || undefined,
    userEmail: decoded?.email || undefined,
    userRole: decoded?.role || undefined,
    collegeId: decoded?.collegeId || undefined,

    // Why
    reason,
    errorName: error?.name || undefined,
    errorMessage: error?.message || undefined,

    // Token forensics
    tokenIssuedAt,
    tokenExpiredAt,
    tokenAgeSeconds,
    tokenVersion: decoded?.tokenVersion ?? undefined,
    dbTokenVersion: dbUser?.tokenVersion ?? undefined,

    // Request context
    requestEndpoint: req?.path || undefined,
    requestMethod: req?.method || undefined,
    clientIp,

    // Client context
    platform,
    appVersion,

    occurredAt: new Date(),
  });
}
