import { Server } from "socket.io";
import { Bus, IBus } from "../models/Bus.model";
import logger from "../utils/logger";
import { getBusAssignmentService } from "./busAssignmentService";
import { delCache } from "../utils/cache";

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
    requestingUserName?: string,
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

    // Handle assignment state changes via BusAssignmentService
    const busAssignmentService = getBusAssignmentService();
    await busAssignmentService.handleAssignmentChanges(
      oldBus,
      updatedBus,
      updateData,
      requestingUserName,
    );

    // Handle simulation triggers
    await this.handleSimulationTriggers(oldBus, updatedBus, updateData);

    // Invalidate caches BEFORE broadcasting
    await delCache("buses:all");
    await delCache(`buses:${updatedBus.collegeId}`);

    // Broadcast update to college room
    this.broadcastBusListUpdate(updatedBus.collegeId.toString());

    return updatedBus;
  }

  /**
   * Handle simulation triggers
   */
  private async handleSimulationTriggers(
    oldBus: IBus,
    updatedBus: IBus,
    updateData: Partial<IBus>,
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
          updatedBus.collegeId.toString(),
        );
      }
    }
  }

  /**
   * Update bus location and handle side effects (broadcasting, nearby notifications)
   */
  async updateBusLocation(data: {
    busId: string;
    location: { lat: number; lng: number };
    speed?: number;
    heading?: number;
  }): Promise<void> {
    const { busId, location, speed, heading } = data;

    const { Bus, BusLocation } = require("../models/Bus.model");
    const { checkAndNotifyBusNearby } = require("../utils/busNearbyLogic");

    // 1. Fetch bus details to get collegeId, busNumber, and routeId
    const bus = await Bus.findById(busId);
    if (!bus) {
      throw new Error("Bus not found");
    }

    const collegeId = bus.collegeId.toString();

    // 2. Broadcast to college room
    this.io.to(collegeId).emit("location_updated", {
      busId,
      collegeId,
      location,
      speed: speed ?? 0,
      heading: heading ?? 0,
      timestamp: new Date(),
    });

    // 2b. Broadcast to global tracking room (for Super Admin)
    this.io.to("global_tracking").emit("location_updated", {
      busId,
      collegeId,
      location,
      speed: speed ?? 0,
      heading: heading ?? 0,
      timestamp: new Date(),
    });

    // 3. Update Bus status in DB
    const status =
      speed && speed > 2
        ? bus.delay > 10
          ? "delayed"
          : "on-time"
        : bus.status;
    const oldBusRecord = await Bus.findById(busId);
    const oldStatus = oldBusRecord?.status;

    await Bus.findByIdAndUpdate(busId, { status });

    // Invalidate cache if status changed
    if (oldStatus !== status) {
      await delCache("buses:all");
      await delCache(`buses:${collegeId}`);
      this.broadcastBusListUpdate(collegeId);
    }

    // 4. Save location to DB
    const newLocation = new BusLocation({
      busId,
      currentLocation: location,
      speed: speed ?? 0,
      heading: heading ?? 0,
    });
    await newLocation.save();

    // 4. Check for nearby notifications
    if (bus.routeId) {
      checkAndNotifyBusNearby(
        busId,
        bus.busNumber,
        location.lat,
        location.lng,
        bus.routeId.toString(),
      );
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
