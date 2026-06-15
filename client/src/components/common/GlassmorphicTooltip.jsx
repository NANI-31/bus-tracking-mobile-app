import React from "react";

const GlassmorphicTooltip = ({ active, payload, label, formatter }) => {
  if (!active || !payload || !payload.length) return null;

  const primaryColor = payload[0]?.color || payload[0]?.fill || "#1E90FF";

  return (
    <div 
      className="backdrop-blur-xl bg-white/85 dark:bg-slate-950/80 border border-white/40 dark:border-slate-800/80 p-4 rounded-2xl transition-all duration-150 ring-1 ring-black/5 dark:ring-white/5"
      style={{
        borderColor: `${primaryColor}30`,
        boxShadow: `0 20px 50px ${primaryColor}15, 0 1px 1px 0 rgba(255, 255, 255, 0.5) inset`,
      }}
    >
      <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 mb-2 uppercase tracking-widest">{label}</p>
      <div className="space-y-2">
        {payload.map((entry, index) => {
          const displayValue = formatter 
            ? formatter(entry.value, entry.name, entry, index) 
            : (typeof entry.value === "number" ? entry.value.toLocaleString() : entry.value);

          return (
            <div key={index} className="flex items-center space-x-3 text-xs">
              <span 
                className="w-3 h-3 rounded-full inline-block border-2 border-white dark:border-slate-800 shadow-sm"
                style={{ backgroundColor: entry.color || entry.fill }}
              />
              <span className="font-semibold text-slate-500 dark:text-slate-400">{entry.name}:</span>
              <span className="font-extrabold text-slate-800 dark:text-slate-100">
                {displayValue}
                {entry.unit ? ` ${entry.unit}` : ""}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default GlassmorphicTooltip;
