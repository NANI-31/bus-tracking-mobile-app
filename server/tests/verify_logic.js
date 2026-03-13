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
Object.defineProperty(exports, "__esModule", { value: true });
const busNearbyLogic_1 = require("../src/utils/busNearbyLogic");
// Mock Mongoose setup if needed, or just import logic to test syntax
// Ideally this spins up a test DB context, but for quick verify we check compilation
console.log("Analyzing busNearbyLogic for compilation errors...");
// Only strictly needed part;
const test = () => __awaiter(void 0, void 0, void 0, function* () {
    try {
        yield (0, busNearbyLogic_1.checkAndNotifyBusNearby)("bus123", "AP01", 17.0, 78.0, "routeId123");
        console.log("Logic executed (simulated)");
    }
    catch (e) {
        console.error(e);
    }
});
test();
