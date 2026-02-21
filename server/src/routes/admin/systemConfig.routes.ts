import { Router } from "express";
import * as ConfigController from "@/controllers/admin/systemConfig.controller";
import { protect, superAdminOnly } from "@/middleware/authMiddleware";

const router = Router();

// Public config is accessible without protection
router.get("/public", ConfigController.getPublicConfig);

// Private config and updates require Super Admin
router.get("/", protect, superAdminOnly, ConfigController.getSystemConfig);
router.put("/", protect, superAdminOnly, ConfigController.updateConfig);

export default router;
