# DFD1: Main Processes (Level 1)

**DFD ID:** DFD1  
**Level:** 1  
**System:** College Bus Tracking System  
**Version:** 1.0  
**Date:** 2025-12-30

---

## 1. Purpose

The Level 1 DFD explodes the single "System" process from the Context Diagram into its major functional subprocesses. It illustrates how data moves between these core processes and the system's data stores.

---

## 2. Processes

| Process ID | Process Name         | Description                                                               |
| ---------- | -------------------- | ------------------------------------------------------------------------- |
| **1.0**    | Manage User Auth     | Handles registration, login, approval, and session management.            |
| **2.0**    | Track Live Buses     | Processes GPS streams, updates locations, and broadcasts to listeners.    |
| **3.0**    | Manage Resources     | Handles CRUD operations for buses, routes, and stops.                     |
| **4.0**    | Handle Notifications | Triggers and dispatches alerts for proximity, assignments, and incidents. |
| **5.0**    | Manage Incidents     | Processes incident reports and escalation workflows.                      |

---

## 3. Data Stores

| Store ID | Name        | Contents                                             |
| -------- | ----------- | ---------------------------------------------------- |
| **D1**   | User DB     | Profiles, credentials, roles, tokens.                |
| **D2**   | Bus DB      | Bus static data, current status, driver assignments. |
| **D3**   | Route DB    | Route paths, stop coordinates, schedules.            |
| **D4**   | History DB  | Trip logs, location history (time-series).           |
| **D5**   | Incident DB | Incident reports, investigation logs.                |

---

## 4. Mermaid Diagram

```mermaid
flowchart TB
    %% External Entities
    User[User]
    Driver[Driver]
    Coord[Coordinator]

    %% Processes
    P1((1.0 \n Manage \n Auth))
    P2((2.0 \n Track \n Live Buses))
    P3((3.0 \n Manage \n Resources))
    P4((4.0 \n Handle \n Notifications))
    P5((5.0 \n Manage \n Incidents))

    %% Data Stores
    D1[(D1 \n User DB)]
    D2[(D2 \n Bus DB)]
    D3[(D3 \n Route DB)]
    D4[(D4 \n History DB)]
    D5[(D5 \n Incident DB)]

    %% Flows - Auth
    User -->|Credentials| P1
    P1 <-->|Read/Write Profile| D1
    P1 -->|Session Token| User

    %% Flows - Tracking
    Driver -->|GPS Stream| P2
    P2 -->|Update Location| D2
    P2 -->|Log History| D4
    P2 -->|Broadcast Location| User
    P3 -.->|Route Info| P2

    %% Flows - Resources
    Coord -->|Bus/Route Data| P3
    P3 <-->|CRUD| D2
    P3 <-->|CRUD| D3

    %% Flows - Notifications
    P2 -->|Proximity Event| P4
    P5 -->|Incident Alert| P4
    P4 -->|FCM Payload| User
    P4 <-->|Fetch Tokens| D1

    %% Flows - Incidents
    Driver -->|Report Incident| P5
    P5 <-->|Log Incident| D5
    P5 -->|Status Update| Coord
```

---

## 5. Notes / Considerations

- **Process Integration:** Process 2.0 (Tracking) provides real-time triggers to Process 4.0 (Notifications) for proximity alerts.
- **Data Persistence:** Location updates are transient in memory (Socket.IO) but periodically persisted to D4 (History DB) for analytics.
- **Access Control:** All processes implicitly interact with Process 1.0 (Auth) to validate permissions before execution.
