# DFD2: Track Live Buses (Level 2)

**DFD ID:** DFD2.0  
**Level:** 2 (Explosion of Process 2.0)  
**Process:** Track Live Buses  
**Version:** 1.0  
**Date:** 2025-12-30

---

## 1. Purpose

This Level 2 DFD details the internal data flows of the "Track Live Buses" process. It shows how raw GPS data from drivers is validated, processed for ETA calculations, broadcasted to users, and archived.

---

## 2. Processes

| Process ID | Process Name      | Description                                                         |
| ---------- | ----------------- | ------------------------------------------------------------------- |
| **2.1**    | Validate GPS Data | Checks for valid coordinates, timestamp, and active driver session. |
| **2.2**    | Update Bus State  | Updates the current location and heading in memory/database.        |
| **2.3**    | Calculate ETA     | Computes estimated arrival time for next stops based on distance.   |
| **2.4**    | Check Proximity   | Determines if the bus has entered a geofence (500m) of a stop.      |
| **2.5**    | Broadcast Update  | Emits the processed location event to subscribed socket rooms.      |

---

## 3. Data Stores & External

| ID        | Name           | Type                          |
| --------- | -------------- | ----------------------------- |
| **D2**    | Bus DB         | Data Store (Current State)    |
| **D3**    | Route DB       | Data Store (Stop Coordinates) |
| **D4**    | History DB     | Data Store (Archival)         |
| **Users** | Student/Parent | External Entity (Subscribers) |

---

## 4. Mermaid Diagram

```mermaid
flowchart TB
    %% External Inputs
    Driver[Driver App]

    %% Processes
    P2_1((2.1 \n Validate \n GPS Data))
    P2_2((2.2 \n Update \n Bus State))
    P2_3((2.3 \n Calculate \n ETA))
    P2_4((2.4 \n Check \n Proximity))
    P2_5((2.5 \n Broadcast \n Update))

    %% Stores
    D2[(D2 \n Bus DB)]
    D3[(D3 \n Route DB)]
    D4[(D4 \n History DB)]

    %% External Output
    Subscribers[Socket Subscribers]
    NotifService[[Notification Service]]

    %% Flows
    Driver -->|Raw GPS Packet| P2_1

    P2_1 -->|Valid Data| P2_2
    P2_1 -->|Invalid Data| Discard[Discard]

    P2_2 -->|Current Location| D2
    P2_2 -->|Location Log| D4
    P2_2 -->|State Changed| P2_3

    D3 -.->|Stop Locations| P2_3
    P2_3 -->|ETA List| P2_4
    P2_3 -->|ETA Value| P2_5

    P2_4 -->|Triggers| NotifService
    D3 -.->|Geofence Data| P2_4

    P2_2 -->|Position Data| P2_5
    P2_5 -->|Socket Event| Subscribers
```

---

## 5. Notes / Considerations

- **Latency:** Critical path (2.1 -> 2.2 -> 2.5) must occur in sub-second time for "real-time" feel.
- **Geofencing:** Process 2.4 compares current Lat/Lng against Stop Lat/Lng from D3 (Route DB).
- **Optimization:** ETA calculation (2.3) may be rate-limited (e.g., every 30s) rather than every GPS tick to save resources.
