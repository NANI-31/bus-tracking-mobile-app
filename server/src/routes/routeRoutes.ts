import express from "express";
import {
  createRoute,
  getRoute,
  getRoutesByCollege,
  updateRoute,
  deleteRoute,
} from "../controllers/routeController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, authorize("admin", "busCoordinator"), createRoute);
router.get("/college/:collegeId", protect, getRoutesByCollege);
router.get("/:id", protect, getRoute);
router.put("/:id", protect, authorize("admin", "busCoordinator"), updateRoute);
router.delete(
  "/:id",
  protect,
  authorize("admin", "busCoordinator"),
  deleteRoute
);

export default router;
