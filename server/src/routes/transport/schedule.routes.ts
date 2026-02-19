import express from "express";
import {
  createSchedule,
  getSchedule,
  getSchedulesByRoute,
  getSchedulesByCollege,
  updateSchedule,
  deleteSchedule,
} from "../../controllers/transport/schedule.controller";

import { protect, authorize } from "../../middleware/authMiddleware";

const router = express.Router();

router.post(
  "/",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  createSchedule,
);
router.get("/route/:routeId", protect, getSchedulesByRoute);
router.get("/college/:collegeId", protect, getSchedulesByCollege);
router.get("/:id", protect, getSchedule);

router.put(
  "/:id",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  updateSchedule,
);

router.delete(
  "/:id",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  deleteSchedule,
);

export default router;
