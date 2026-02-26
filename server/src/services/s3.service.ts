import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  DeleteObjectsCommand,
  ListObjectsV2Command,
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
  /**
   * Deletes a file from S3
   * @param key S3 Object Key
   */
  async deleteFile(key: string): Promise<boolean> {
    try {
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      await this.client.send(command);
      logger.info(`[S3Service] Successfully deleted: ${key}`);
      return true;
    } catch (error) {
      logger.error(`[S3Service] Deletion failed for ${key}:`, error);
      return false;
    }
  }

  /**
   * Calculates bucket statistics (total size and object count)
   * @param prefix Optional prefix to filter objects (e.g. for a specific college)
   */
  async getBucketStats(prefix?: string): Promise<{
    totalSize: number;
    objectCount: number;
  }> {
    try {
      let totalSize = 0;
      let objectCount = 0;
      let isTruncated = true;
      let continuationToken: string | undefined;

      while (isTruncated) {
        const command = new ListObjectsV2Command({
          Bucket: this.bucketName,
          Prefix: prefix,
          ContinuationToken: continuationToken,
        });

        const response = await this.client.send(command);
        if (response.Contents) {
          for (const item of response.Contents) {
            totalSize += item.Size || 0;
            objectCount++;
          }
        }
        isTruncated = response.IsTruncated || false;
        continuationToken = response.NextContinuationToken;
      }

      return { totalSize, objectCount };
    } catch (error) {
      logger.error(`[S3Service] Failed to fetch bucket stats:`, error);
      return { totalSize: 0, objectCount: 0 };
    }
  }

  /**
   * Clears all objects in the S3 bucket
   */
  async clearBucket(): Promise<void> {
    try {
      logger.info(`[S3Service] Attempting to clear bucket: ${this.bucketName}`);
      let isTruncated = true;
      let continuationToken: string | undefined;

      while (isTruncated) {
        const listCommand = new ListObjectsV2Command({
          Bucket: this.bucketName,
          ContinuationToken: continuationToken,
        });

        const response = await this.client.send(listCommand);

        if (response.Contents && response.Contents.length > 0) {
          const keys = response.Contents.map((item) => ({ Key: item.Key! }));
          const deleteCommand = new DeleteObjectsCommand({
            Bucket: this.bucketName,
            Delete: { Objects: keys },
          });

          await this.client.send(deleteCommand);
          logger.info(`[S3Service] Deleted ${keys.length} objects`);
        }

        isTruncated = response.IsTruncated || false;
        continuationToken = response.NextContinuationToken;
      }
      logger.info(
        `[S3Service] Successfully cleared bucket: ${this.bucketName}`,
      );
    } catch (error) {
      logger.error(`[S3Service] Failed to clear bucket:`, error);
      throw error;
    }
  }
}

export const s3Service = new S3Service();
