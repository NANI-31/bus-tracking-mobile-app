import express from "express";
import {
  getAssignmentLogsByBus,
  getAssignmentLogsByDriver,
} from "../../controllers/transport/assignment.controller";

import { protect } from "@/middleware/authMiddleware";

const router = express.Router();

router.get("/bus/:busId", protect, getAssignmentLogsByBus);
router.get("/driver/:driverId", protect, getAssignmentLogsByDriver);

export default router;
