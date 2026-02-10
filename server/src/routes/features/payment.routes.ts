import { Router } from "express";
import {
  createOrder,
  verifyPayment,
} from "../../controllers/features/payment.controller";
import { protect } from "../../middleware/authMiddleware";

const router = Router();

router.post("/create-order", protect, createOrder);
router.post("/verify-payment", protect, verifyPayment);

export default router;
