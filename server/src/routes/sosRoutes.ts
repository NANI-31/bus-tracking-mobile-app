import express from "express";
import {
  sendSOS,
  resolveSos,
  getActiveSos,
} from "../controllers/sosController";
import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

// Only drivers and busCoordinators can send SOS
router.post(
  "/",
  protect,
  authorize("driver", "busCoordinator", "admin"),
  sendSOS
);

// Only busCoordinators and admins can resolve SOS
router.put(
  "/:id/resolve",
  protect,
  authorize("busCoordinator", "admin"),
  resolveSos
);

// Only busCoordinators and admins can view active SOS lists for their college
router.get(
  "/active/:collegeId",
  protect,
  authorize("busCoordinator", "admin"),
  getActiveSos
);

export default router;
