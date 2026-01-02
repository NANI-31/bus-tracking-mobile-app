import express from "express";
import {
  createUser,
  getUser,
  getAllUsers,
  updateUser,
  deleteUser,
  verifyEmail,
} from "../controllers/userController";
import { getDriverHistory } from "../controllers/historyController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", createUser); // Public registration
router.get("/", getAllUsers); // Public for dev test tool
router.get("/:id", protect, getUser);
router.get(
  "/:id/history",
  protect,
  authorize("admin", "busCoordinator"),
  getDriverHistory
);
router.put("/:id", protect, updateUser);
router.put("/:id/verify-email", protect, verifyEmail);
router.delete("/:id", protect, authorize("admin"), deleteUser);

export default router;
