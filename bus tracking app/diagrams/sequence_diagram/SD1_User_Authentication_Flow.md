# SD1: User Authentication Flow

**Sequence Diagram ID:** SD1  
**Scenario Name:** User Authentication Flow  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This sequence diagram illustrates the complete authentication flow for users (Student, Teacher, Driver, Admin) logging into the College Bus Tracking System. It shows the interaction between the mobile application, backend API, and database, including credential validation and JWT token generation.

---

## 2. Actors & Objects

| Participant    | Type     | Description                            |
| -------------- | -------- | -------------------------------------- |
| User           | Actor    | Any user attempting to login           |
| MobileApp      | System   | Flutter mobile application             |
| AuthController | Backend  | Express controller handling auth logic |
| UserModel      | Database | MongoDB User collection                |
| JWTService     | Service  | Token generation service               |

---

## 3. Mermaid Diagram

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant MobileApp as Mobile App
    participant AuthController as Auth Controller
    participant UserModel as User Model (MongoDB)
    participant JWTService as JWT Service

    User->>MobileApp: Enter email & password
    MobileApp->>MobileApp: Validate input fields

    alt Input Invalid
        MobileApp-->>User: Display validation error
    else Input Valid
        MobileApp->>AuthController: POST /api/auth/login {email, password}
        AuthController->>UserModel: findOne({email})

        alt User Not Found
            UserModel-->>AuthController: null
            AuthController-->>MobileApp: 401 {error: "Invalid credentials"}
            MobileApp-->>User: Display "Invalid email or password"
        else User Found
            UserModel-->>AuthController: User document
            AuthController->>AuthController: bcrypt.compare(password, hash)

            alt Password Mismatch
                AuthController-->>MobileApp: 401 {error: "Invalid credentials"}
                MobileApp-->>User: Display "Invalid email or password"
            else Password Match
                AuthController->>AuthController: Check user.approved

                alt Account Not Approved
                    AuthController-->>MobileApp: 403 {error: "Account pending approval"}
                    MobileApp-->>User: Display "Awaiting admin approval"
                else Account Approved
                    AuthController->>JWTService: generateToken(userId, role)
                    JWTService-->>AuthController: JWT access token
                    AuthController-->>MobileApp: 200 {token, user}
                    MobileApp->>MobileApp: Store token securely
                    MobileApp-->>User: Navigate to Dashboard
                end
            end
        end
    end
```

---

## 4. Alternative Flows / Exceptions

| Scenario           | Handling                                                           |
| ------------------ | ------------------------------------------------------------------ |
| Network Error      | MobileApp displays "Connection failed. Please try again."          |
| Server Error (500) | MobileApp displays generic error with retry option                 |
| Token Expired      | On subsequent API calls, 401 triggers logout and redirect to login |

---

## 5. Modules / Components Represented

| Component       | File/Location                                                          |
| --------------- | ---------------------------------------------------------------------- |
| Mobile App      | `lib/screens/auth/login_screen.dart`, `lib/services/auth_service.dart` |
| Auth Controller | `src/controllers/authController.ts`                                    |
| User Model      | `src/models/User.ts`                                                   |
| JWT Service     | `src/utils/jwt.ts`                                                     |

---

## 6. Notes / Considerations

- **Security:** Passwords are never transmitted in plain text after hashing. Bcrypt is used for password verification.
- **Token Storage:** JWT is stored using `flutter_secure_storage` for encrypted persistence.
- **Stateless Auth:** The backend uses stateless JWT authentication; no session is stored server-side.
