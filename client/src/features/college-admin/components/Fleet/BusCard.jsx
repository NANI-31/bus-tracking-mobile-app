import React, { useEffect, useRef } from "react";
import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import { TruckIcon, TrashIcon } from "@heroicons/react/24/outline";

// Custom HTML5 Canvas pulsing status indicator conveying real-time connectivity states
const LiveStatusDot = ({ color = "#10B981" }) => {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    let animationFrameId;
    let radius = 2;
    let growing = true;

    const render = () => {
      if (!canvas || !ctx) return;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;

      // Draw outer glowing pulsing ring
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius + 2.5, 0, 2 * Math.PI);
      ctx.fillStyle = color.startsWith("#") ? `${color}30` : "rgba(16, 185, 129, 0.18)";
      ctx.fill();

      // Draw middle ring
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      ctx.fillStyle = color.startsWith("#") ? `${color}60` : "rgba(16, 185, 129, 0.38)";
      ctx.fill();

      // Draw center solid dot
      ctx.beginPath();
      ctx.arc(centerX, centerY, 3.2, 0, 2 * Math.PI);
      ctx.fillStyle = color;
      ctx.fill();

      // Animate pulsing radius
      if (growing) {
        radius += 0.12;
        if (radius >= 6.8) growing = false;
      } else {
        radius -= 0.12;
        if (radius <= 2.2) growing = true;
      }

      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animationFrameId);
    };
  }, [color]);

  return <canvas ref={canvasRef} width={20} height={20} className="w-5 h-5 shrink-0" />;
};

const BusCard = ({ bus, onDelete }) => {
  const isOnline = bus.status === "active" || bus.status === "on-time" || !bus.status;
  const isDelayed = bus.status === "delayed";
  const capacityPercent = Math.min(100, Math.max(5, ((parseInt(bus.capacity) || 0) / 80) * 100));
  
  const statusColor = isOnline 
    ? "#10B981" // emerald
    : isDelayed 
    ? "#F59E0B" // amber
    : "#EF4444"; // rose

  const statusText = bus.status 
    ? bus.status.replace("-", " ").toUpperCase() 
    : "ACTIVE";

  // Spring-based 3D Card Hover Tilts
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  const rotateX = useSpring(useTransform(y, [-0.5, 0.5], [6, -6]), { stiffness: 300, damping: 22 });
  const rotateY = useSpring(useTransform(x, [-0.5, 0.5], [-6, 6]), { stiffness: 300, damping: 22 });

  const handleMouseMove = (e) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const width = rect.width;
    const height = rect.height;
    const mouseX = e.clientX - rect.left - width / 2;
    const mouseY = e.clientY - rect.top - height / 2;
    x.set(mouseX / width);
    y.set(mouseY / height);
  };

  const handleMouseLeave = () => {
    x.set(0);
    y.set(0);
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      whileHover={{ 
        y: -6, 
        scale: 1.025, 
        transition: { type: "spring", stiffness: 450, damping: 18 } 
      }}
      style={{ rotateX, rotateY, transformStyle: "preserve-3d", transformPerspective: 1000 }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      layout
      className="cursor-pointer"
    >
      <div
        className="bg-background-paper rounded-3xl p-6 border transition-all duration-350 relative overflow-hidden group"
        style={{
          borderTop: `6px solid ${statusColor}`,
          borderColor: "var(--border-color)",
          boxShadow: "0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05)",
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.boxShadow = `0 20px 35px -10px ${statusColor}20, 0 5px 15px -5px ${statusColor}10`;
          e.currentTarget.style.borderColor = `${statusColor}50`;
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.boxShadow = "0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05)";
          e.currentTarget.style.borderColor = "var(--border-color)";
        }}
      >
        <div className="flex justify-between items-start mb-4">
          <div className="relative">
            <div className="p-3.5 bg-linear-to-tr from-slate-100 to-slate-50 dark:from-slate-800 dark:to-slate-850 rounded-2xl border border-border-theme transition-transform duration-350 group-hover:scale-110 group-hover:rotate-3">
              <TruckIcon className="w-6 h-6 text-primary-main animate-pulse" />
            </div>
            {/* Live indicator dot positioned on top-right of the truck avatar */}
            <div className="absolute -top-1.5 -right-1.5">
              <LiveStatusDot color={statusColor} />
            </div>
          </div>

          {/* Glassmorphic delete button */}
          <button
            onClick={(e) => {
              e.stopPropagation();
              onDelete(bus._id);
            }}
            className="p-2.5 rounded-xl border border-border-theme/40 text-text-theme-secondary hover:text-rose-500 hover:bg-rose-500/10 hover:border-rose-500/20 active:scale-95 transition-all duration-200 cursor-pointer"
            title="Remove Bus"
          >
            <TrashIcon className="w-4 h-4" />
          </button>
        </div>

        <div>
          <h3 className="text-lg font-black text-text-theme-primary tracking-tight">Bus {bus.busNumber}</h3>
          <p className="text-[10px] font-semibold text-text-theme-secondary uppercase tracking-widest mt-0.5">
            Vehicle ID: {bus._id?.substring(0, 8).toUpperCase() || "N/A"}
          </p>
        </div>

        {/* Seating Capacity Bar & Utilization */}
        <div className="mt-5 pt-4 border-t border-border-theme/40 space-y-3">
          <div className="space-y-1.5">
            <div className="flex justify-between text-[9px] sm:text-[11px] font-black uppercase tracking-wider text-text-theme-secondary">
              <span>Seating Occupancy</span>
              <span className="text-text-theme-primary font-black">{bus.capacity} / 80 Seats</span>
            </div>
            <div className="w-full h-2 bg-background-default rounded-full overflow-hidden border border-border-theme/30">
              <motion.div 
                initial={{ width: 0 }}
                animate={{ width: `${capacityPercent}%` }}
                transition={{ type: "spring", stiffness: 80, damping: 15 }}
                className="h-full rounded-full"
                style={{ backgroundColor: statusColor }}
              />
            </div>
          </div>

          <div className="hidden sm:flex justify-between items-center text-xs font-semibold text-text-theme-secondary pt-1">
            <span className="text-[9px] sm:text-[11px] font-black uppercase tracking-wider">Operational Status</span>
            <span
              className="px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-widest border transition-all"
              style={{ 
                backgroundColor: `${statusColor}15`, 
                color: statusColor,
                borderColor: `${statusColor}30`
              }}
            >
              {statusText}
            </span>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

export default BusCard;
