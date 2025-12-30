# PKG3: Node.js Backend Packages

**Package Diagram ID:** PKG3  
**Module Group:** Node.js Backend Server  
**Version:** 1.0  
**Date:** 2025-12-30

---

## 1. Purpose

This package diagram details the internal package structure of the Node.js backend server, showing the layered architecture and module dependencies.

---

## 2. Packages / Modules

| Package     | Path               | Description                      |
| ----------- | ------------------ | -------------------------------- |
| routes      | `src/routes/`      | Express route definitions        |
| controllers | `src/controllers/` | Request handlers                 |
| models      | `src/models/`      | Mongoose schemas                 |
| middleware  | `src/middleware/`  | Auth, validation, error handling |
| services    | `src/services/`    | External service integrations    |
| socket      | `src/socket.ts`    | Socket.IO event handlers         |
| config      | `src/config/`      | Environment configuration        |
| utils       | `src/utils/`       | Helper functions                 |

---

## 3. Mermaid Diagram

```mermaid
flowchart TB
    subgraph Backend["src/"]
        subgraph EntryPoint["Entry"]
            index["index.ts"]
            app["app.ts"]
        end

        subgraph API["API Layer"]
            routes["routes/"]
            subgraph RouteModules["Route Modules"]
                authRoutes["authRoutes.ts"]
                userRoutes["userRoutes.ts"]
                busRoutes["busRoutes.ts"]
                routeRoutes["routeRoutes.ts"]
                incidentRoutes["incidentRoutes.ts"]
            end
        end

        subgraph Controllers["Controller Layer"]
            controllers["controllers/"]
            subgraph ControllerModules["Controller Modules"]
                authCtrl["authController.ts"]
                userCtrl["userController.ts"]
                busCtrl["busController.ts"]
            end
        end

        subgraph Data["Data Layer"]
            models["models/"]
            subgraph ModelModules["Model Modules"]
                User["User.ts"]
                Bus["Bus.ts"]
                Route["Route.ts"]
                Incident["Incident.ts"]
            end
        end

        subgraph Middleware["Middleware Layer"]
            middleware["middleware/"]
            authMW["authMiddleware.ts"]
            rateLimiter["rateLimiter.ts"]
            errorHandler["errorHandler.ts"]
        end

        subgraph Services["Service Layer"]
            services["services/"]
            notificationSvc["notificationService.ts"]
        end

        subgraph RealTime["Real-Time Layer"]
            socket["socket.ts"]
        end

        subgraph Config["Configuration"]
            config["config/"]
            utils["utils/"]
        end
    end

    index --> app
    app --> routes
    app --> middleware
    app --> socket

    routes --> RouteModules
    RouteModules --> controllers
    controllers --> ControllerModules
    ControllerModules --> models
    ControllerModules --> services

    models --> ModelModules
    middleware --> authMW
    middleware --> rateLimiter
    socket --> models
    socket --> services
```

---

## 4. Dependencies

| Source Package | Target Package | Dependency Type  |
| -------------- | -------------- | ---------------- |
| index.ts       | app.ts         | Bootstrap        |
| routes         | controllers    | Request Handling |
| controllers    | models         | Data Access      |
| controllers    | services       | Business Logic   |
| middleware     | routes         | Request Pipeline |
| socket         | models         | Real-time Data   |

---

## 5. Actors / Roles

| Package    | Interacting Roles                          |
| ---------- | ------------------------------------------ |
| authRoutes | All roles                                  |
| userRoutes | Admin, Coordinator                         |
| busRoutes  | Coordinator, Driver                        |
| socket     | Driver (emit), Students/Teachers (receive) |

---

## 6. Notes / Considerations

- **Layered Architecture:** Clear separation between routes, controllers, and models.
- **Middleware Pipeline:** Auth → Rate Limit → Route Handler → Error Handler.
- **Real-Time:** Socket.IO runs alongside Express on same server.
- **TypeScript:** Full type safety across all modules.
