import { Router } from "express";
import * as CollegeAdminController from "../controllers/collegeAdmin.controller";
import { protect, collegeAdminOnly } from "../middleware/authMiddleware";

const router = Router();

// All routes here require being a logged-in College Admin (or Super Admin)
router.use(protect, collegeAdminOnly);

router.get("/stats", CollegeAdminController.getCollegeStats);
router.get("/users", CollegeAdminController.getCollegeUsers);
router.put("/settings", CollegeAdminController.updateCollegeSettings);

export default router;
