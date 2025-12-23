import express from "express";
import {
  createCollege,
  getCollege,
  getAllColleges,
} from "../controllers/collegeController";

const router = express.Router();

router.post("/", createCollege);
router.get("/", getAllColleges);
router.get("/:id", getCollege);

export default router;
