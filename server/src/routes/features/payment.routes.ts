import { Router } from "express";
import {
  createOrder,
  verifyPayment,
  getTransactions,
  requestRefund,
  getRefundRequests,
  resolveRefund,
  getSubscriptionAnalytics,
  getAdvancedAnalytics,
} from "@/controllers/features/payment.controller";
import {
  protect,
  collegeAdminOnly,
  superAdminOnly,
  premiumOnly,
} from "@/middleware/authMiddleware";

const router = Router();

router.post("/create-order", protect, createOrder);
router.post("/verify-payment", protect, verifyPayment);
router.get("/transactions", protect, getTransactions);
router.post("/request-refund", protect, requestRefund);

// Admin Routes
router.get(
  "/admin/refund-requests",
  protect,
  collegeAdminOnly,
  getRefundRequests,
);
router.post("/admin/resolve-refund", protect, collegeAdminOnly, resolveRefund);
router.get(
  "/admin/analytics",
  protect,
  collegeAdminOnly,
  getSubscriptionAnalytics,
);
router.get(
  "/admin/advanced-analytics",
  protect,
  collegeAdminOnly,
  premiumOnly,
  getAdvancedAnalytics,
);

export default router;
