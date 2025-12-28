import express from "express";
import {
  createIncident,
  getIncidentsByCollege,
  updateIncidentStatus,
} from "../controllers/incidentController";
import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, createIncident);
router.get(
  "/college/:collegeId",
  protect,
  authorize("admin", "coordinator"),
  getIncidentsByCollege
);
router.patch(
  "/:id/status",
  protect,
  authorize("admin", "coordinator"),
  updateIncidentStatus
);

export default router;
