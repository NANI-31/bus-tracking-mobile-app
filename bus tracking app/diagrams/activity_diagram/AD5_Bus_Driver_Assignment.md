# AD5: Bus-Driver Assignment Process

**Activity Diagram ID:** AD5  
**Process Name:** Bus-Driver Assignment  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This activity diagram models the workflow for a Coordinator to assign a Driver to a Bus, and the subsequent Driver response (accept/reject).

---

## 2. Actors / Roles

| Role                 | Participation          |
| -------------------- | ---------------------- |
| Coordinator          | Creates the assignment |
| Backend Server       | Processes assignment   |
| Driver               | Responds to assignment |
| Notification Service | Sends alerts           |

---

## 3. Mermaid Diagram

```mermaid
flowchart TD
    A([Start]) --> B[Coordinator navigates to Buses]
    B --> C[Display list of buses]
    C --> D[Select unassigned bus]
    D --> E[Display driver selection modal]
    E --> F[Select a driver]
    F --> G{Assign route?}

    G -- Yes --> H[Select route]
    G -- No --> I[Skip route selection]

    H --> J[Tap Confirm Assignment]
    I --> J

    J --> K[Send PUT /api/buses/:busId/assign]
    K --> L{Driver already assigned?}

    L -- Yes --> M[Display conflict warning]
    M --> N{Coordinator confirms?}
    N -- No --> E
    N -- Yes --> O[Proceed with assignment]

    L -- No --> O

    O --> P[Update Bus document - status: pending]
    P --> Q[Create BusAssignmentLog entry]
    Q --> R[Send FCM to Driver]
    R --> S[Return success to Coordinator]
    S --> T[Display 'Awaiting response']

    T --> U[Driver receives notification]
    U --> V[Driver views assignment details]
    V --> W{Driver decision?}

    W -- Accept --> X[Send PUT /api/buses/:busId/accept]
    X --> Y[Update Bus status: accepted]
    Y --> Z[Update AssignmentLog: accepted]
    Z --> AA[Send FCM to Coordinator]
    AA --> AB[Display bus details to Driver]
    AB --> AC([End - Assignment active])

    W -- Reject --> AD[Send PUT /api/buses/:busId/reject]
    AD --> AE[Clear Bus driverId]
    AE --> AF[Update AssignmentLog: rejected]
    AF --> AG[Send FCM to Coordinator]
    AG --> AH[Display rejection, prompt new driver]
    AH --> E
```

---

## 4. Notes / Conditions

### Preconditions

- Coordinator has appropriate role
- Bus and Driver exist in system

### Postconditions

- Assignment logged with outcome
- Both parties notified

### Exceptional Flows

- **Timeout:** Auto-reject after configured period
- **Cancel:** Coordinator can cancel pending assignment

---

## 5. Modules / Components Represented

| Component               | Activities                    |
| ----------------------- | ----------------------------- |
| Flutter Coordinator App | Assignment UI                 |
| Flutter Driver App      | Response UI                   |
| Node.js Backend         | Assignment logic              |
| MongoDB                 | Bus and AssignmentLog storage |
| FCM                     | Notifications                 |
