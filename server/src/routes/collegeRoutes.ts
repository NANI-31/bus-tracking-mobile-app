import express from "express";
import {
  createCollege,
  getCollege,
  getAllColleges,
  getBusNumbers,
  addBusNumber,
  removeBusNumber,
  renameBusNumber,
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
  authorize("admin", "busCoordinator"),
  addBusNumber
);
router.delete(
  "/:collegeId/bus-numbers/:busNumber",
  protect,
  authorize("admin", "busCoordinator"),
  removeBusNumber
);
router.put(
  "/bus-numbers/rename",
  protect,
  authorize("admin", "busCoordinator"),
  renameBusNumber
);

export default router;
