import { Server } from "socket.io";
import College from "../models/College.model";
import { Bus } from "../models/Bus.model";
import logger from "../utils/logger";

export class CollegeService {
  private io: Server;

  constructor(io: Server) {
    this.io = io;
  }

  async addBusNumber(collegeId: string, busNumber: string): Promise<string[]> {
    const college = await College.findById(collegeId);
    if (!college) throw new Error("College not found");

    if (!college.busNumbers.includes(busNumber)) {
      college.busNumbers.push(busNumber);
      await college.save();
    }

    this.broadcastBusListUpdate(collegeId);
    return college.busNumbers;
  }

  async removeBusNumber(
    collegeId: string,
    busNumber: string,
  ): Promise<string[]> {
    const college = await College.findById(collegeId);
    if (!college) throw new Error("College not found");

    college.busNumbers = college.busNumbers.filter((n) => n !== busNumber);
    await college.save();

    this.broadcastBusListUpdate(collegeId);
    return college.busNumbers;
  }

  async renameBusNumber(
    collegeId: string,
    oldBusNumber: string,
    newBusNumber: string,
  ): Promise<string[]> {
    const college = await College.findById(collegeId);
    if (!college) throw new Error("College not found");

    // 1. Update allowlist in College
    const index = college.busNumbers.indexOf(oldBusNumber);
    if (index !== -1) {
      college.busNumbers[index] = newBusNumber;
      await college.save();
    }

    // 2. Update actual Bus documents
    await Bus.updateMany(
      { collegeId, busNumber: oldBusNumber },
      { busNumber: newBusNumber },
    );

    this.broadcastBusListUpdate(collegeId);
    return college.busNumbers;
  }

  private broadcastBusListUpdate(collegeId: string): void {
    this.io.to(collegeId).emit("bus_list_updated");
  }
}

let collegeServiceInstance: CollegeService | null = null;

export const getCollegeService = (io: Server): CollegeService => {
  if (!collegeServiceInstance) {
    collegeServiceInstance = new CollegeService(io);
  }
  return collegeServiceInstance;
};
