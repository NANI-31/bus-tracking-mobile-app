import { Router } from "express";
import userRoutes from "./core/user.routes";
import busRoutes from "./transport/bus.routes";
import collegeRoutes from "./core/college.routes";
import routeRoutes from "./transport/route.routes";
import scheduleRoutes from "./transport/schedule.routes";
import notificationRoutes from "./features/notification.routes";
import authRoutes from "./auth.routes";
import assignmentRoutes from "./transport/assignment.routes";
import sosRoutes from "./features/sos.routes";
import incidentRoutes from "./features/incident.routes";
import historyRoutes from "./transport/history.routes";
import paymentRoutes from "./features/payment.routes";

import collegeAdminRoutes from "./admin/collegeAdmin.routes";
import superAdminRoutes from "./admin/superAdmin.routes";
import auditRoutes from "./admin/audit.routes";
import systemConfigRoutes from "./admin/systemConfig.routes";

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

router.use("/admin/college", collegeAdminRoutes);
router.use("/admin/super", superAdminRoutes);
router.use("/admin/audit-logs", auditRoutes);
router.use("/admin/system-config", systemConfigRoutes);

export { router };
