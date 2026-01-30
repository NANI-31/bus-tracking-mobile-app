import { Router } from "express";
import userRoutes from "./userRoutes";
import busRoutes from "./busRoutes";
import collegeRoutes from "./collegeRoutes";
import routeRoutes from "./routeRoutes";
import scheduleRoutes from "./scheduleRoutes";
import notificationRoutes from "./notificationRoutes";
import authRoutes from "./authRoutes";
import assignmentRoutes from "./assignmentRoutes";
import sosRoutes from "./sosRoutes";
import incidentRoutes from "./incidentRoutes";
import historyRoutes from "./historyRoutes";
import paymentRoutes from "./paymentRoutes";

const router = Router();

router.use("/users", userRoutes);
router.use("/buses", busRoutes);
router.use("/colleges", collegeRoutes);
router.use("/routes", routeRoutes);
router.use("/schedules", scheduleRoutes);
router.use("/notifications", notificationRoutes);
router.use("/auth", authRoutes);
router.use("/assignments", assignmentRoutes);
router.use("/sos", sosRoutes);
router.use("/incidents", incidentRoutes);
router.use("/history", historyRoutes);
router.use("/payment", paymentRoutes);

// Admin Routes
import collegeAdminRoutes from "./collegeAdmin.routes";
import superAdminRoutes from "./superAdmin.routes";
import auditRoutes from "./audit.routes";
import systemConfigRoutes from "./systemConfig.routes";

router.use("/admin/college", collegeAdminRoutes);
router.use("/admin/super", superAdminRoutes);
router.use("/admin/audit-logs", auditRoutes);
router.use("/admin/system-config", systemConfigRoutes);

export default router;
