import express from "express";
import {
  sendNotification,
  getUserNotifications,
  markNotificationAsRead,
} from "../controllers/notificationController";

const router = express.Router();

router.post("/", sendNotification);
router.get("/user/:userId", getUserNotifications);
router.put("/:id/read", markNotificationAsRead);

export default router;
