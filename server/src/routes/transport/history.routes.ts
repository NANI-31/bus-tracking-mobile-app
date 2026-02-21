import express from "express";
import { getHistory } from "@/controllers/transport/history.controller";
import { protect, authorize } from "@/middleware/authMiddleware";

const router = express.Router();

router.get("/", protect, authorize("admin", "busCoordinator"), getHistory);

export default router;
