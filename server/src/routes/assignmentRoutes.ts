import express from "express";
import {
  getAssignmentLogsByBus,
  getAssignmentLogsByDriver,
} from "../controllers/assignmentController";

import { protect } from "../middleware/authMiddleware";

const router = express.Router();

router.get("/bus/:busId", protect, getAssignmentLogsByBus);
router.get("/driver/:driverId", protect, getAssignmentLogsByDriver);

export default router;
