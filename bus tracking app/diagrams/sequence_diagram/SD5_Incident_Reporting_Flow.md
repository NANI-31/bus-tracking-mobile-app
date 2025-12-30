# SD5: Incident Reporting Flow

**Sequence Diagram ID:** SD5  
**Scenario Name:** Incident Reporting Flow  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This sequence diagram models the workflow when a Driver (or Student) reports an incident through the mobile application. It covers incident submission, persistence, and immediate escalation via push notification to Coordinators.

---

## 2. Actors & Objects

| Participant         | Type     | Description                          |
| ------------------- | -------- | ------------------------------------ |
| Driver              | Actor    | User reporting the incident          |
| DriverApp           | System   | Driver's Flutter mobile app          |
| IncidentController  | Backend  | Express controller for incident CRUD |
| IncidentModel       | Database | Incident collection in MongoDB       |
| NotificationService | Service  | Sends alerts to Coordinators         |
| CoordinatorApp      | System   | Coordinator's mobile app             |
| Coordinator         | Actor    | Recipient of incident alert          |

---

## 3. Mermaid Diagram

```mermaid
sequenceDiagram
    autonumber
    participant Driver
    participant DriverApp as Driver App
    participant IncidentController as Incident Controller
    participant IncidentModel as Incident (MongoDB)
    participant NotificationService as Notification Service
    participant CoordinatorApp as Coordinator App
    participant Coordinator

    Driver->>DriverApp: Navigate to "Report Incident"
    DriverApp-->>Driver: Display incident form

    Driver->>DriverApp: Select type, enter description, set severity
    Driver->>DriverApp: Tap "Submit"

    DriverApp->>DriverApp: Capture current GPS location

    DriverApp->>IncidentController: POST /api/incidents {type, description, severity, location, busId}

    IncidentController->>IncidentController: Validate payload
    IncidentController->>IncidentModel: insertOne({...payload, status: "open", reporterId})
    IncidentModel-->>IncidentController: Created incident document

    IncidentController->>NotificationService: notifyCoordinators(incident)

    par Notify All Coordinators
        NotificationService->>NotificationService: Fetch coordinators for collegeId
        NotificationService->>CoordinatorApp: FCM push notification
    end

    IncidentController-->>DriverApp: 201 {message: "Incident reported", incidentId}
    DriverApp-->>Driver: Display "Incident reported successfully"

    CoordinatorApp->>CoordinatorApp: Display system notification
    Coordinator->>CoordinatorApp: Tap notification
    CoordinatorApp->>CoordinatorApp: Navigate to incident details
    CoordinatorApp-->>Coordinator: View incident and take action
```

---

## 4. Alternative Flows / Exceptions

| Scenario                      | Handling                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------ |
| Location Unavailable          | Incident submitted without location; logged with `location: null`              |
| SOS Emergency                 | Pre-selects "Critical" severity; triggers immediate high-priority notification |
| Coordinator Resolves Incident | Updates `status` to "resolved"; Reporter receives notification                 |

---

## 5. Modules / Components Represented

| Component            | File/Location                                    |
| -------------------- | ------------------------------------------------ |
| Driver App           | `lib/screens/shared/report_incident_screen.dart` |
| Incident Controller  | `src/controllers/incidentController.ts`          |
| Incident Model       | `src/models/Incident.ts`                         |
| Notification Service | `src/services/notificationService.ts`            |
| Coordinator App      | `lib/screens/coordinator/`                       |

---

## 6. Notes / Considerations

- **Parallel Notification:** The `par` block indicates that notifications are sent to all coordinators concurrently.
- **Incident Lifecycle:** `status` transitions: `open` → `investigating` → `resolved`.
- **Priority Handling:** "Critical" incidents may trigger additional channels (SMS, email).
