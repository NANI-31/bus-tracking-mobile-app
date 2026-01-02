import Route from "../models/Route";
import { Bus } from "../models/Bus";
import Schedule from "../models/Schedule";
// Helper to generate dummy coordinates
const generateGeo = (index: number) => {
  const baseLat = 16.3067;
  const baseLng = 80.4365;
  return {
    lat: baseLat + (Math.random() - 0.5) * 0.1,
    lng: baseLng + (Math.random() - 0.5) * 0.1,
  };
};

export const seedTransport = async (
  collegeId: string,
  coordinatorId: string,
  routesData: any[],
  domain: string,
  drivers: any[]
) => {
  console.log(`Seeding Transport for college with domain ${domain}...`);

  const numBuses = routesData.length;

  for (let i = 1; i <= numBuses; i++) {
    // 1. Get Route Data (static or fallback)
    const staticRoute = routesData[i - 1];
    const busNumber = staticRoute.busNumber;
    const routeName = staticRoute.routeName;
    const stops = staticRoute.stops;

    // 1. Get Pre-seeded Driver (Only for first bus)
    const driver = i === 1 ? drivers[0] : null;
    const driverId = driver ? driver._id : null;

    // 2. Prepare Stops with Geo
    const stopPoints = stops.map((stop: string | any, idx: number) => {
      const name = typeof stop === "string" ? stop : stop.location;
      return {
        name,
        location: generateGeo(idx),
      };
    });

    const startPoint = { ...stopPoints[0] };
    const endPoint = { ...stopPoints[stopPoints.length - 1] };

    // 3. Create Route
    const route = await Route.create({
      routeName: routeName,
      routeType: "pickup",
      startPoint,
      endPoint,
      stopPoints,
      collegeId: collegeId,
      createdBy: coordinatorId,
      isActive: true,
    });

    // 4. Create Bus
    const statuses = ["on-time", "delayed", "not-running"];
    const randomStatus = statuses[Math.floor(Math.random() * statuses.length)];

    const bus = await Bus.create({
      busNumber: busNumber,
      driverId: null,
      routeId: route._id,
      defaultRouteId: route._id,
      collegeId: collegeId,
      isActive: true,
      status: randomStatus,
    });

    // 5. Create Schedule
    await Schedule.create({
      routeId: route._id,
      busId: bus._id,
      shift: "1st",
      collegeId: collegeId,
      createdBy: coordinatorId,
      isActive: true,
      stopSchedules: stopPoints.map((stop: any, idx: number) => ({
        stopName: stop.name,
        arrivalTime: `08:${10 + idx * 5}`,
        departureTime: `08:${12 + idx * 5}`,
      })),
    });

    console.log(`Seeded Route: ${busNumber}`);
  }

  console.log("Transport seeding complete.");
};
