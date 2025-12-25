import { getDistanceInMeters } from "./distance";
import { buildNotificationMessage } from "./buildNotification";
import { NOTIFICATION_TYPES } from "../constants/notificationTypes";
import { sendNotificationToDevice } from "./firebase";
import User, { IUser } from "../models/User";
import { IBus } from "../models/Bus";

const NEARBY_RADIUS_METERS = 400; // 400 meters radius

export const checkAndNotifyBusNearby = async (
  busId: string,
  busNumber: string,
  currentLat: number,
  currentLng: number,
  routeId: string
) => {
  try {
    // Find users who are on this route and have a valid stop location
    // Also ensuring they have an FCM token to receive notifications
    const users = await User.find({
      routeId: routeId,
      fcmToken: { $exists: true, $ne: "" },
      "stopLocation.lat": { $exists: true },
      "stopLocation.lng": { $exists: true },
    });

    for (const user of users) {
      if (
        !user.stopLocation ||
        !user.stopLocation.lat ||
        !user.stopLocation.lng
      )
        continue;

      const distance = getDistanceInMeters(
        currentLat,
        currentLng,
        user.stopLocation.lat,
        user.stopLocation.lng
      );

      // Check if bus is within radius
      if (distance <= NEARBY_RADIUS_METERS) {
        // Prevent spam: Check if we already notified for this bus nearby recently
        // Ideally we reset this flag when the trip ends or after a long cooldown
        if (user.lastNearbyNotifiedBusId === busId) continue;

        // Get user language preference (defaults to 'en')
        const language = (user.language as "en" | "hi" | "te") || "en";

        const { title, message } = buildNotificationMessage(
          NOTIFICATION_TYPES.BUS_NEARBY,
          {
            busNumber: busNumber,
            stopName: user.stopName || "your stop",
          },
          language
        );

        if (user.fcmToken) {
          await sendNotificationToDevice(user.fcmToken, title, message, {
            type: NOTIFICATION_TYPES.BUS_NEARBY,
            busId: busId,
            stopId: user.stopId || "",
          });

          // Update user state to avoid duplicate notifications
          user.lastNearbyNotifiedBusId = busId;
          await user.save();
          console.log(
            `[BusNearby] Sent notification to user ${user._id} for bus ${busNumber}`
          );
        }
      }
    }
  } catch (error) {
    console.error("Error in checkAndNotifyBusNearby:", error);
  }
};
