import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  MapIcon,
  TrashIcon,
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

const RouteCard = ({ route, onDelete }) => {
  const [expanded, setExpanded] = useState(false);
  const stops = route.stopPoints || [];
  const startStop = stops[0];
  const endStop = stops[stops.length - 1];
  const intermediateStopsCount = Math.max(0, stops.length - 2);

  return (
    <motion.div
      layout
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      whileHover={{ y: -8, transition: { duration: 0.3 } }}
      transition={{ duration: 0.3 }}
    >
      <Card
        elevation={0}
        sx={{
          borderRadius: "24px",
          border: "2px solid #f1f5f9",
          bgcolor: "white",
          overflow: "hidden",
          transition: "all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)",
          boxShadow:
            "0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)",
          "&:hover": {
            boxShadow: "0 25px 50px -12px rgb(0 0 0 / 0.12)",
            borderColor: "#1E90FF",
            "& .route-icon-avatar": {
              transform: "scale(1.1) rotate(5deg)",
              bgcolor: "#e0f2fe",
            },
          },
        }}
      >
        <CardContent sx={{ p: 3 }}>
          <div className="flex justify-between items-start mb-6">
            <div className="flex items-center space-x-4">
              <Avatar
                className="route-icon-avatar"
                sx={{
                  bgcolor: "#f0f9ff",
                  color: "#1E90FF",
                  width: 52,
                  height: 52,
                  borderRadius: "16px",
                  transition: "all 0.3s ease",
                }}
              >
                <MapIcon className="w-7 h-7" />
              </Avatar>
              <div>
                <Typography
                  variant="h6"
                  sx={{ fontWeight: 800, color: "#1e293b", lineHeight: 1.2 }}
                >
                  {route.routeName}
                </Typography>
                <Typography
                  variant="caption"
                  sx={{
                    color: "#94a3b8",
                    fontWeight: 600,
                    fontFamily: "monospace",
                  }}
                >
                  ID: {route._id?.substring(0, 8).toUpperCase()}
                </Typography>
              </div>
            </div>
            <Tooltip title="Delete Route" arrow>
              <IconButton
                onClick={() => onDelete(route._id)}
                size="small"
                sx={{
                  color: "#94a3b8",
                  "&:hover": { color: "#ef4444", bgcolor: "#fef2f2" },
                }}
              >
                <TrashIcon className="w-5 h-5" />
              </IconButton>
            </Tooltip>
          </div>

          <div className="space-y-4">
            <div className="flex items-start space-x-3">
              <div className="flex flex-col items-center">
                <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 ring-4 ring-emerald-50"></div>
                {!expanded && (
                  <div className="w-0.5 h-12 bg-gradient-to-b from-emerald-200 to-blue-200 my-1 border-dashed border-l"></div>
                )}
              </div>
              <div className="flex-1">
                <Typography
                  variant="body2"
                  sx={{ fontWeight: 800, color: "#334155" }}
                >
                  {startStop?.name || "Starting Point"}
                </Typography>
                <Typography variant="caption" sx={{ color: "#94a3b8" }}>
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
                  onClick={() => setExpanded(true)}
                  className="text-[10px] font-black uppercase tracking-widest text-[#1E90FF] bg-blue-50 px-2.5 py-1 rounded-full hover:bg-blue-100 transition-colors"
                >
                  +{intermediateStopsCount} Intermediate Stops
                </button>
              </div>
            )}

            <Collapse in={expanded} timeout="auto" unmountOnExit>
              <div className="pl-[5px] border-l-2 border-dashed border-slate-200 ml-[4px] space-y-4 my-4">
                {stops.slice(1, -1).map((stop, idx) => (
                  <div key={idx} className="pl-6 relative">
                    <div className="absolute left-[-6px] top-1.5 w-2 h-2 rounded-full bg-slate-400 border-2 border-white"></div>
                    <Typography
                      variant="body2"
                      sx={{ fontWeight: 600, color: "#475569" }}
                    >
                      {stop.name}
                    </Typography>
                    <Typography variant="caption" sx={{ color: "#94a3b8" }}>
                      {stop.location?.lat.toFixed(4)},{" "}
                      {stop.location?.lng.toFixed(4)}
                    </Typography>
                  </div>
                ))}
              </div>
            </Collapse>

            <div className="flex items-start space-x-3">
              <div className="w-2.5 h-2.5 rounded-full bg-blue-500 ring-4 ring-blue-50 mt-1"></div>
              <div className="flex-1">
                <Typography
                  variant="body2"
                  sx={{ fontWeight: 800, color: "#334155" }}
                >
                  {endStop?.name || "Destination"}
                </Typography>
                <Typography variant="caption" sx={{ color: "#94a3b8" }}>
                  Final Stop • {endStop?.location?.lat.toFixed(4)},{" "}
                  {endStop?.location?.lng.toFixed(4)}
                </Typography>
              </div>
            </div>
          </div>

          <div className="mt-8 pt-6 border-t border-slate-50 flex justify-between items-center">
            <div className="flex items-center space-x-2">
              <PinIcon className="w-4 h-4 text-slate-300" />
              <Typography
                variant="body2"
                sx={{ fontWeight: 700, color: "#64748b" }}
              >
                {stops.length} Total Stops
              </Typography>
            </div>
            {stops.length > 2 && (
              <button
                onClick={() => setExpanded(!expanded)}
                className="flex items-center space-x-1 text-sm font-bold text-[#1E90FF] hover:text-[#1C64F2] transition-colors px-3 py-1.5 rounded-lg hover:bg-blue-50"
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
