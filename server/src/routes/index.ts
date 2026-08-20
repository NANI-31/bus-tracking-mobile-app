import { Router } from "express";
import userRoutes from "@/routes/core/user.routes";
import busRoutes from "@/routes/transport/bus.routes";
import collegeRoutes from "@/routes/core/college.routes";
import routeRoutes from "@/routes/transport/route.routes";
import scheduleRoutes from "@/routes/transport/schedule.routes";
import notificationRoutes from "@/routes/features/notification.routes";
import authRoutes from "@/routes/auth.routes";
import assignmentRoutes from "@/routes/transport/assignment.routes";
import sosRoutes from "@/routes/features/sos.routes";
import incidentRoutes from "@/routes/features/incident.routes";
import historyRoutes from "@/routes/transport/history.routes";
import paymentRoutes from "@/routes/features/payment.routes";
import planRoutes from "@/routes/features/plan.routes";
import placesRoutes from "@/routes/core/places.routes";

import collegeAdminRoutes from "@/routes/admin/collegeAdmin.routes";
import superAdminRoutes from "@/routes/admin/superAdmin.routes";
import auditRoutes from "@/routes/admin/audit.routes";
import systemConfigRoutes from "@/routes/admin/systemConfig.routes";
import sessionExpiryLogRoutes from "@/routes/admin/sessionExpiryLog.routes";

const router = Router();

router.use("/users", userRoutes);
router.use("/buses", busRoutes);
router.use("/colleges", collegeRoutes);
router.use("/places", placesRoutes);
router.use("/routes", routeRoutes);
router.use("/schedules", scheduleRoutes);
router.use("/notifications", notificationRoutes);
router.use("/auth", authRoutes);
router.use("/assignments", assignmentRoutes);
router.use("/sos", sosRoutes);
router.use("/incidents", incidentRoutes);
router.use("/history", historyRoutes);
router.use("/payments", paymentRoutes);
router.use("/plans", planRoutes);

// Admin Routes

router.use("/admin/college", collegeAdminRoutes);
router.use("/admin/super", superAdminRoutes);
router.use("/admin/audit-logs", auditRoutes);
router.use("/admin/system-config", systemConfigRoutes);
router.use("/admin/session-expiry-logs", sessionExpiryLogRoutes);

export { router };
