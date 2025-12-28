import { Server } from "socket.io";

interface SimulatedBus {
  busId: string;
  route: { lat: number; lng: number }[];
  currentIndex: number;
  interval: NodeJS.Timeout | null;
}

const activeSimulations: Map<string, SimulatedBus> = new Map();

// Hardcoded route coordinates for Bus 9 (Simulation)
// Starting from KKR & KSR Institute area (approx route)
const SIMULATION_ROUTE = [
  { lat: 16.2345, lng: 80.4567 },
  { lat: 16.235, lng: 80.457 },
  { lat: 16.2355, lng: 80.4573 },
  { lat: 16.236, lng: 80.4576 },
  { lat: 16.2365, lng: 80.458 },
  { lat: 16.237, lng: 80.4583 },
  { lat: 16.2375, lng: 80.4586 },
  { lat: 16.238, lng: 80.459 },
  { lat: 16.2385, lng: 80.4593 },
  { lat: 16.239, lng: 80.4596 },
  // Loop back or continue
];

export const startSimulation = (
  io: Server,
  busId: string,
  collegeId: string
) => {
  if (activeSimulations.has(busId)) {
    console.log(`Simulation already running for bus ${busId}`);
    return;
  }

  console.log(`Starting simulation for bus ${busId}`);

  const simulation: SimulatedBus = {
    busId,
    route: SIMULATION_ROUTE,
    currentIndex: 0,
    interval: null,
  };

  simulation.interval = setInterval(() => {
    if (simulation.currentIndex >= simulation.route.length) {
      simulation.currentIndex = 0; // Loop the route
    }

    const location = simulation.route[simulation.currentIndex];

    const updateData = {
      busId,
      collegeId,
      location,
      speed: 40, // Simulated speed km/h
      heading: 0, // Simplified heading
      timestamp: new Date().toISOString(),
    };

    // Emit to college room
    io.to(collegeId).emit("location_updated", updateData);

    // Log occasionally
    if (simulation.currentIndex % 5 === 0) {
      console.log(`[SIM] Bus ${busId} at ${location.lat}, ${location.lng}`);
    }

    simulation.currentIndex++;
  }, 1000); // 1 update per second

  activeSimulations.set(busId, simulation);
};

export const stopSimulation = (busId: string) => {
  const simulation = activeSimulations.get(busId);
  if (simulation) {
    if (simulation.interval) {
      clearInterval(simulation.interval);
    }
    activeSimulations.delete(busId);
    console.log(`Stopped simulation for bus ${busId}`);
  }
};
