import { Router } from "express";
import * as SessionExpiryLogController from "@/controllers/admin/sessionExpiryLog.controller";
import { protect, superAdminOnly } from "@/middleware/authMiddleware";

const router = Router();

// All session expiry log endpoints are super admin only
router.use(protect, superAdminOnly);

// GET  /admin/session-expiry-logs/summary   → dashboard summary cards + chart
router.get("/summary", SessionExpiryLogController.getSessionExpiryLogsSummary);

// GET  /admin/session-expiry-logs           → paginated list with filters
router.get("/", SessionExpiryLogController.getSessionExpiryLogs);

// GET  /admin/session-expiry-logs/:id       → single log full detail
router.get("/:id", SessionExpiryLogController.getSessionExpiryLogDetail);

// DELETE /admin/session-expiry-logs         → manual purge (TTL handles routine)
router.delete("/", SessionExpiryLogController.purgeSessionExpiryLogs);

export default router;
