import express from "express";
import {
  getActivePlans,
  seedPlans,
  getAllPlans,
  createPlan,
  updatePlan,
  deletePlan,
} from "@/controllers/features/plan.controller";
import { protect, authorize } from "@/middleware/authMiddleware";

const router = express.Router();

// Public/student routes: get active plans
router.get("/", protect, getActivePlans);

// Admin/SuperAdmin routes
router.get("/all", protect, authorize("superAdmin"), getAllPlans);
router.post("/seed", protect, authorize("superAdmin", "admin"), seedPlans);
router.post("/", protect, authorize("superAdmin"), createPlan);
router.put("/:id", protect, authorize("superAdmin"), updatePlan);
router.delete("/:id", protect, authorize("superAdmin"), deletePlan);

export default router;

