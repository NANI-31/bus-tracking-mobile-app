import { Router } from "express";
import {
  createOrder,
  verifyPayment,
  getTransactions,
} from "../../controllers/features/payment.controller";
import { protect, collegeAdminOnly } from "../../middleware/authMiddleware";

const router = Router();

router.post("/create-order", protect, createOrder);
router.post("/verify-payment", protect, verifyPayment);
router.get("/transactions", protect, collegeAdminOnly, getTransactions);

export default router;
