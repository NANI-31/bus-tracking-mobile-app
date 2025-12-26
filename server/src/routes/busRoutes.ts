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

const router = express.Router();

router.post("/", createBus);
router.get("/", getAllBuses);
router.get("/college/:collegeId/locations", getCollegeBusLocations);
router.get("/:id", getBus);
router.put("/:id", updateBus);
router.delete("/:id", deleteBus);
router.post("/location", updateBusLocation);
router.get("/:busId/location", getBusLocation);

export default router;
