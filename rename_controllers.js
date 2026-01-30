const fs = require("fs");
const path = require("path");

const dir = "server/src/controllers";
const renames = {
  "busController.ts": "bus.controller.ts",
  "userController.ts": "user.controller.ts",
  "collegeController.ts": "college.controller.ts",
  "historyController.ts": "history.controller.ts",
  "incidentController.ts": "incident.controller.ts",
  "notificationController.ts": "notification.controller.ts",
  "routeController.ts": "route.controller.ts",
  "scheduleController.ts": "schedule.controller.ts",
  "sosController.ts": "sos.controller.ts",
  "assignmentController.ts": "assignment.controller.ts",
};

Object.entries(renames).forEach(([oldName, newName]) => {
  const oldPath = path.join(dir, oldName);
  const newPath = path.join(dir, newName);
  if (fs.existsSync(oldPath)) {
    fs.renameSync(oldPath, newPath);
    console.log(`Renamed: ${oldName} -> ${newName}`);
  } else {
    console.log(`Skipped (not found): ${oldName}`);
  }
});
