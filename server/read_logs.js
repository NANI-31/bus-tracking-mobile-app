const fs = require("fs");
const path = require("path");

const logPath = path.join(__dirname, "logs", "all.log");

try {
  if (fs.existsSync(logPath)) {
    const stats = fs.statSync(logPath);
    const fileSize = stats.size;
    const readSize = Math.min(fileSize, 5000);
    const buffer = Buffer.alloc(readSize);

    const fd = fs.openSync(logPath, "r");
    fs.readSync(fd, buffer, 0, readSize, fileSize - readSize);
    fs.closeSync(fd);

    console.log(buffer.toString());
  } else {
    console.log("Log file not found at:", logPath);
  }
} catch (error) {
  console.error("Error reading log:", error.message);
}
