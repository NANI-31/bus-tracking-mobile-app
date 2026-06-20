import { Request, Response } from "express";
import logger from "@/utils/logger";
import SystemConfig from "@/models/SystemConfig.model";

const apiKey = process.env.DIRECTION_MAP || "";

const incrementApiCount = async (apiType: "autocomplete" | "details" | "reverseGeocode") => {
  try {
    const specificKeys = {
      autocomplete: "googleAutocompleteCount",
      details: "googlePlaceDetailsCount",
      reverseGeocode: "googleGeocodingCount",
    };
    const specificKey = specificKeys[apiType];

    await Promise.all([
      SystemConfig.findOneAndUpdate(
        { key: "googleApiUsageCount" },
        { 
          $inc: { value: 1 },
          $setOnInsert: { 
            dataType: "number", 
            isPublic: false, 
            isEditable: false,
            description: "Total Google Maps API calls made by the system",
            category: "usage"
          } 
        },
        { upsert: true }
      ),
      SystemConfig.findOneAndUpdate(
        { key: specificKey },
        { 
          $inc: { value: 1 },
          $setOnInsert: { 
            dataType: "number", 
            isPublic: false, 
            isEditable: false,
            description: `Total Google Maps ${apiType} API calls`,
            category: "usage"
          } 
        },
        { upsert: true }
      )
    ]);
  } catch (err) {
    logger.error("[PlacesController] Failed to increment googleApiUsageCount:", err);
  }
};

export const getAutocomplete = async (req: Request, res: Response) => {
  try {
    const { input, sessiontoken } = req.query;
    if (!input) {
      return res.status(400).json({ message: "Input query parameter is required" });
    }

    if (!apiKey) {
      logger.error("[PlacesController] Google Maps API key (DIRECTION_MAP) is missing in .env");
      return res.status(500).json({ message: "API key is not configured" });
    }

    const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(
      input as string
    )}&sessiontoken=${encodeURIComponent((sessiontoken || "") as string)}&types=geocode&key=${apiKey}`;

    await incrementApiCount("autocomplete");
    const response = await fetch(url);
    if (!response.ok) {
      return res.status(response.status).json({ message: `Google API error: ${response.statusText}` });
    }

    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    logger.error("[PlacesController] Autocomplete error:", error);
    return res.status(500).json({ message: (error as Error).message });
  }
};

export const getPlaceDetails = async (req: Request, res: Response) => {
  try {
    const { placeId, sessiontoken } = req.query;
    if (!placeId) {
      return res.status(400).json({ message: "placeId query parameter is required" });
    }

    if (!apiKey) {
      logger.error("[PlacesController] Google Maps API key (DIRECTION_MAP) is missing in .env");
      return res.status(500).json({ message: "API key is not configured" });
    }

    const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(
      placeId as string
    )}&fields=geometry%2Cformatted_address&sessiontoken=${encodeURIComponent((sessiontoken || "") as string)}&key=${apiKey}`;

    await incrementApiCount("details");
    const response = await fetch(url);
    if (!response.ok) {
      return res.status(response.status).json({ message: `Google API error: ${response.statusText}` });
    }

    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    logger.error("[PlacesController] Place details error:", error);
    return res.status(500).json({ message: (error as Error).message });
  }
};

export const getReverseGeocode = async (req: Request, res: Response) => {
  try {
    const { lat, lng } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ message: "lat and lng query parameters are required" });
    }

    if (!apiKey) {
      logger.error("[PlacesController] Google Maps API key (DIRECTION_MAP) is missing in .env");
      return res.status(500).json({ message: "API key is not configured" });
    }

    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&result_type=street_address|route|neighborhood|sublocality|locality&key=${apiKey}`;

    await incrementApiCount("reverseGeocode");
    const response = await fetch(url);
    if (!response.ok) {
      return res.status(response.status).json({ message: `Google API error: ${response.statusText}` });
    }

    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    logger.error("[PlacesController] Reverse geocode error:", error);
    return res.status(500).json({ message: (error as Error).message });
  }
};
