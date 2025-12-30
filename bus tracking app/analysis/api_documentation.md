# API Documentation

## Base Configuration

- **Base URL**: Configured via `API_BASE_URL` environment variable
- **Content-Type**: `application/json`
- **Authentication**: Bearer token in `Authorization` header

---

## Authentication Endpoints

### POST `/api/auth/register`

Register a new user account.

**Request Body**:

```json
{
  "fullName": "string",
  "email": "string",
  "password": "string",
  "role": "student|teacher|driver|busCoordinator|admin|parent",
  "collegeId": "string",
  "phoneNumber": "string (optional)",
  "rollNumber": "string (optional)"
}
```

**Response**: `{ success: true, message: string }`

---

### POST `/api/auth/login`

Authenticate and receive JWT token.

**Request Body**:

```json
{
  "email": "string",
  "password": "string"
}
```

**Response**:

```json
{
  "success": true,
  "token": "JWT_TOKEN",
  "user": {
    "id": "string",
    "email": "string",
    "fullName": "string",
    "role": "string",
    "collegeId": "string",
    "approved": true
  }
}
```

---

### POST `/api/auth/send-otp`

Send OTP to email for verification.

**Request Body**: `{ "email": "string" }`

---

### POST `/api/auth/verify-otp`

Verify OTP code.

**Request Body**: `{ "email": "string", "otp": "string" }`

---

### POST `/api/auth/reset-password`

Reset password after OTP verification.

**Request Body**: `{ "email": "string", "newPassword": "string" }`

---

## User Endpoints

| Method | Endpoint         | Description    |
| ------ | ---------------- | -------------- |
| GET    | `/api/users`     | Get all users  |
| GET    | `/api/users/:id` | Get user by ID |
| PUT    | `/api/users/:id` | Update user    |

---

## Bus Endpoints

| Method | Endpoint                                  | Description                       |
| ------ | ----------------------------------------- | --------------------------------- |
| GET    | `/api/buses`                              | Get all buses                     |
| POST   | `/api/buses`                              | Create new bus                    |
| PUT    | `/api/buses/:id`                          | Update bus                        |
| DELETE | `/api/buses/:id`                          | Delete bus                        |
| POST   | `/api/buses/location`                     | Update bus location               |
| GET    | `/api/buses/:id/location`                 | Get bus location                  |
| GET    | `/api/buses/college/:collegeId/locations` | Get all bus locations for college |

---

## Route Endpoints

| Method | Endpoint                         | Description           |
| ------ | -------------------------------- | --------------------- |
| GET    | `/api/routes/college/:collegeId` | Get routes by college |
| POST   | `/api/routes`                    | Create new route      |
| PUT    | `/api/routes/:id`                | Update route          |
| DELETE | `/api/routes/:id`                | Delete route          |

---

## Schedule Endpoints

| Method | Endpoint                            | Description              |
| ------ | ----------------------------------- | ------------------------ |
| GET    | `/api/schedules/college/:collegeId` | Get schedules by college |
| POST   | `/api/schedules`                    | Create schedule          |
| PUT    | `/api/schedules/:id`                | Update schedule          |
| DELETE | `/api/schedules/:id`                | Delete schedule          |

---

## Notification Endpoints

| Method | Endpoint                              | Description            |
| ------ | ------------------------------------- | ---------------------- |
| GET    | `/api/notifications/user/:userId`     | Get user notifications |
| POST   | `/api/notifications`                  | Send notification      |
| PUT    | `/api/notifications/:id/read`         | Mark as read           |
| POST   | `/api/notifications/remove-fcm-token` | Remove FCM token       |

---

## College Endpoints

| Method | Endpoint                                | Description       |
| ------ | --------------------------------------- | ----------------- |
| GET    | `/api/colleges`                         | Get all colleges  |
| GET    | `/api/colleges/:id/bus-numbers`         | Get bus numbers   |
| POST   | `/api/colleges/bus-numbers`             | Add bus number    |
| DELETE | `/api/colleges/:id/bus-numbers/:number` | Remove bus number |

---

## Special Endpoints

### SOS

`POST /api/sos` - Send emergency alert

```json
{
  "busId": "string",
  "location": { "lat": number, "lng": number }
}
```

### Incidents

`POST /api/incidents` - Report incident

### Assignment Logs

- `GET /api/assignments/bus/:busId` - Get by bus
- `GET /api/assignments/driver/:driverId` - Get by driver

---

## Socket.IO Events

### Client → Server

| Event              | Payload                                                      | Description             |
| ------------------ | ------------------------------------------------------------ | ----------------------- |
| `join_college`     | `collegeId: string`                                          | Join college room       |
| `update_location`  | `{ busId, collegeId, location: {lat, lng}, speed, heading }` | Broadcast location      |
| `bus_list_updated` | none                                                         | Notify bus list changed |

### Server → Client

| Event                  | Payload                 | Description           |
| ---------------------- | ----------------------- | --------------------- |
| `location_updated`     | Same as update_location | Location broadcast    |
| `bus_updated`          | Bus data                | Single bus updated    |
| `bus_list_updated`     | none                    | List refresh trigger  |
| `driver_status_update` | `{ driverId, status }`  | Driver online/offline |

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "message": "Error description"
}
```

| Status Code | Meaning                        |
| ----------- | ------------------------------ |
| 400         | Bad Request / Validation Error |
| 401         | Unauthorized / Invalid Token   |
| 403         | Forbidden / Access Denied      |
| 404         | Resource Not Found             |
| 429         | Rate Limit Exceeded            |
| 500         | Internal Server Error          |
