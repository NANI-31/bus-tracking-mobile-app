import express from "express";
import {
  requestOverride,
  getOverrideRequests,
  handleOverrideRequest,
  cancelOverride,
} from "../../controllers/transport/teacherOverride.controller";
import { protect, authorize } from "@/middleware/authMiddleware";

const router = express.Router();

router.post(
  "/request",
  protect,
  authorize("teacher"),
  requestOverride,
);

router.get(
  "/requests",
  protect,
  authorize("superAdmin", "busCoordinator", "collegeAdmin", "teacher"),
  getOverrideRequests,
);

router.put(
  "/request/:requestId",
  protect,
  authorize("superAdmin", "busCoordinator", "collegeAdmin"),
  handleOverrideRequest,
);

router.post(
  "/cancel",
  protect,
  authorize("teacher", "superAdmin", "busCoordinator", "collegeAdmin"),
  cancelOverride,
);

export default router;
