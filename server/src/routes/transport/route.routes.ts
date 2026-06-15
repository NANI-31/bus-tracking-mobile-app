import express from "express";
import {
  createRoute,
  getRoute,
  getRoutesByCollege,
  getAllRoutes,
  updateRoute,
  deleteRoute,
  getRouteDirections,
} from "../../controllers/transport/route.controller";

import { protect, authorize } from "@/middleware/authMiddleware";

const router = express.Router();

router.post(
  "/",
  protect,
  authorize("superAdmin", "busCoordinator", "collegeAdmin"),
  createRoute,
);
router.get("/", protect, getAllRoutes);
router.get("/college/:collegeId", protect, getRoutesByCollege);
router.get("/:id/directions", protect, getRouteDirections);
router.get("/:id", protect, getRoute);
router.put(
  "/:id",
  protect,
  authorize("superAdmin", "busCoordinator", "collegeAdmin"),
  updateRoute,
);
router.delete(
  "/:id",
  protect,
  authorize("superAdmin", "busCoordinator", "collegeAdmin"),
  deleteRoute,
);

export default router;
