import { Bus, IBus } from "@/models/Bus.model";
import { BusAssignmentLog } from "@/models/BusAssignmentLog.model";
import User, { UserRole } from "@/models/User.model";
import { sendTemplatedNotificationHelper } from "@/controllers/features/notification.controller";
import { logHistoryHelper } from "@/controllers/transport/history.controller";
import { NOTIFICATION_TYPES } from "@/constants/notificationTypes";
import logger from "@/utils/logger";

/**
 * BusAssignmentService - Encapsulates logic for bus assignments and route changes.
 */
export class BusAssignmentService {
  /**
   * Handle all assignment-related state changes
   */
  async handleAssignmentChanges(
    oldBus: IBus,
    updatedBus: IBus,
    updateData: Partial<IBus>,
    requestingUserName?: string,
  ): Promise<void> {
    const newStatus = updateData.assignmentStatus;
    const oldStatus = oldBus.assignmentStatus;

    // New assignment (pending)
    if (this.isNewAssignment(oldBus, updateData)) {
      await this.handleNewAssignment(updatedBus, requestingUserName);
    }

    // Assignment accepted
    if (newStatus === "accepted" && oldStatus === "pending") {
      await this.handleAcceptedAssignment(updatedBus);
    }

    // Assignment rejected
    if (newStatus === "unassigned" && oldStatus === "pending") {
      await this.handleRejectedAssignment(oldBus, updatedBus);
    }

    // Trip completed
    if (newStatus === "unassigned" && oldStatus === "accepted") {
      await this.handleTripCompletion(oldBus, updatedBus);
    }

    // Route changed (or assigned for the first time)
    if (this.isRouteChange(oldBus, updateData)) {
      await this.handleRouteChange(updatedBus);
    }
  }

  /**
   * Check if the route has changed
   */
  private isRouteChange(oldBus: IBus, updateData: Partial<IBus>): boolean {
    return (
      !!updateData.routeId &&
      updateData.routeId.toString() !== oldBus.routeId?.toString()
    );
  }

  /**
   * Handle route change notifications
   */
  private async handleRouteChange(bus: IBus): Promise<void> {
    // If assigned back to default, do nothing as per user request
    if (bus.routeId?.toString() === bus.defaultRouteId?.toString()) {
      logger.info(
        `Bus ${bus.busNumber} assigned to its default route. No notification needed.`,
      );
      return;
    }

    logger.info(
      `Bus ${bus.busNumber} assigned to non-default route ${bus.routeId}. Sending notifications.`,
    );

    // Find all users associated with this route
    const usersToNotify = await User.find({
      routeId: bus.routeId,
      role: { $in: [UserRole.Student, UserRole.Parent, UserRole.Teacher] },
      fcmToken: { $exists: true, $ne: null },
    });

    if (usersToNotify.length === 0) {
      logger.info(`No users found to notify for route ${bus.routeId}`);
      return;
    }

    // Send notifications to each user
    for (const user of usersToNotify) {
      try {
        await sendTemplatedNotificationHelper(
          user._id.toString(),
          NOTIFICATION_TYPES.ROUTE_CHANGE,
          {
            busNumber: bus.busNumber,
            routeName: "assigned route", // We could fetch actual route name if needed
          },
        );
      } catch (err) {
        logger.error(`Failed to notify user ${user._id}: ${err}`);
      }
    }

    // Log to history
    await logHistoryHelper(
      bus.collegeId.toString(),
      "route_assignment_change",
      `Bus ${bus.busNumber} assigned to a temporary route.`,
      { routeId: bus.routeId },
      bus._id.toString(),
    );
  }

  /**
   * Check if this is a new assignment
   */
  private isNewAssignment(oldBus: IBus, updateData: Partial<IBus>): boolean {
    return (
      updateData.assignmentStatus === "pending" &&
      (oldBus.assignmentStatus !== "pending" ||
        oldBus.driverId?.toString() !== updateData.driverId?.toString())
    );
  }

  /**
   * Handle new driver assignment
   */
  private async handleNewAssignment(
    bus: IBus,
    coordinatorName: string = "Coordinator",
  ): Promise<void> {
    if (!bus.driverId) return;

    // Ensure driver is unassigned from other buses
    await Bus.updateMany(
      {
        driverId: bus.driverId,
        _id: { $ne: bus._id },
      },
      {
        $set: {
          driverId: "",
          assignmentStatus: "unassigned",
          status: "not-running",
        },
      },
    );

    const driver = await User.findById(bus.driverId);
    const driverName = driver?.fullName || "Unknown Driver";

    logger.info(
      `${coordinatorName} assigned bus ${bus.busNumber} to driver ${driverName}`,
    );

    // Send notification
    await sendTemplatedNotificationHelper(
      bus.driverId.toString(),
      NOTIFICATION_TYPES.DRIVER_ASSIGNED,
      { busNumber: bus.busNumber },
    );

    // Create assignment log
    const newLog = new BusAssignmentLog({
      busId: bus._id,
      driverId: bus.driverId,
      routeId: bus.routeId,
      status: "pending",
    });
    await newLog.save();

    // History log
    await logHistoryHelper(
      bus.collegeId.toString(),
      "assignment_creation",
      `Bus ${bus.busNumber} assigned to driver.`,
      { assignmentId: newLog._id },
      bus._id.toString(),
      bus.driverId.toString(),
    );
  }

  /**
   * Handle driver accepting assignment
   */
  private async handleAcceptedAssignment(bus: IBus): Promise<void> {
    await BusAssignmentLog.findOneAndUpdate(
      { busId: bus._id, driverId: bus.driverId, status: "pending" } as any,
      { status: "accepted", acceptedAt: new Date() },
      { sort: { assignedAt: -1 } },
    );

    const driver = await User.findById(bus.driverId);
    const driverName = driver?.fullName || "Driver";

    await logHistoryHelper(
      bus.collegeId.toString(),
      "assignment_acceptance",
      `${driverName} accepted the assignment`,
      {},
      bus._id.toString(),
      bus.driverId?.toString(),
    );
  }

  /**
   * Handle assignment rejection
   */
  private async handleRejectedAssignment(
    oldBus: IBus,
    updatedBus: IBus,
  ): Promise<void> {
    await BusAssignmentLog.findOneAndUpdate(
      { busId: oldBus._id, driverId: oldBus.driverId, status: "pending" } as any,
      { status: "rejected", completedAt: new Date() },
      { sort: { assignedAt: -1 } },
    );

    await logHistoryHelper(
      updatedBus.collegeId.toString(),
      "assignment_rejection",
      `Bus ${oldBus.busNumber} assignment rejected/revoked.`,
      {},
      oldBus._id.toString(),
      oldBus.driverId?.toString(),
    );
  }

  /**
   * Handle trip completion
   */
  private async handleTripCompletion(
    oldBus: IBus,
    updatedBus: IBus,
  ): Promise<void> {
    await BusAssignmentLog.findOneAndUpdate(
      { busId: oldBus._id, driverId: oldBus.driverId, status: "accepted" } as any,
      { status: "completed", completedAt: new Date() },
      { sort: { assignedAt: -1 } },
    );

    await logHistoryHelper(
      updatedBus.collegeId.toString(),
      "trip_completion",
      `Trip completed for Bus ${oldBus.busNumber}.`,
      {},
      oldBus._id.toString(),
      oldBus.driverId?.toString(),
    );

    // Stop simulation if bus 9
    // Note: This logic was coupled in BusService. Ideally, BusAssignmentService should emit an event or call SimulationService.
    // For now, we will notify simulation service if it's bus 9.
    if (oldBus.busNumber === "9") {
      const { stopSimulation } = require("./simulationService");
      stopSimulation(oldBus._id.toString());
    }
  }
}

// Singleton instance
let busAssignmentServiceInstance: BusAssignmentService | null = null;

export const getBusAssignmentService = (): BusAssignmentService => {
  if (!busAssignmentServiceInstance) {
    busAssignmentServiceInstance = new BusAssignmentService();
  }
  return busAssignmentServiceInstance;
};
