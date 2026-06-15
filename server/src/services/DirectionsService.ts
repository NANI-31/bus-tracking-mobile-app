import { IRoute } from "@/models/Route.model";
import logger from "@/utils/logger";
import SystemConfig from "@/models/SystemConfig.model";

export interface LegInfo {
  startAddress: string;
  endAddress: string;
  distanceKm: number;
  durationMin: number;
}

export interface DirectionsResult {
  polylinePoints: { latitude: number; longitude: number }[];
  totalDistanceKm: number;
  totalDurationMin: number;
  legs: LegInfo[];
}

export class DirectionsService {
  private static apiKey = process.env.DIRECTION_MAP || "";

  /**
   * Fetch directions from Google Directions API for a Route model.
   */
  public static async getDirectionsForRoute(route: IRoute): Promise<DirectionsResult | null> {
    if (!this.apiKey) {
      logger.error("[DirectionsService] Google Maps API key (DIRECTION_MAP) is missing in .env");
      return null;
    }

    const start = route.startPoint.location;
    const end = route.endPoint.location;

    if (!start.lat || !start.lng || !end.lat || !end.lng) {
      logger.warn(`[DirectionsService] Route ${route._id} has invalid start/end coordinates`);
      return null;
    }

    const origin = `${start.lat},${start.lng}`;
    const destination = `${end.lat},${end.lng}`;

    let url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&mode=driving&key=${this.apiKey}`;

    // Add waypoints (stops)
    if (route.stopPoints && route.stopPoints.length > 0) {
      const validStops = route.stopPoints
        .filter(s => s.location && s.location.lat && s.location.lng)
        .map(s => `${s.location.lat},${s.location.lng}`);
      
      if (validStops.length > 0) {
        url += `&waypoints=${encodeURIComponent(validStops.join("|"))}`;
      }
    }

    try {
      logger.info(`[DirectionsService] Fetching directions from Google for route ${route._id}`);
      
      // Increment Google Maps API Usage Count in DB
      try {
        await SystemConfig.findOneAndUpdate(
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
        );
      } catch (err) {
        logger.error("[DirectionsService] Failed to increment googleApiUsageCount:", err);
      }

      const response = await fetch(url);
      if (!response.ok) {
        logger.error(`[DirectionsService] HTTP error: ${response.status} ${response.statusText}`);
        return null;
      }

      const data = await response.json() as any;
      if (data.status !== "OK") {
        logger.error(`[DirectionsService] Google API returned status: ${data.status}`);
        return null;
      }

      const apiRoute = data.routes[0];
      const overviewPolyline = apiRoute?.overview_polyline?.points;
      if (!overviewPolyline) {
        logger.error(`[DirectionsService] No overview polyline returned for route ${route._id}`);
        return null;
      }

      // Decode the polyline points
      const polylinePoints = this.decodePolyline(overviewPolyline);

      // Parse legs and totals
      const legsData = apiRoute.legs || [];
      let totalDistanceM = 0;
      let totalDurationS = 0;
      const legs: LegInfo[] = [];

      for (const leg of legsData) {
        const distanceM = leg.distance?.value || 0;
        const durationS = leg.duration?.value || 0;
        
        totalDistanceM += distanceM;
        totalDurationS += durationS;

        legs.push({
          startAddress: leg.start_address || "",
          endAddress: leg.end_address || "",
          distanceKm: distanceM / 1000.0,
          durationMin: Math.ceil(durationS / 60.0),
        });
      }

      return {
        polylinePoints,
        totalDistanceKm: totalDistanceM / 1000.0,
        totalDurationMin: Math.ceil(totalDurationS / 60.0),
        legs,
      };
    } catch (error) {
      logger.error(`[DirectionsService] Error fetching directions:`, error);
      return null;
    }
  }

  /**
   * Decodes Google's Encoded Polyline Format into coordinate points.
   */
  private static decodePolyline(encoded: string): { latitude: number; longitude: number }[] {
    const points: { latitude: number; longitude: number }[] = [];
    let index = 0;
    const len = encoded.length;
    let lat = 0;
    let lng = 0;

    while (index < len) {
      let b;
      let shift = 0;
      let result = 0;
      
      do {
        b = encoded.charCodeAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      const dlat = (result & 1) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = encoded.charCodeAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      const dlng = (result & 1) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.push({
        latitude: lat / 1e5,
        longitude: lng / 1e5,
      });
    }

    return points;
  }
}
