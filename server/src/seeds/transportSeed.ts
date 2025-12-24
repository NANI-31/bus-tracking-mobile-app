import Route from "../models/Route";
import { Bus } from "../models/Bus";
import Schedule from "../models/Schedule";
import User from "../models/User";
import crypto from "crypto";

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
  routesData: any[]
) => {
  console.log("Seeding Transport (Routes, Buses, Schedules)...");

  // Clear existing
  await Route.deleteMany({});
  await Bus.deleteMany({});
  await Schedule.deleteMany({});

  for (const routeData of routesData) {
    // 1. Create Driver
    const driverId = crypto.randomUUID();
    await User.create({
      _id: driverId,
      fullName: `Driver ${routeData.busNumber}`,
      email: `driver${routeData.busNumber
        .toLowerCase()
        .replace(/[^\w]/g, "")}@kkr.ac.in`,
      password: "password_hash",
      role: "driver",
      collegeId: collegeId,
      approved: true,
      emailVerified: true,
    });

    // 2. Prepare Stops with Geo
    const stopPoints = routeData.stops.map(
      (stop: string | any, idx: number) => {
        const name = typeof stop === "string" ? stop : stop.location;
        return {
          name,
          location: generateGeo(idx),
        };
      }
    );

    const startPoint = { ...stopPoints[0] };
    const endPoint = { ...stopPoints[stopPoints.length - 1] };

    // 3. Create Route
    const route = await Route.create({
      routeName: routeData.routeName,
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
      busNumber: routeData.busNumber,
      driverId: driverId,
      routeId: route._id,
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

    console.log(`Seeded Route: ${routeData.busNumber}`);
  }

  console.log("Transport seeding complete.");
};
