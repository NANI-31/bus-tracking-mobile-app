import React, { useState } from "react";
import { motion, AnimatePresence, useMotionValue, useSpring, useTransform } from "framer-motion";
import {
  MapIcon,
  TrashIcon,
  PencilIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  MapPinIcon as PinIcon,
  EllipsisHorizontalIcon,
} from "@heroicons/react/24/outline";
import {
  Card,
  CardContent,
  IconButton,
  Collapse,
  Tooltip,
  Avatar,
  Typography,
} from "@mui/material";

const RouteCard = ({ route, onDelete, onEdit, onSelect, isSelected, onHoverStop }) => {
  const [expanded, setExpanded] = useState(false);
  const stops = route.stopPoints || [];
  const startStop = stops[0];
  const endStop = stops[stops.length - 1];
  const intermediateStopsCount = Math.max(0, stops.length - 2);
  const routeColor = route.color || "#1E90FF";

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
      layout
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      whileHover={{ 
        y: -6, 
        scale: 1.015, 
        transition: { type: "spring", stiffness: 450, damping: 18 } 
      }}
      style={{ rotateX, rotateY, transformStyle: "preserve-3d", transformPerspective: 1000 }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      transition={{ type: "spring", stiffness: 300, damping: 25 }}
      onClick={() => onSelect && onSelect(route)}
      className="cursor-pointer"
    >
      <Card
        elevation={0}
        sx={{
          borderRadius: "24px",
          border: isSelected ? `2px solid ${routeColor}` : "2px solid var(--border-color)",
          borderTop: `6px solid ${routeColor}`,
          bgcolor: "background.paper",
          overflow: "hidden",
          transition: "all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)",
          boxShadow: isSelected 
            ? `0 12px 30px -10px ${routeColor}40` 
            : "0 1px 3px 0 rgba(0, 0, 0, 0.05), 0 1px 2px -1px rgba(0, 0, 0, 0.05)",
          "&:hover": {
            boxShadow: isSelected 
              ? `0 22px 45px -10px ${routeColor}55`
              : `0 20px 35px -10px ${routeColor}20, 0 5px 15px -5px ${routeColor}10`,
            borderColor: routeColor,
            "& .route-icon-avatar": {
              transform: "scale(1.15) rotate(5deg)",
              bgcolor: `${routeColor}25`,
            },
          },
        }}
      >
        <CardContent sx={{ p: 3, position: "relative" }}>
          {/* Action overlay container - glassmorphic top-right positioning */}
          <div className="absolute top-6 right-6 flex items-center space-x-1 bg-slate-100/80 dark:bg-slate-800/80 backdrop-blur-md p-1 rounded-xl border border-slate-200/50 dark:border-slate-700/50 shadow-xs z-10">
            <Tooltip title="Edit Route" arrow>
              <IconButton
                onClick={(e) => {
                  e.stopPropagation();
                  onEdit(route);
                }}
                size="small"
                sx={{
                  color: "text.secondary",
                  p: 0.75,
                  transition: "all 0.2s ease",
                  "&:hover": { 
                    color: routeColor, 
                    bgcolor: `${routeColor}20`,
                    transform: "scale(1.05)",
                  },
                }}
              >
                <PencilIcon className="w-4 h-4" />
              </IconButton>
            </Tooltip>
            <Tooltip title="Delete Route" arrow>
              <IconButton
                onClick={(e) => {
                  e.stopPropagation();
                  onDelete(route._id);
                }}
                size="small"
                sx={{
                  color: "text.secondary",
                  p: 0.75,
                  transition: "all 0.2s ease",
                  "&:hover": { 
                    color: "#ef4444", 
                    bgcolor: "rgba(239, 68, 68, 0.15)",
                    transform: "scale(1.05)",
                  },
                }}
              >
                <TrashIcon className="w-4 h-4" />
              </IconButton>
            </Tooltip>
          </div>

          <div className="flex justify-between items-start gap-3 mb-6">
            <div className="flex items-center space-x-4 flex-1 min-w-0 pr-20">
              <Avatar
                className="route-icon-avatar"
                sx={{
                  bgcolor: isSelected ? `${routeColor}30` : `${routeColor}15`,
                  color: routeColor,
                  width: 52,
                  height: 52,
                  borderRadius: "16px",
                  transition: "all 0.3s ease",
                  flexShrink: 0,
                }}
              >
                <MapIcon className="w-7 h-7" />
              </Avatar>
              <div className="flex-1 min-w-0">
                <Typography
                  variant="h6"
                  sx={{ 
                    fontWeight: 800, 
                    color: "text.primary", 
                    lineHeight: 1.2,
                    wordBreak: "break-word",
                  }}
                >
                  {route.routeName}
                </Typography>
                <Typography
                  variant="caption"
                  sx={{
                    color: "text.secondary",
                    fontWeight: 600,
                    fontFamily: "monospace",
                  }}
                >
                  ID: {route._id?.substring(0, 8).toUpperCase()}
                </Typography>
              </div>
            </div>
          </div>

          <div className="space-y-4">
            {/* Start Stop Container */}
            <div 
              className="flex items-start space-x-3 hover:bg-slate-50/60 dark:hover:bg-slate-800/30 p-2 -m-2 rounded-2xl transition-all duration-200"
              onMouseEnter={() => onHoverStop && onHoverStop(startStop?._id || startStop?.name)}
              onMouseLeave={() => onHoverStop && onHoverStop(null)}
            >
              <div className="flex flex-col items-center mt-1">
                <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 ring-4 ring-emerald-50"></div>
                {!expanded && (
                  <div className="w-0.5 h-12 bg-linear-to-b from-emerald-200 to-blue-200 my-1 border-dashed border-l"></div>
                )}
              </div>
              <div className="flex-1">
                <Typography
                  variant="body2"
                  sx={{ fontWeight: 800, color: "text.primary" }}
                >
                  {startStop?.name || "Starting Point"}
                </Typography>
                <Typography variant="caption" sx={{ color: "text.secondary" }}>
                  Pickup Point • {startStop?.location?.lat.toFixed(4)},{" "}
                  {startStop?.location?.lng.toFixed(4)}
                </Typography>
              </div>
            </div>
 
            {!expanded && intermediateStopsCount > 0 && (
              <div className="flex items-center space-x-3 py-1">
                <div className="flex justify-center w-2.5">
                  <EllipsisHorizontalIcon className="w-4 h-4 text-slate-300 rotate-90" />
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setExpanded(true);
                  }}
                  className="text-[10px] font-black uppercase tracking-widest px-2.5 py-1 rounded-full transition-all duration-200 hover:scale-105"
                  style={{
                    color: routeColor,
                    backgroundColor: `${routeColor}15`,
                  }}
                >
                  +{intermediateStopsCount} Intermediate Stops
                </button>
              </div>
            )}

            <Collapse in={expanded} timeout="auto" unmountOnExit>
              <div className="pl-[5px] border-l-2 border-dashed border-slate-200 dark:border-slate-700 ml-[4px] space-y-4 my-4">
                {stops.slice(1, -1).map((stop, idx) => (
                  <div 
                    key={idx} 
                    className="pl-6 relative hover:bg-slate-50/60 dark:hover:bg-slate-800/30 p-2 -m-2 rounded-2xl transition-all duration-200"
                    onMouseEnter={() => onHoverStop && onHoverStop(stop._id || stop.name)}
                    onMouseLeave={() => onHoverStop && onHoverStop(null)}
                  >
                    <div className="absolute left-[-6px] top-3.5 w-2 h-2 rounded-full bg-slate-400 border-2 border-white"></div>
                    <Typography
                      variant="body2"
                      sx={{ fontWeight: 600, color: "text.primary" }}
                    >
                      {stop.name}
                    </Typography>
                    <Typography variant="caption" sx={{ color: "text.secondary" }}>
                      {stop.location?.lat.toFixed(4)},{" "}
                      {stop.location?.lng.toFixed(4)}
                    </Typography>
                  </div>
                ))}
              </div>
            </Collapse>
 
            {/* Terminus Stop Container */}
            <div 
              className="flex items-start space-x-3 hover:bg-slate-50/60 dark:hover:bg-slate-800/30 p-2 -m-2 rounded-2xl transition-all duration-200"
              onMouseEnter={() => onHoverStop && onHoverStop(endStop?._id || endStop?.name)}
              onMouseLeave={() => onHoverStop && onHoverStop(null)}
            >
              <div className="w-2.5 h-2.5 rounded-full bg-blue-500 ring-4 ring-blue-50 mt-1.5"></div>
              <div className="flex-1">
                <Typography
                  variant="body2"
                  sx={{ fontWeight: 800, color: "text.primary" }}
                >
                  {endStop?.name || "Destination"}
                </Typography>
                <Typography variant="caption" sx={{ color: "text.secondary" }}>
                  Final Stop • {endStop?.location?.lat.toFixed(4)},{" "}
                  {endStop?.location?.lng.toFixed(4)}
                </Typography>
              </div>
            </div>
          </div>

          <div className="mt-8 pt-6 border-t border-border-theme flex justify-between items-center">
            <div className="flex items-center space-x-2">
              <PinIcon className="w-4 h-4 text-slate-300" />
              <Typography
                variant="body2"
                sx={{ fontWeight: 700, color: "text.secondary" }}
              >
                {stops.length} Total Stops
              </Typography>
            </div>
            {stops.length > 2 && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setExpanded(!expanded);
                }}
                className="flex items-center space-x-1 text-sm font-bold transition-colors px-3 py-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800"
                style={{ color: routeColor }}
              >
                <span>{expanded ? "Hide Details" : "View Full Path"}</span>
                {expanded ? (
                  <ChevronUpIcon className="w-4 h-4" />
                ) : (
                  <ChevronDownIcon className="w-4 h-4" />
                )}
              </button>
            )}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
};

export default RouteCard;
