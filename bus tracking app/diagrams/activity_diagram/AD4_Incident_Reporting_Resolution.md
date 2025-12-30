# AD4: Incident Reporting and Resolution Process

**Activity Diagram ID:** AD4  
**Process Name:** Incident Reporting and Resolution  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This activity diagram models the workflow for reporting and resolving incidents within the bus tracking system. It covers submission, Coordinator review, escalation, and resolution.

---

## 2. Actors / Roles

| Role             | Participation                  |
| ---------------- | ------------------------------ |
| Driver / Student | Reports the incident           |
| Backend Server   | Processes and stores incident  |
| Coordinator      | Reviews and resolves incidents |
| Admin            | Handles escalated incidents    |

---

## 3. Mermaid Diagram

```mermaid
flowchart TD
    A([Start]) --> B[Reporter navigates to Report Incident]
    B --> C[Display incident form]
    C --> D[Select incident type]
    D --> E[Enter description]
    E --> F[Select severity level]
    F --> G[Tap Submit]
    G --> H[Capture current GPS location]
    H --> I[Send POST /api/incidents]

    I --> J[Backend validates payload]
    J --> K[Create Incident document - status: open]
    K --> L[Log to History collection]

    L --> M{Severity = Critical?}
    M -- Yes --> N[Send high-priority FCM to Admins + Coordinators]
    M -- No --> O[Send normal FCM to Coordinators]

    N --> P[Return success response]
    O --> P

    P --> Q[Display 'Incident reported successfully']
    Q --> R[Coordinator receives notification]
    R --> S[Coordinator views incident details]
    S --> T[Tap 'Start Investigation']
    T --> U[Update status to investigating]
    U --> V[Notify reporter of status change]

    V --> W{Can Coordinator resolve?}
    W -- Yes --> X[Take action and tap Resolve]
    W -- No --> Y[Tap Escalate]

    Y --> Z[Update status to escalated]
    Z --> AA[Send FCM to Admin]
    AA --> AB[Admin reviews and resolves]
    AB --> AC[Update status to resolved]

    X --> AD[Enter resolution notes]
    AD --> AE[Update status to resolved]

    AC --> AF[Send resolution notification to reporter]
    AE --> AF

    AF --> AG[Reporter receives notification]
    AG --> AH([End - Incident resolved])
```

---

## 4. Notes / Conditions

### Preconditions

- Reporter is authenticated
- Incident has occurred

### Postconditions

- Incident logged and resolved
- All parties notified

### Exceptional Flows

- **Reopen:** Resolved incident can be reopened
- **Auto-Escalation:** Critical incidents auto-escalate after timeout

---

## 5. Modules / Components Represented

| Component          | Activities                    |
| ------------------ | ----------------------------- |
| Flutter Mobile App | Incident form, status display |
| Node.js Backend    | Incident CRUD, status updates |
| MongoDB            | Incident and History storage  |
| FCM                | Alert notifications           |
