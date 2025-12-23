import express from "express";
import {
  createRoute,
  getRoute,
  getRoutesByCollege,
} from "../controllers/routeController";

const router = express.Router();

router.post("/", createRoute);
router.get("/college/:collegeId", getRoutesByCollege);
router.get("/:id", getRoute);

export default router;
