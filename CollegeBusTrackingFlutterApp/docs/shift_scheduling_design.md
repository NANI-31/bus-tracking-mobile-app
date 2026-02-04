# Shift-Based Bus Scheduling Design

## Overview

This document outlines the implementation strategy for flexible shift-based bus scheduling, supporting colleges with both single-shift and multi-shift operations.

---

## Use Cases

### Multi-Shift Colleges (e.g., 7:30 AM + 9:00 AM)

| Shift       | Morning (Pickup)                 | Evening (Drop)                  |
| ----------- | -------------------------------- | ------------------------------- |
| **Shift 1** | 1st & 3rd Year → 7:30 AM classes | 1st & 3rd Year → Released early |
| **Shift 2** | 2nd & 4th Year → 9:00 AM classes | 2nd & 4th Year → Released later |

### Single-Shift Colleges

- Only 9:00 AM classes
- Same evening release time for all
- **No shift filter needed** → UI adapts automatically

---

## Data Model Changes

### College Configuration

```javascript
// CollegeModel additions
{
  shiftCount: 1 | 2,           // Number of shifts for this college
  shifts: [
    {
      shiftId: "shift_1",
      name: "Early Shift",      // or "Morning Shift" for single-shift
      pickupTime: "07:30",
      dropTime: "16:00",
      targetYears: [1, 3]       // Optional: year groups
    },
    {
      shiftId: "shift_2",
      name: "Regular Shift",
      pickupTime: "09:00",
      dropTime: "17:30",
      targetYears: [2, 4]
    }
  ]
}
```

### Bus-Shift Assignment

```javascript
// BusModel additions
{
  shiftId: "shift_1" | "shift_2" | null,  // null for single-shift colleges
  shiftType: "pickup" | "drop"            // Current trip type
}
```

### Schedule Entry

```javascript
// ScheduleModel
{
  busId: String,
  routeId: String,
  shiftId: String,
  tripType: "pickup" | "drop",
  departureTime: DateTime,
  arrivalTime: DateTime
}
```

---

## UI Implementation

### Student Schedule Screen

```
┌─────────────────────────────────────────┐
│  Bus Schedule                           │
├─────────────────────────────────────────┤
│  [Pickup ▼]  [Shift 1] [Shift 2]        │  ← Filters (hidden if single-shift)
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ 🚌 Bus 101 - Route A            │    │
│  │    Departs: 7:30 AM             │    │
│  │    Arrives: 8:15 AM             │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ 🚌 Bus 102 - Route B            │    │
│  │    Departs: 7:35 AM             │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### Adaptive Filter Logic

```dart
// In BusScheduleScreen
final college = ref.watch(collegeProvider);
final showShiftFilter = college.shiftCount > 1;

if (showShiftFilter) {
  // Show: [Shift 1] [Shift 2] toggle
} else {
  // Hide shift filter, show all buses directly
}
```

---

## Implementation Checklist

### Backend

- [ ] Add `shiftCount` and `shifts[]` to College schema
- [ ] Add `shiftId` to Bus schema
- [ ] Add `shiftId` and `tripType` to Schedule schema
- [ ] Create API: `GET /schedules?collegeId=&shiftId=&tripType=`

### Flutter App

- [ ] Update `CollegeModel` with shift configuration
- [ ] Update `BusModel` with shift association
- [ ] Create `ScheduleModel` for timetable entries
- [ ] Modify `BusScheduleScreen` with conditional shift filters
- [ ] Add `ShiftProvider` to manage shift state
- [ ] Implement auto-hide logic for single-shift colleges

### Coordinator Panel

- [ ] Add shift configuration in college settings
- [ ] Allow bus-to-shift assignment
- [ ] Enable schedule creation per shift

---

## Edge Cases

| Scenario                  | Handling                                 |
| ------------------------- | ---------------------------------------- |
| Single-shift college      | Hide shift filter, display all buses     |
| Student year mismatch     | Allow manual shift selection (override)  |
| Mid-semester shift change | Admin can reassign via coordinator panel |
| Holiday/special schedules | Separate "special schedule" flag         |

---

## Migration Strategy

1. Default all existing colleges to `shiftCount: 1`
2. Coordinators manually upgrade to multi-shift via settings
3. No breaking changes for existing single-shift workflows
