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
} from "../controllers/notificationController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post(
  "/",
  protect,
  authorize("admin", "busCoordinator"),
  sendNotification
);
router.post("/test", protect, authorize("admin"), sendTestNotification);
router.post(
  "/templated",
  protect,
  authorize("admin", "busCoordinator"),
  sendTemplatedNotification
);
router.post("/fcm-token", protect, updateFcmToken);
router.post("/remove-fcm-token", protect, removeFcmToken);
router.post(
  "/college",
  protect,
  authorize("admin", "busCoordinator"),
  sendCollegeNotification
);
router.post(
  "/broadcast",
  protect,
  authorize("admin", "busCoordinator"),
  broadcastNotification
);
router.get("/user/:userId", protect, getUserNotifications);
router.put("/:id/read", protect, markNotificationAsRead);

export default router;
