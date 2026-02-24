import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { Upload } from "@aws-sdk/lib-storage";
import logger from "@/utils/logger";
import fs from "fs";

/**
 * S3 Service - Handles audio file storage on AWS S3
 */
class S3Service {
  private client: S3Client;
  private bucketName: string;

  constructor() {
    this.bucketName = process.env.S3_BUCKET_NAME || "";
    this.client = new S3Client({
      region: process.env.AWS_REGION || "ap-south-1",
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
      },
    });
  }

  /**
   * Uploads a file to S3
   * @param filePath Local path to the file
   * @param key S3 Object Key
   * @param mimetype Content Type
   */
  async uploadFile(
    filePath: string,
    key: string,
    mimetype: string,
  ): Promise<string> {
    try {
      const fileStream = fs.createReadStream(filePath);
      const upload = new Upload({
        client: this.client,
        params: {
          Bucket: this.bucketName,
          Key: key,
          Body: fileStream,
          ContentType: mimetype,
        },
      });

      await upload.done();
      logger.info(`[S3Service] Successfully uploaded: ${key}`);
      return key;
    } catch (error) {
      logger.error(`[S3Service] Upload failed for ${key}:`, error);
      throw error;
    }
  }

  /**
   * Generates a pre-signed URL for temporary access
   * @param key S3 Object Key
   * @param expiresIn Seconds until expiration (default 1 hour)
   */
  async generatePresignedUrl(
    key: string,
    expiresIn: number = 3600,
  ): Promise<string> {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      const url = await getSignedUrl(this.client, command, { expiresIn });
      return url;
    } catch (error) {
      logger.error(
        `[S3Service] Presigned URL generation failed for ${key}:`,
        error,
      );
      throw error;
    }
  }
}

export const s3Service = new S3Service();
