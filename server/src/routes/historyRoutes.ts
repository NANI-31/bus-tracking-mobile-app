import express from "express";
import { getHistory } from "../controllers/historyController";
import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.get("/", protect, authorize("admin", "busCoordinator"), getHistory);

export default router;
