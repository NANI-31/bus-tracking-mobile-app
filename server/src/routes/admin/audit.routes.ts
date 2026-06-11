import { Router } from "express";
import * as AuditController from "@/controllers/admin/audit.controller";
import { protect, authorize } from "@/middleware/authMiddleware";

const router = Router();

// Audit logs are sensitive
router.use(protect);

router.get(
  "/",
  authorize("superAdmin", "collegeAdmin", "admin"),
  AuditController.getAuditLogs,
);
router.post("/", authorize("superAdmin", "admin"), AuditController.createManualAuditLog);

export default router;
