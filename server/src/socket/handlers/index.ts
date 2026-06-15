import { Server, Socket } from "socket.io";
import { registerConnectionHandler } from "./connection";
import { registerTrackingHandlers } from "./tracking";
import { registerLocationHandlers } from "./location";
import { registerSosHandlers } from "./sos";
import { registerUpdateHandlers } from "./updates";
import { registerDisconnectHandler } from "./disconnect";

export const registerSocketHandlers = (io: Server, socket: Socket) => {
  registerConnectionHandler(io, socket);
  registerTrackingHandlers(io, socket);
  registerLocationHandlers(io, socket);
  registerSosHandlers(io, socket);
  registerUpdateHandlers(io, socket);
  registerDisconnectHandler(io, socket);
};
