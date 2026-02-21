import { Router } from "express";
import * as SuperAdminController from "@/controllers/admin/superAdmin.controller";
import { protect, superAdminOnly } from "@/middleware/authMiddleware";

const router = Router();

// All routes here require being a logged-in Super Admin
router.use(protect, superAdminOnly);

router.get("/stats", SuperAdminController.getSystemStats);
router.get("/storage-stats", SuperAdminController.getStorageStats);
router.get(
  "/colleges/:collegeId/storage-history",
  SuperAdminController.getCollegeStorageHistory,
);
router.put("/colleges/:collegeId/verify", SuperAdminController.verifyCollege);
router.put("/colleges/:collegeId/suspend", SuperAdminController.suspendCollege);

export default router;
