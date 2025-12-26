import express from "express";
import {
  getAssignmentLogsByBus,
  getAssignmentLogsByDriver,
} from "../controllers/assignmentController";

const router = express.Router();

router.get("/bus/:busId", getAssignmentLogsByBus);
router.get("/driver/:driverId", getAssignmentLogsByDriver);

export default router;
