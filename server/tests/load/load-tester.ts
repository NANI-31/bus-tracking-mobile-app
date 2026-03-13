import { io } from "socket.io-client";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";

dotenv.config();

const CSV_PATH = path.join(__dirname, "tokens.csv");
const SERVER_URL = "http://127.0.0.1:5000";
const CONCURRENCY = 50; // Total concurrent users per process
const RAMP_UP_MS = 100; // Delay between each connection

async function runLoadTest() {
  const fileContent = fs.readFileSync(CSV_PATH, "utf-8");
  const lines = fileContent.split("\n").slice(1).filter(l => l.trim());
  
  if (lines.length === 0) {
    console.error("No tokens found in tokens.csv");
    process.exit(1);
  }

  console.log(`Starting load test with ${Math.min(CONCURRENCY, lines.length)} users...`);
  
  let connectedCount = 0;
  let errorCount = 0;

  for (let i = 0; i < Math.min(CONCURRENCY, lines.length); i++) {
    const [token, role, collegeId, busId] = lines[i].split(",");
    
    const socket = io(SERVER_URL, {
      auth: { token },
      transports: ["websocket"],
      reconnection: false
    });

    socket.on("connect", () => {
      connectedCount++;
      // console.log(`[${i}] Connected as ${role}`);
      socket.emit("join_college", collegeId);
      
      if (role === "driver" && busId) {
        setInterval(() => {
          socket.emit("update_location", {
            lat: 12.9716 + (Math.random() - 0.5) * 0.01,
            lng: 77.5946 + (Math.random() - 0.5) * 0.01
          });
        }, 5000);
      }
    });

    socket.on("connect_error", (err) => {
      errorCount++;
      console.error(`[${i}] Connection error: ${err.message}`);
    });

    socket.on("disconnect", () => {
      connectedCount--;
    });

    await new Promise(resolve => setTimeout(resolve, RAMP_UP_MS));
  }

  // Monitor progress
  setInterval(() => {
    console.log(`--- Status: ${connectedCount} connected, ${errorCount} errors ---`);
  }, 10000);
}

runLoadTest().catch(console.error);
