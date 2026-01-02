import { Server } from "socket.io";
import { Bus, IBus } from "../models/Bus";
import { BusAssignmentLog } from "../models/BusAssignmentLog";
import User, { UserRole } from "../models/User";
import { sendTemplatedNotificationHelper } from "../controllers/notificationController";
import { logHistoryHelper } from "../controllers/historyController";
import { NOTIFICATION_TYPES } from "../constants/notificationTypes";
import logger from "../utils/logger";

/**
 * BusService - Encapsulates bus update business logic.
 * Extracted from busController to follow Single Responsibility Principle.
 */
export class BusService {
  private io: Server;

  constructor(io: Server) {
    this.io = io;
  }

  /**
   * Update a bus and handle all related side effects
   */
  async updateBus(
    busId: string,
    updateData: Partial<IBus>,
    requestingUserName?: string
  ): Promise<IBus> {
    const oldBus = await Bus.findById(busId);
    if (!oldBus) {
      throw new Error("Bus not found");
    }

    const updatedBus = await Bus.findByIdAndUpdate(busId, updateData, {
      new: true,
    });

    if (!updatedBus) {
      throw new Error("Failed to update bus");
    }

    // Handle assignment state changes
    await this.handleAssignmentChanges(
      oldBus,
      updatedBus,
      updateData,
      requestingUserName
    );

    // Handle simulation triggers
    await this.handleSimulationTriggers(oldBus, updatedBus, updateData);

    // Broadcast update to college room
    this.broadcastBusListUpdate(updatedBus.collegeId.toString());

    return updatedBus;
  }

  /**
   * Handle all assignment-related state changes
   */
  private async handleAssignmentChanges(
    oldBus: IBus,
    updatedBus: IBus,
    updateData: Partial<IBus>,
    requestingUserName?: string
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
        `Bus ${bus.busNumber} assigned to its default route. No notification needed.`
      );
      return;
    }

    logger.info(
      `Bus ${bus.busNumber} assigned to non-default route ${bus.routeId}. Sending notifications.`
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
          }
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
      bus._id.toString()
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
    coordinatorName: string = "Coordinator"
  ): Promise<void> {
    if (!bus.driverId) return;

    const driver = await User.findById(bus.driverId);
    const driverName = driver?.fullName || "Unknown Driver";

    logger.info(
      `${coordinatorName} assigned bus ${bus.busNumber} to driver ${driverName}`
    );

    // Send notification
    await sendTemplatedNotificationHelper(
      bus.driverId.toString(),
      NOTIFICATION_TYPES.DRIVER_ASSIGNED,
      { busNumber: bus.busNumber }
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
      bus.driverId.toString()
    );
  }

  /**
   * Handle driver accepting assignment
   */
  private async handleAcceptedAssignment(bus: IBus): Promise<void> {
    await BusAssignmentLog.findOneAndUpdate(
      {
        busId: bus._id,
        driverId: bus.driverId,
        status: "pending",
      },
      { status: "accepted", acceptedAt: new Date() },
      { sort: { assignedAt: -1 } }
    );

    const driver = await User.findById(bus.driverId);
    const driverName = driver?.fullName || "Driver";

    await logHistoryHelper(
      bus.collegeId.toString(),
      "assignment_acceptance",
      `${driverName} accepted the assignment`,
      {},
      bus._id.toString(),
      bus.driverId?.toString()
    );
  }

  /**
   * Handle assignment rejection
   */
  private async handleRejectedAssignment(
    oldBus: IBus,
    updatedBus: IBus
  ): Promise<void> {
    await BusAssignmentLog.findOneAndUpdate(
      { busId: oldBus._id, driverId: oldBus.driverId, status: "pending" },
      { status: "rejected", completedAt: new Date() },
      { sort: { assignedAt: -1 } }
    );

    await logHistoryHelper(
      updatedBus.collegeId.toString(),
      "assignment_rejection",
      `Bus ${oldBus.busNumber} assignment rejected/revoked.`,
      {},
      oldBus._id.toString(),
      oldBus.driverId?.toString()
    );
  }

  /**
   * Handle trip completion
   */
  private async handleTripCompletion(
    oldBus: IBus,
    updatedBus: IBus
  ): Promise<void> {
    await BusAssignmentLog.findOneAndUpdate(
      { busId: oldBus._id, driverId: oldBus.driverId, status: "accepted" },
      { status: "completed", completedAt: new Date() },
      { sort: { assignedAt: -1 } }
    );

    await logHistoryHelper(
      updatedBus.collegeId.toString(),
      "trip_completion",
      `Trip completed for Bus ${oldBus.busNumber}.`,
      {},
      oldBus._id.toString(),
      oldBus.driverId?.toString()
    );

    // Stop simulation if bus 9
    if (oldBus.busNumber === "9") {
      const { stopSimulation } = require("./simulationService");
      stopSimulation(oldBus._id.toString());
    }
  }

  /**
   * Handle simulation triggers
   */
  private async handleSimulationTriggers(
    oldBus: IBus,
    updatedBus: IBus,
    updateData: Partial<IBus>
  ): Promise<void> {
    // Cast to any since request body may contain "STARTED" which isn't in IBus type
    const requestStatus = (updateData as any).status;

    if (requestStatus === "STARTED") {
      logger.info(`Driver started the drive for bus ${updatedBus.busNumber}`);

      // Trigger simulation for bus 9
      if (updatedBus.busNumber === "9") {
        const { startSimulation } = require("./simulationService");
        startSimulation(
          this.io,
          updatedBus._id.toString(),
          updatedBus.collegeId.toString()
        );
      }
    }
  }

  /**
   * Broadcast bus list update to college room
   */
  private broadcastBusListUpdate(collegeId: string): void {
    this.io.to(collegeId).emit("bus_list_updated");
  }
}

// Singleton instance (created when imported with io)
let busServiceInstance: BusService | null = null;

export const getBusService = (io: Server): BusService => {
  if (!busServiceInstance) {
    busServiceInstance = new BusService(io);
  }
  return busServiceInstance;
};
