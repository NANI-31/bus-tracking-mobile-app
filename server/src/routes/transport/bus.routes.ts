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
} from "../../controllers/transport/bus.controller";

import { protect, authorize } from "@/middleware/authMiddleware";

const router = express.Router();

router.post(
  "/",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  createBus,
);
router.get("/", protect, getAllBuses);
router.get("/college/:collegeId/locations", protect, getCollegeBusLocations);
router.get("/:id", protect, getBus);
router.put(
  "/:id",
  protect,
  authorize("admin", "busCoordinator", "driver", "collegeAdmin"),
  updateBus,
);
router.delete(
  "/:id",
  protect,
  authorize("admin", "busCoordinator", "collegeAdmin"),
  deleteBus,
);
router.post(
  "/location",
  protect,
  authorize("driver", "busCoordinator", "collegeAdmin"),
  updateBusLocation,
);
router.get("/:busId/location", protect, getBusLocation);

export default router;
