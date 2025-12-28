import express from "express";
import {
  createRoute,
  getRoute,
  getRoutesByCollege,
} from "../controllers/routeController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, authorize("admin", "coordinator"), createRoute);
router.get("/college/:collegeId", protect, getRoutesByCollege);
router.get("/:id", protect, getRoute);

export default router;
