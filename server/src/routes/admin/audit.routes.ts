import { Router } from "express";
import * as AuditController from "@/controllers/admin/audit.controller";
import { protect, authorize } from "@/middleware/authMiddleware";

const router = Router();

// Audit logs are sensitive
router.use(protect);

router.get(
  "/",
  authorize("superAdmin", "collegeAdmin"),
  AuditController.getAuditLogs,
);
router.post("/", authorize("superAdmin"), AuditController.createManualAuditLog);

export default router;
