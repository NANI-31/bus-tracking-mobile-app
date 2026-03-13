"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
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
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
dotenv_1.default.config();
const mongoose_1 = __importDefault(require("mongoose"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const fs_1 = __importDefault(require("fs"));
const User_model_1 = __importStar(require("../../src/models/User.model"));
const Bus_model_1 = require("../../src/models/Bus.model");
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    console.error("JWT_SECRET is not defined in .env file!");
    process.exit(1);
}
console.log("Using JWT_SECRET for token generation.");
const OUTPUT_FILE = path_1.default.join(__dirname, "tokens.csv");
const NUM_DRIVERS = 20;
const NUM_STUDENTS = 100;
function generateTokens() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const mongoUri = process.env.MONGO_URI;
            if (!mongoUri)
                throw new Error("MONGO_URI is missing");
            yield mongoose_1.default.connect(mongoUri);
            console.log("Connected to MongoDB...");
            // Fetch drivers and their associated college/bus info
            const drivers = yield User_model_1.default.find({ role: User_model_1.UserRole.Driver }).limit(NUM_DRIVERS);
            const students = yield User_model_1.default.find({ role: User_model_1.UserRole.Student }).limit(NUM_STUDENTS);
            if (drivers.length === 0 || students.length === 0) {
                console.warn("Not enough drivers/students found in DB. Please run seeding first.");
                process.exit(1);
            }
            const csvLines = ["token,role,collegeId,busId"];
            // Generate tokens for drivers
            for (const driver of drivers) {
                const bus = yield Bus_model_1.Bus.findOne({ driverId: driver._id.toString() });
                const payload = {
                    id: driver._id.toString(),
                    role: driver.role,
                    collegeId: driver.collegeId.toString(),
                };
                const token = jsonwebtoken_1.default.sign(payload, JWT_SECRET);
                csvLines.push(`${token},driver,${driver.collegeId.toString()},${bus ? bus._id.toString() : ""}`);
            }
            // Generate tokens for students
            for (const student of students) {
                const payload = {
                    id: student._id.toString(),
                    role: student.role,
                    collegeId: student.collegeId.toString(),
                };
                const token = jsonwebtoken_1.default.sign(payload, JWT_SECRET);
                csvLines.push(`${token},student,${student.collegeId.toString()},`);
            }
            fs_1.default.writeFileSync(OUTPUT_FILE, csvLines.join("\n"));
            console.log(`Successfully generated ${csvLines.length - 1} tokens in ${OUTPUT_FILE}`);
            yield mongoose_1.default.disconnect();
        }
        catch (err) {
            console.error("Error generating tokens:", err);
            process.exit(1);
        }
    });
}
generateTokens();
