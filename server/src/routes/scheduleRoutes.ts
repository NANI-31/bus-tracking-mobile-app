import express from "express";
import {
  createSchedule,
  getSchedule,
  getSchedulesByRoute,
  getSchedulesByCollege,
} from "../controllers/scheduleController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, authorize("admin", "busCoordinator"), createSchedule);
router.get("/route/:routeId", protect, getSchedulesByRoute);
router.get("/college/:collegeId", protect, getSchedulesByCollege);
router.get("/:id", protect, getSchedule);

export default router;
