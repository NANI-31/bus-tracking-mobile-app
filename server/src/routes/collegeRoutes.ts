import express from "express";
import {
  createCollege,
  getCollege,
  getAllColleges,
  getBusNumbers,
  addBusNumber,
  removeBusNumber,
} from "../controllers/collegeController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, authorize("admin"), createCollege);
router.get("/", getAllColleges); // Public for registration
router.get("/:id", protect, getCollege);

// Bus Number Management
router.get("/:collegeId/bus-numbers", protect, getBusNumbers);
router.post(
  "/bus-numbers",
  protect,
  authorize("admin", "coordinator"),
  addBusNumber
);
router.delete(
  "/:collegeId/bus-numbers/:busNumber",
  protect,
  authorize("admin", "coordinator"),
  removeBusNumber
);

export default router;
