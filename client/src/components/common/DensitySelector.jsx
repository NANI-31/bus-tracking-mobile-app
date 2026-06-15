import React from "react";
import { motion } from "framer-motion";

const DensitySelector = ({ currentDensity, onChange }) => {
  const options = [
    { id: "compact", label: "Compact" },
    { id: "default", label: "Default" },
    { id: "relaxed", label: "Relaxed" },
  ];

  return (
    <div className="flex items-center space-x-2 bg-slate-100/80 p-1 rounded-xl border border-slate-200/50 backdrop-blur-xs w-fit">
      {options.map((opt) => {
        const isActive = currentDensity === opt.id;
        return (
          <button
            key={opt.id}
            onClick={() => onChange(opt.id)}
            className="relative px-3 py-1.5 rounded-lg text-xs font-bold transition-colors duration-200 select-none cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 z-10"
            style={{
              color: isActive ? "#ffffff" : "#64748b",
            }}
          >
            {isActive && (
              <motion.div
                layoutId="activeDensityBg"
                className="absolute inset-0 bg-[#1E90FF] rounded-lg -z-10 shadow-sm"
                transition={{ type: "spring", stiffness: 380, damping: 30 }}
              />
            )}
            {opt.label}
          </button>
        );
      })}
    </div>
  );
};

export default DensitySelector;
