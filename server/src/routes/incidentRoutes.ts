import express from "express";
import {
  createIncident,
  getIncidentsByCollege,
  updateIncidentStatus,
} from "../controllers/incident.controller";
import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, createIncident);
router.get(
  "/college/:collegeId",
  protect,
  authorize("admin", "busCoordinator"),
  getIncidentsByCollege,
);
router.patch(
  "/:id/status",
  protect,
  authorize("admin", "busCoordinator"),
  updateIncidentStatus,
);

export default router;
