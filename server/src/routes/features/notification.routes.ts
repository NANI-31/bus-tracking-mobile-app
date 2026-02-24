import express from "express";
import {
  sendNotification,
  getUserNotifications,
  markNotificationAsRead,
  sendTestNotification,
  updateFcmToken,
  removeFcmToken,
  sendCollegeNotification,
  sendTemplatedNotification,
  broadcastNotification,
  markAllNotificationsAsRead,
} from "../../controllers/features/notification.controller";
import { sendVoiceNotification } from "../../controllers/features/voiceNotification.controller";

import { protect, authorize } from "@/middleware/authMiddleware";
import multer from "multer";

const router = express.Router();
const upload = multer({ dest: "uploads/" });

router.post(
  "/",
  protect,
  authorize("admin", "busCoordinator"),
  sendNotification,
);
router.post("/test", protect, authorize("admin"), sendTestNotification);
router.post(
  "/templated",
  protect,
  authorize("admin", "busCoordinator"),
  sendTemplatedNotification,
);
router.post("/fcm-token", protect, updateFcmToken);
router.post("/remove-fcm-token", protect, removeFcmToken);
router.post(
  "/college",
  protect,
  authorize("admin", "busCoordinator"),
  sendCollegeNotification,
);
router.post(
  "/broadcast",
  protect,
  authorize("admin", "busCoordinator"),
  broadcastNotification,
);
router.get("/user/:userId", protect, getUserNotifications);
router.put("/user/:userId/read-all", protect, markAllNotificationsAsRead);
router.post("/voice", protect, upload.single("audio"), sendVoiceNotification);
router.put("/:id/read", protect, markNotificationAsRead);

export default router;
