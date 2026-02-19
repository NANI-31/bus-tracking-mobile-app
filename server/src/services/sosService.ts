import { Server } from "socket.io";
import { v4 as uuidv4 } from "uuid";
import { Sos, SosStatus, ISos } from "../models/Sos.model";
import User from "../models/User.model";
import { Bus } from "../models/Bus.model";
import { sendSosNotification } from "../utils/firebase";
import logger from "../utils/logger";
import AuditLog from "../models/AuditLog.model";

interface TriggerSosParams {
  userId: string;
  userRole: string;
  collegeId: string;
  busId?: string;
  routeId?: string;
  location: { lat: number; lng: number };
}

export class SosService {
  private io: Server;

  constructor(io: Server) {
    this.io = io;
  }

  async triggerSos(params: TriggerSosParams): Promise<ISos> {
    const { userId, userRole, collegeId, busId, routeId, location } = params;

    const sosId = `SOS-${uuidv4().substring(0, 8).toUpperCase()}`;

    const bus = busId ? await Bus.findById(busId) : null;
    const busNumber = bus ? bus.busNumber : busId || "N/A";

    const newSos = new Sos({
      sos_id: sosId,
      collegeId: collegeId,
      user_id: userId,
      user_role: userRole,
      bus_id: busId || "N/A",
      bus_number: busNumber,
      route_id: routeId || "N/A",
      latitude: location.lat,
      longitude: location.lng,
      timestamp: new Date(),
      status: SosStatus.ACTIVE,
    });

    await newSos.save();

    // Broadcast via Socket.IO to coordinators only
    const coordRoom = `${collegeId}_coordinators`;
    this.io.to(coordRoom).emit("sos_alert", newSos);
    this.io.to("global_sos").emit("sos_alert", newSos); // Global broadcast for Super Admins
    logger.info(
      `[Socket] SOS alert broadcasted to coordinator room: ${coordRoom} and global room`,
    );

    // Send Firebase Notifications to Coordinators and College Admins
    await this.sendSosNotifications(
      collegeId,
      userRole,
      busNumber,
      sosId,
      userId,
      busId,
      location,
    );

    logger.info(`SOS triggered: ${sosId} by ${userId}`);

    // Log to Audit Trail
    try {
      await AuditLog.create({
        userId: userId,
        userEmail: "system@sos",
        userName: userRole,
        action: "SOS_ALERT_CREATED",
        resource: "SOS",
        resourceId: sosId,
        newState: {
          sosId: sosId,
          busId: busId,
          routeId: routeId,
          location: location,
        },
        collegeId: collegeId,
        ipAddress: "SYSTEM",
      });
    } catch (auditError) {
      logger.error("Failed to create audit log for SOS trigger", auditError);
    }

    return newSos;
  }

  async resolveSos(
    sosId: string,
    resolutionNotes: string,
    resolvedByApiKey: string,
  ): Promise<ISos> {
    const sos = await Sos.findOneAndUpdate(
      { sos_id: sosId },
      {
        status: SosStatus.RESOLVED,
        resolvedAt: new Date(),
        resolvedBy: resolvedByApiKey,
        resolutionNotes: resolutionNotes || "Resolved by administrator",
      },
      { new: true },
    );

    if (!sos) {
      throw new Error("SOS alert not found");
    }

    // Broadcast resolution via Socket.IO to coordinators/admins
    if (sos.collegeId) {
      const coordRoom = `${sos.collegeId}_coordinators`;
      this.io.to(coordRoom).emit("sos_resolved", { sos_id: sosId });
      this.io.to("global_sos").emit("sos_resolved", { sos_id: sosId }); // Global broadcast
    }

    logger.info(`SOS resolved: ${sosId} by ${resolvedByApiKey}`);

    // Log to Audit Trail
    try {
      await AuditLog.create({
        userId: resolvedByApiKey,
        userEmail: "system@sos",
        userName: "Administrator",
        action: "SOS_RESOLVED",
        resource: "SOS",
        resourceId: sosId,
        newState: {
          sosId: sosId,
          resolutionNotes: resolutionNotes,
        },
        collegeId: sos.collegeId,
        ipAddress: "SYSTEM",
      });
    } catch (auditError) {
      logger.error("Failed to create audit log for SOS resolution", auditError);
    }

    return sos;
  }

  async getActiveSos(
    collegeId: string,
    queryFilters: any,
    userRole: string,
  ): Promise<ISos[]> {
    const query: any = {};

    if (collegeId !== "all") {
      query.collegeId = collegeId;
    } else if (userRole !== "superAdmin") {
      throw new Error("Access denied");
    }

    // Merge additional filters
    Object.assign(query, queryFilters);

    const alerts = await Sos.find(query).sort({ timestamp: -1 });
    return alerts;
  }

  private async sendSosNotifications(
    collegeId: string,
    userRole: string,
    busNumber: string,
    sosId: string,
    userId: string,
    busId: string | undefined,
    location: { lat: number; lng: number },
  ) {
    try {
      const targetAdmins = await User.find({
        collegeId,
        role: { $in: ["busCoordinator", "collegeAdmin"] },
        fcmToken: { $exists: true, $ne: null },
      });

      const tokens = targetAdmins
        .map((c) => c.fcmToken)
        .filter((t): t is string => !!t);

      if (tokens.length > 0) {
        await sendSosNotification(
          tokens,
          "🚨 SOS Alert!",
          `Emergency reported by ${userRole}. Bus: ${busNumber}`,
          {
            type: "SOS",
            sos_id: sosId,
            bus_id: busId || "",
            bus_number: busNumber,
            user_id: userId,
            lat: location.lat.toString(),
            lng: location.lng.toString(),
          },
        );
      }
    } catch (error) {
      logger.error("Failed to send SOS FCM notifications", error);
      // Don't throw here, as SOS creation should effectively succeed even if notifs fail
    }
  }
}

let sosServiceInstance: SosService | null = null;

export const getSosService = (io: Server): SosService => {
  if (!sosServiceInstance) {
    sosServiceInstance = new SosService(io);
  }
  return sosServiceInstance;
};
