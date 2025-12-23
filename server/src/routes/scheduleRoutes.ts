import express from "express";
import {
  createSchedule,
  getSchedule,
  getSchedulesByRoute,
} from "../controllers/scheduleController";

const router = express.Router();

router.post("/", createSchedule);
router.get("/route/:routeId", getSchedulesByRoute);
router.get("/:id", getSchedule);

export default router;
