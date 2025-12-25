import { NOTIFICATION_TYPES } from "../notificationTypes";
import { busDelayed } from "./busDelayed";
import { busArriving } from "./busArriving";
import { busNearby } from "./busNearby";
import { busCancelled } from "./busCancelled";
import { nextStop } from "./nextStop";
import { tripStarted } from "./tripStarted";
import { tripEnded } from "./tripEnded";
import { emergencyAlert } from "./emergencyAlert";
import { routeChange } from "./routeChange";
import { generalAnnouncement } from "./generalAnnouncement";

type LanguageCode = "en" | "hi" | "te";

export interface NotificationTemplate {
  title: string;
  body: string;
}

export type MultiLangTemplates = Record<LanguageCode, NotificationTemplate>;

export const NOTIFICATION_TEMPLATES: Record<string, MultiLangTemplates> = {
  [NOTIFICATION_TYPES.BUS_DELAYED]: busDelayed,
  [NOTIFICATION_TYPES.BUS_ARRIVING]: busArriving,
  [NOTIFICATION_TYPES.BUS_NEARBY]: busNearby,
  [NOTIFICATION_TYPES.BUS_CANCELLED]: busCancelled,
  [NOTIFICATION_TYPES.NEXT_STOP]: nextStop,
  [NOTIFICATION_TYPES.TRIP_STARTED]: tripStarted,
  [NOTIFICATION_TYPES.TRIP_ENDED]: tripEnded,
  [NOTIFICATION_TYPES.EMERGENCY_ALERT]: emergencyAlert,
  [NOTIFICATION_TYPES.ROUTE_CHANGE]: routeChange,
  [NOTIFICATION_TYPES.GENERAL_ANNOUNCEMENT]: generalAnnouncement,
};

// Helper to get templates for a specific language (defaults to English)
export const getTemplatesForLanguage = (
  type: string,
  lang: string = "en"
): NotificationTemplate => {
  const templates = NOTIFICATION_TEMPLATES[type];
  if (!templates) {
    // Return a generic fallback if type not found to prevent crash
    return {
      title: "Notification",
      body: "You have a new notification.",
    };
  }
  // Safe cast for lang, defaulting to 'en' if the specific lang key doesn't exist
  return (templates as any)[lang] || templates["en"];
};
