import express from "express";
import {
  createBus,
  getBus,
  getAllBuses,
  updateBusLocation,
  getBusLocation,
} from "../controllers/busController";

const router = express.Router();

router.post("/", createBus);
router.get("/", getAllBuses);
router.get("/:id", getBus);
router.post("/location", updateBusLocation);
router.get("/:busId/location", getBusLocation);

export default router;
