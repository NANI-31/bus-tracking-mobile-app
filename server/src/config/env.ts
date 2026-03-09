/**
 * Environment Variable Validation
 *
 * Validates all required environment variables on server startup
 * to prevent runtime failures due to missing configuration.
 */
import dotenv from "dotenv";
dotenv.config();

const REQUIRED_VARS = ["JWT_SECRET", "REFRESH_TOKEN_SECRET", "MONGO_URI"];

// Optional but recommended for production
const RECOMMENDED_VARS = [
  "REDIS_URL",
  "AWS_ACCESS_KEY_ID",
  "AWS_SECRET_ACCESS_KEY",
  "AWS_BUCKET_NAME",
  "RAZORPAY_KEY_ID",
  "RAZORPAY_KEY_SECRET",
];

export function validateEnv(): void {
  const missing: string[] = [];

  for (const v of REQUIRED_VARS) {
    if (!process.env[v]) {
      missing.push(v);
    }
  }

  if (missing.length > 0) {
    throw new Error(
      `❌ Missing REQUIRED environment variables:\n  ${missing.join("\n  ")}\n\nPlease set them in your .env file.`,
    );
  }

  // JWT_SECRET strength check
  if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
    console.warn(
      "⚠️  WARNING: JWT_SECRET should be at least 32 characters for security.",
    );
  }

  // Warn about missing recommended vars (non-fatal)
  if (process.env.NODE_ENV === "production") {
    const missingRecommended = RECOMMENDED_VARS.filter((v) => !process.env[v]);
    if (missingRecommended.length > 0) {
      console.warn(
        `⚠️  Missing recommended environment variables for production:\n  ${missingRecommended.join("\n  ")}`,
      );
    }
  }

  // Ensure NODE_ENV is explicitly set
  if (!process.env.NODE_ENV) {
    console.warn(
      '⚠️  NODE_ENV is not set. Defaulting to "development". Set to "production" for deployment.',
    );
    process.env.NODE_ENV = "development";
  }
}
