import express from "express";
import {
  sendNotification,
  getUserNotifications,
  markNotificationAsRead,
  sendTestNotification,
  updateFcmToken,
  sendCollegeNotification,
  sendTemplatedNotification,
} from "../controllers/notificationController";

const router = express.Router();

router.post("/", sendNotification);
router.post("/test", sendTestNotification);
router.post("/templated", sendTemplatedNotification);
router.post("/fcm-token", updateFcmToken);
router.post("/college", sendCollegeNotification);
router.get("/user/:userId", getUserNotifications);
router.put("/:id/read", markNotificationAsRead);

export default router;
