import express from "express";
import {
  getAutocomplete,
  getPlaceDetails,
  getReverseGeocode,
} from "../../controllers/core/places.controller";
import { protect } from "@/middleware/authMiddleware";

const router = express.Router();

router.get("/autocomplete", protect, getAutocomplete);
router.get("/details", protect, getPlaceDetails);
router.get("/reverse-geocode", protect, getReverseGeocode);

export default router;
