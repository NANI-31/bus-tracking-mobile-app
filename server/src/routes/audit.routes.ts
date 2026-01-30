import { Router } from "express";
import * as AuditController from "../controllers/audit.controller";
import { protect, superAdminOnly } from "../middleware/authMiddleware";

const router = Router();

// Audit logs are sensitive and only for Super Admins
router.use(protect, superAdminOnly);

router.get("/", AuditController.getAuditLogs);
router.post("/", AuditController.createManualAuditLog);

export default router;
