import express from "express";
import {
  getActivePlans,
  seedPlans,
} from "@/controllers/features/plan.controller";
import { protect, authorize } from "@/middleware/authMiddleware";

const router = express.Router();

router.get("/", protect, getActivePlans);
router.post("/seed", protect, authorize("superAdmin", "admin"), seedPlans);

export default router;
