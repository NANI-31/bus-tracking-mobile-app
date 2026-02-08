import express from "express";
import {
  sendSOS,
  resolveSos,
  getActiveSos,
} from "../controllers/sos.controller";
import { protect, authorize } from "../middleware/authMiddleware";

import { validate } from "../middleware/validate";
import { triggerSosSchema, resolveSosSchema } from "../schemas/sos.schema";

const router = express.Router();

// Only drivers and busCoordinators can send SOS
router.post(
  "/",
  protect,
  authorize("driver", "busCoordinator", "collegeAdmin", "superAdmin"),
  validate(triggerSosSchema),
  sendSOS,
);

// Only busCoordinators and admins can resolve SOS
router.put(
  "/:id/resolve",
  protect,
  authorize("busCoordinator", "collegeAdmin", "superAdmin"),
  validate(resolveSosSchema),
  resolveSos,
);

// Only busCoordinators and admins can view lists
router.get(
  "/active/:collegeId",
  protect,
  authorize("busCoordinator", "collegeAdmin", "superAdmin"),
  getActiveSos,
);

router.get(
  "/logs/:collegeId",
  protect,
  authorize("busCoordinator", "collegeAdmin", "superAdmin"),
  getActiveSos, // I'll change the controller to handle status filter
);

export default router;
