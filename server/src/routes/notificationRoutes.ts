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
} from "../controllers/notificationController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, authorize("admin", "coordinator"), sendNotification);
router.post("/test", protect, authorize("admin"), sendTestNotification);
router.post(
  "/templated",
  protect,
  authorize("admin", "coordinator"),
  sendTemplatedNotification
);
router.post("/fcm-token", protect, updateFcmToken);
router.post("/remove-fcm-token", protect, removeFcmToken);
router.post(
  "/college",
  protect,
  authorize("admin", "coordinator"),
  sendCollegeNotification
);
router.get("/user/:userId", protect, getUserNotifications);
router.put("/:id/read", protect, markNotificationAsRead);

export default router;
