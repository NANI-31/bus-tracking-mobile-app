import { Server } from "socket.io";
import { Bus, IBus } from "../models/Bus";
import logger from "../utils/logger";
import { getBusAssignmentService } from "./busAssignmentService";

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
