import express from "express";
import {
  addBusNumber,
  getBusNumbers,
  removeBusNumber,
} from "../controllers/busNumberController";

const router = express.Router();

router.post("/", addBusNumber);
router.get("/:collegeId", getBusNumbers);
router.delete("/:collegeId/:busNumber", removeBusNumber);

export default router;
