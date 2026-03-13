"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const socket_io_client_1 = require("socket.io-client");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const CSV_PATH = path_1.default.join(__dirname, "tokens.csv");
const SERVER_URL = "http://127.0.0.1:5000";
const CONCURRENCY = 50; // Total concurrent users per process
const RAMP_UP_MS = 100; // Delay between each connection
function runLoadTest() {
    return __awaiter(this, void 0, void 0, function* () {
        const fileContent = fs_1.default.readFileSync(CSV_PATH, "utf-8");
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
            const socket = (0, socket_io_client_1.io)(SERVER_URL, {
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
            yield new Promise(resolve => setTimeout(resolve, RAMP_UP_MS));
        }
        // Monitor progress
        setInterval(() => {
            console.log(`--- Status: ${connectedCount} connected, ${errorCount} errors ---`);
        }, 10000);
    });
}
runLoadTest().catch(console.error);
