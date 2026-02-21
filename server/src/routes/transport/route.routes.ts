import express from "express";
import {
  createRoute,
  getRoute,
  getRoutesByCollege,
  getAllRoutes,
  updateRoute,
  deleteRoute,
} from "../../controllers/transport/route.controller";

import { protect, authorize } from "@/middleware/authMiddleware";

const router = express.Router();

router.post(
  "/",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  createRoute,
);
router.get("/", protect, getAllRoutes);
router.get("/college/:collegeId", protect, getRoutesByCollege);
router.get("/:id", protect, getRoute);
router.put(
  "/:id",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  updateRoute,
);
router.delete(
  "/:id",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  deleteRoute,
);

export default router;
