import winston from "winston";

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
      ""
    );
    const emoji = emojis[cleanLevel as keyof typeof emojis] || "";
    // Split timestamp into date & time
    const timestamp = info.timestamp as string;

    const [date, ...timeParts] = timestamp.split(" ");
    const time = timeParts.join(" ");

    return `[📅 ${date} ⏰ ${time}] ${emoji} ${info.level}: ${info.message}`;
  })
);

const logger = winston.createLogger({
  levels,
  level: "debug",
  format,
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/all.log" }),
  ],
});

export default logger;
