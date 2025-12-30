# AD1: User Registration and Approval Process

**Activity Diagram ID:** AD1  
**Process Name:** User Registration and Approval  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This activity diagram models the complete user onboarding workflow from initial registration through account activation. It covers different paths based on email domain validation, manual approval requirements, and OTP verification.

---

## 2. Actors / Roles

| Role                                 | Participation                                    |
| ------------------------------------ | ------------------------------------------------ |
| User (Student/Teacher/Driver/Parent) | Initiates registration                           |
| Mobile Application                   | Validates input, communicates with backend       |
| Backend Server                       | Processes registration, evaluates approval rules |
| Admin                                | Reviews and approves/rejects pending accounts    |

---

## 3. Mermaid Diagram

```mermaid
flowchart TD
    A([Start]) --> B[User opens app]
    B --> C[Select Register]
    C --> D[Display registration form]
    D --> E[User enters details]
    E --> F{Input valid?}

    F -- No --> G[Display validation errors]
    G --> E

    F -- Yes --> H[Send POST /api/auth/register]
    H --> I{Email exists?}

    I -- Yes --> J[Return 409 Conflict]
    J --> K[Display error message]
    K --> E

    I -- No --> L[Extract email domain]
    L --> M{Domain in allowed list?}

    M -- Yes --> N[Set approved=true]
    M -- No --> O[Set needsManualApproval=true]

    N --> P[Create User document]
    O --> P

    P --> Q[Generate OTP]
    Q --> R[Send OTP via email]
    R --> S[Return success response]
    S --> T[Navigate to OTP screen]
    T --> U[User enters OTP]
    U --> V[Send POST /api/auth/verify-otp]
    V --> W{OTP valid?}

    W -- No --> X[Display Invalid OTP]
    X --> U

    W -- Yes --> Y[Set emailVerified=true]
    Y --> Z{Needs approval?}

    Z -- No --> AA[Navigate to Login]
    Z -- Yes --> AB[Display Pending Approval message]

    AB --> AC[Admin views pending users]
    AC --> AD[Admin reviews details]
    AD --> AE{Approve or Reject?}

    AE -- Approve --> AF[Set approved=true]
    AE -- Reject --> AG[Flag/delete user]

    AF --> AH[Send approval notification]
    AG --> AI[Send rejection notification]

    AH --> AJ([End - User can login])
    AI --> AK([End - Registration rejected])
    AA --> AJ
```

---

## 4. Notes / Conditions

### Preconditions

- Mobile application is installed
- Backend server is operational

### Postconditions

- User account exists in database with appropriate approval status

### Exceptional Flows

- **Network Failure:** App displays retry option
- **OTP Expiry:** User can request new OTP

---

## 5. Modules / Components Represented

| Component          | Activities                                 |
| ------------------ | ------------------------------------------ |
| Flutter Mobile App | Form display, input validation, navigation |
| Node.js Backend    | Registration processing, OTP generation    |
| MongoDB            | User document storage                      |
| Email Service      | OTP delivery                               |
| FCM                | Approval notifications                     |
