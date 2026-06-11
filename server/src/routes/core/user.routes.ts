import express from "express";
import {
  activateManualPremium,
  bulkActivatePremium,
  createUser,
  getUser,
  getAllUsers,
  updateUser,
  deleteUser,
  getDevUsers,
  verifyEmail,
} from "../../controllers/core/user.controller";
import { getDriverHistory } from "@/controllers/transport/history.controller";

import { protect, authorize } from "@/middleware/authMiddleware";
import multer from "multer";

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post("/", createUser); // Public registration
router.get("/dev-list", getDevUsers); // Dev tool helper
router.get("/", protect, getAllUsers); // Protected and role-based filtering
router.get("/:id", protect, getUser);
router.get(
  "/:id/history",
  protect,
  authorize("admin", "busCoordinator"),
  getDriverHistory,
);
router.put("/:id", protect, updateUser);
router.put("/:id/verify-email", protect, verifyEmail);

// Premium Management
router.post(
  "/manual-premium",
  protect,
  authorize("collegeAdmin"),
  activateManualPremium,
);
router.post(
  "/bulk-premium",
  protect,
  authorize("collegeAdmin"),
  upload.single("file"),
  bulkActivatePremium,
);

router.delete(
  "/:id",
  protect,
  authorize("superAdmin", "collegeAdmin", "busCoordinator", "admin"),
  deleteUser,
);

export default router;
