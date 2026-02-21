import { IAuthRequest } from "@/types";
import AuditLog from "@/models/AuditLog.model";
import logger from "@/utils/logger";

interface LogParams {
  req: IAuthRequest;
  action: string;
  resource: string;
  resourceId: any;
  resourceName?: string;
  previousState?: any;
  newState?: any;
  collegeId?: string;
}

export class AuditService {
  /**
   * Log an administrative or significant system action
   */
  public static async log({
    req,
    action,
    resource,
    resourceId,
    resourceName,
    previousState,
    newState,
    collegeId,
  }: LogParams) {
    try {
      const logData = {
        userId: req.user?.id,
        userEmail: req.user?.email,
        userName: req.user?.fullName || "System Admin",
        collegeId: collegeId || req.user?.collegeId,
        action,
        resource,
        resourceId: String(resourceId),
        resourceName,
        previousState,
        newState,
        ipAddress:
          req.ip || req.headers["x-forwarded-for"] || req.socket.remoteAddress,
        userAgent: req.headers["user-agent"],
        createdAt: new Date(),
      };

      const newLog = await AuditLog.create(logData);
      const logObj = newLog.toObject();

      // Emit Live Log via Socket
      try {
        const { getIO } = require("../socket");
        const io = getIO();

        // 1. Emit to Super Admins (Global)
        io.to("global_audit_logs").emit("new_audit_log", logObj);
        logger.debug("[Socket] Emitted to global_audit_logs");

        // 2. Emit to specific College Admins
        if (logData.collegeId) {
          const room = `${logData.collegeId}_audit_logs`;
          io.to(room).emit("new_audit_log", logObj);
          logger.debug(`[Socket] Emitted to college room: ${room}`);
        }
      } catch (socketErr) {
        logger.warn("Audit log created but live emit failed", socketErr);
      }

      logger.info(
        `Audit Log Created: ${action} on ${resource} (${resourceId}) by ${logData.userEmail}`,
      );
    } catch (error) {
      // We don't want audit logging failures to crash the main request flow,
      // but we definitely want to log it for troubleshooting.
      logger.error("Failed to create audit log entry", {
        error,
        action,
        resource,
        userId: req.user?.id,
      });
    }
  }
}
