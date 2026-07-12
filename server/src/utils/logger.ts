import winston from "winston";
import Transport from "winston-transport";

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

const colors = {
  error: "red",
  warn: "yellow",
  info: "green",
  http: "magenta",
  debug: "white",
};

const emojis = {
  error: "❌",
  warn: "⚠️",
  info: "ℹ️ ",
  http: "🌐",
  debug: "🐛",
};

winston.addColors(colors);

const format = winston.format.combine(
  winston.format.timestamp({
    format: () =>
      new Date()
        .toLocaleString("en-IN", {
          timeZone: "Asia/Kolkata",
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          hour12: true,
        })
        .replace(/\//g, "-")
        .replace(",", ""), // Try to match DD-MM-YYYY hh:mm:ss A derived from en-IN
  }),
  winston.format.colorize({ level: true }),
  winston.format.printf((info) => {
    // Strip ANSI color codes to get the clean level name for emoji lookup
    const cleanLevel = info.level.replace(
      // eslint-disable-next-line
      /[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g,
      "",
    );
    const emoji = emojis[cleanLevel as keyof typeof emojis] || "";
    // Split timestamp into date & time
    const timestamp = info.timestamp as string;

    const [date, ...timeParts] = timestamp.split(" ");
    const time = timeParts.join(" ");

    return `[📅 ${date} ⏰ ${time}] ${emoji} ${info.level}: ${info.message}`;
  }),
);

// Global reference to Socket.io instance
let globalSocketIO: any = null;

export const setSocketIOForLogger = (io: any) => {
  globalSocketIO = io;
};

class SocketIOTransport extends Transport {
  constructor(opts?: any) {
    super(opts);
  }

  log(info: any, callback: () => void) {
    setImmediate(() => {
      this.emit("logged", info);
    });

    if (globalSocketIO) {
      try {
        const SYMBOL_MESSAGE = Symbol.for("message");
        const formattedMessage = info[SYMBOL_MESSAGE] || info.message;
        // Strip ANSI escape codes to ensure clean text on client
        const cleanMessage = typeof formattedMessage === "string"
          ? formattedMessage.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, "")
          : formattedMessage;

        // Emit to the server_terminal_logs room
        globalSocketIO.to("server_terminal_logs").emit("server_log", {
          timestamp: info.timestamp || new Date().toISOString(),
          level: info.level.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, ""),
          message: cleanMessage,
        });
      } catch (err) {
        // Prevent infinite loop if emitting logs throws an error
      }
    }

    callback();
  }
}

const logger = winston.createLogger({
  levels,
  level: "debug",
  format,
  transports: [
    new winston.transports.Console(),
    // File logging removed for containerization (logs should be captured by stdout/stderr)
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/all.log" }),
    new SocketIOTransport(),
  ],
});

export default logger;
