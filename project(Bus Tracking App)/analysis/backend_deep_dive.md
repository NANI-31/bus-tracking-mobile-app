# Backend Deep Dive

-> rule 6 is executed

## Core Logic: Socket.IO & Real-time Tracking (`server/src/socket.ts`)

The server uses a highly optimized real-time communication strategy:

- **Write-Behind Buffer**: Location updates are stored in a `Map` and flushed to MongoDB every 10 seconds to minimize database overhead.
- **Redis Adapter**: Enables horizontal scaling of Socket.IO across multiple server instances.
- **Room Strategy**:
  - `collegeId`: For role-based tracking within a college.
  - `${collegeId}_coordinators`: For SOS alerts and administrative updates.
  - `global_tracking`: For Super Admin overview.
- **Grace Period**: Drivers have a 30-second window to reconnect before being marked as "offline," preventing flicker during backgrounding or minor network drops.

## Data Models (`server/src/models/`)

- **User**: Complex role system with support for 8 distinct roles. Includes GeoJSON `2dsphere` index for stop location proximity.
- **Bus**: Links buses to routes and colleges.
- **BusLocation**: Stores historical and capped live location data.
- **Sos**: Manages alert lifecycle from trigger to resolution.

## API Structure

- **Controllers**: Handle business logic, though there is a move towards a `Service` layer.
- **Middleware**: Includes `authenticateSocket` and standard Express auth middleware.
- **Validation**: Role-based access control (RBAC) is enforced at the route level.
