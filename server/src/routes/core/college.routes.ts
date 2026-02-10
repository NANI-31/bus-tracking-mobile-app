import express from "express";
import {
  createCollege,
  getCollege,
  getAllColleges,
  getBusNumbers,
  addBusNumber,
  removeBusNumber,
  renameBusNumber,
  updateBusDetails,
} from "../../controllers/core/college.controller";

import { protect, authorize } from "../../middleware/authMiddleware";

import { validate } from "../../middleware/validate";
import {
  addBusNumberSchema,
  removeBusNumberSchema,
  renameBusNumberSchema,
} from "../../models/college.schema";

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
  validate(addBusNumberSchema),
  addBusNumber,
);
router.delete(
  "/:collegeId/bus-numbers/:busNumber",
  protect,
  authorize("admin", "busCoordinator"),
  validate(removeBusNumberSchema),
  removeBusNumber,
);
router.put(
  "/bus-numbers/rename",
  protect,
  authorize("admin", "busCoordinator"),
  validate(renameBusNumberSchema),
  renameBusNumber,
);
router.put(
  "/bus-numbers/update",
  protect,
  authorize("admin", "busCoordinator"),
  updateBusDetails,
);

export default router;
