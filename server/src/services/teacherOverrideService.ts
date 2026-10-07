import { Bus } from "@/models/Bus.model";
import { TeacherOverrideRequest } from "@/models/TeacherOverrideRequest.model";
import { delCache } from "@/utils/cache";
import { clearLastKnownPosition } from "@/socket/handlers/location";
import { getIO } from "@/socket";
import logger from "@/utils/logger";

/**
 * Cleanly releases an active teacher override on a bus.
 * Resets bus tracking fields, invalidates Redis caches, marks requests ended,
 * clears GPS anchor, and notifies clients across the college via Socket.IO.
 */
export const releaseTeacherOverride = async (
  busId: string,
  reason: string = "manual"
) => {
  try {
    const bus = await Bus.findById(busId);
    if (!bus || !bus.trackingTeacherId) {
      return null;
    }

    const teacherId = bus.trackingTeacherId;
    const collegeId = bus.collegeId?.toString();

    bus.trackingTeacherId = undefined;
    bus.driverId = "";
    bus.assignmentStatus = "unassigned";
    bus.status = "not-running";
    bus.lastTrackingHeartbeat = undefined;
    await bus.save();

    // Invalidate Redis caches
    await delCache("buses:all");
    if (collegeId) {
      await delCache(`buses:${collegeId}`);
    }

    // Mark any active override requests as ended
    await TeacherOverrideRequest.updateMany(
      { busId, status: "approved" },
      { status: "ended", updatedAt: new Date() }
    );

    // Clear GPS outlier guard anchor for this bus
    clearLastKnownPosition(busId);

    // Notify all connected clients via Socket.IO
    try {
      const io = getIO();
      if (io && collegeId) {
        io.to(collegeId).emit("bus_list_updated");
        io.to(collegeId).emit("bus_updated", { busId });
        io.to(collegeId).emit("location_override_ended", {
          busId,
          teacherId,
          reason,
        });
      }
    } catch (socketErr) {
      logger.warn(
        `[TeacherOverrideService] Could not emit socket update for bus ${busId}:`,
        socketErr
      );
    }

    logger.info(
      `[TeacherOverrideService] Successfully released override for bus ${busId} (teacher: ${teacherId}, reason: ${reason})`
    );
    return bus;
  } catch (error) {
    logger.error(
      `[TeacherOverrideService] Error releasing override for bus ${busId}:`,
      error
    );
    throw error;
  }
};
