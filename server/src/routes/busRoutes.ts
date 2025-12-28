import express from "express";
import {
  createBus,
  getBus,
  getAllBuses,
  updateBusLocation,
  getBusLocation,
  getCollegeBusLocations,
  updateBus,
  deleteBus,
} from "../controllers/busController";

import { protect, authorize } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/", protect, authorize("admin", "busCoordinator"), createBus);
router.get("/", protect, getAllBuses);
router.get("/college/:collegeId/locations", protect, getCollegeBusLocations);
router.get("/:id", protect, getBus);
router.put(
  "/:id",
  protect,
  authorize("admin", "busCoordinator", "driver"),
  updateBus
);
router.delete("/:id", protect, authorize("admin", "busCoordinator"), deleteBus);
router.post(
  "/location",
  protect,
  authorize("driver", "busCoordinator"),
  updateBusLocation
);
router.get("/:busId/location", protect, getBusLocation);

export default router;
