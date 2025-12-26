import express from "express";
import {
  createCollege,
  getCollege,
  getAllColleges,
  getBusNumbers,
  addBusNumber,
  removeBusNumber,
} from "../controllers/collegeController";

const router = express.Router();

router.post("/", createCollege);
router.get("/", getAllColleges);
router.get("/:id", getCollege);

// Bus Number Management
router.get("/:collegeId/bus-numbers", getBusNumbers);
router.post("/bus-numbers", addBusNumber);
router.delete("/:collegeId/bus-numbers/:busNumber", removeBusNumber);

export default router;
