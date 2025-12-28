import express from "express";
import { sendSOS } from "../controllers/sosController";
import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

// Only drivers (and maybe coordinators for testing) can send SOS
router.post("/", protect, authorize("driver", "coordinator", "admin"), sendSOS);

export default router;
