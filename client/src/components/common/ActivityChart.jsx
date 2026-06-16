import React, { useState, useMemo, useRef, useEffect } from "react";
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip as ChartTooltip,
  CartesianGrid,
  ReferenceArea,
} from "recharts";
import { motion, AnimatePresence } from "framer-motion";
import { MagnifyingGlassMinusIcon } from "@heroicons/react/24/outline";

const ActivityChart = ({ data, loading }) => {
  const containerRef = useRef(null);
  const [zoomRange, setZoomRange] = useState({ left: null, right: null });
  const [refAreaLeft, setRefAreaLeft] = useState(null);
  const [refAreaRight, setRefAreaRight] = useState(null);
  const [toolMode, setToolMode] = useState("zoom"); // 'zoom' | 'pan'
  const [isPanning, setIsPanning] = useState(false);
  const [startX, setStartX] = useState(null);
  const [startLeft, setStartLeft] = useState(null);
  const [startRight, setStartRight] = useState(null);

  // Reset zoom when dataset changes
  useEffect(() => {
    setZoomRange({ left: null, right: null });
  }, [data]);

  const chartData = useMemo(() => {
    if (!data || data.length === 0) return [];

    const times = data.map((log) => new Date(log.createdAt).getTime());
    const minTime = Math.min(...times);
    const maxTime = Math.max(...times);
    const timeSpan = maxTime - minTime;

    // Dynamic grouping base on duration of logs
    let groupFn;
    if (timeSpan < 3 * 3600 * 1000) {
      // Group by 1 minute
      groupFn = (date) => {
        date.setSeconds(0, 0);
        return date.getTime();
      };
    } else if (timeSpan < 36 * 3600 * 1000) {
      // Group by 10 minutes
      groupFn = (date) => {
        date.setMinutes(Math.floor(date.getMinutes() / 10) * 10, 0, 0);
        return date.getTime();
      };
    } else {
      // Group by 1 hour
      groupFn = (date) => {
        date.setMinutes(0, 0, 0);
        return date.getTime();
      };
    }

    const groups = {};
    data.forEach((log) => {
      const date = new Date(log.createdAt);
      const key = groupFn(date);
      groups[key] = (groups[key] || 0) + 1;
    });

    return Object.keys(groups)
      .sort()
      .map((key) => ({
        time: parseInt(key),
        count: groups[key],
      }));
  }, [data]);

  const bounds = useMemo(() => {
    if (chartData.length === 0) return { min: 0, max: 0 };
    const times = chartData.map((d) => d.time);
    return {
      min: Math.min(...times),
      max: Math.max(...times),
    };
  }, [chartData]);

  if (loading && (!data || data.length === 0)) {
    return (
      <div className="p-6 bg-background-paper border border-border-theme rounded-2xl h-[200px] flex items-center justify-center">
        <p className="text-text-theme-secondary text-sm font-bold animate-pulse">
          Analyzing activity trends...
        </p>
      </div>
    );
  }

  if (!data || data.length === 0) return null;

  const xDomainLeft = zoomRange.left !== null ? zoomRange.left : bounds.min;
  const xDomainRight = zoomRange.right !== null ? zoomRange.right : bounds.max;

  // Expand domain slightly if they are equal to avoid rendering issues
  const domainLeft = xDomainLeft === xDomainRight ? xDomainLeft - 30000 : xDomainLeft;
  const domainRight = xDomainLeft === xDomainRight ? xDomainRight + 30000 : xDomainRight;

  const isZoomed = zoomRange.left !== null || zoomRange.right !== null;

  const handleMouseDown = (e) => {
    if (!e || !e.activePayload) return;
    const clickedTime = e.activePayload[0].payload.time;
    if (toolMode === "zoom") {
      setRefAreaLeft(clickedTime);
      setRefAreaRight(clickedTime);
    } else if (toolMode === "pan") {
      setIsPanning(true);
      setStartX(e.chartX);
      setStartLeft(domainLeft);
      setStartRight(domainRight);
    }
  };

  const handleMouseMove = (e) => {
    if (!e) return;
    if (toolMode === "zoom" && refAreaLeft !== null) {
      if (e.activePayload) {
        setRefAreaRight(e.activePayload[0].payload.time);
      }
    } else if (toolMode === "pan" && isPanning && startX !== null) {
      const dx = e.chartX - startX;
      const containerWidth = containerRef.current?.clientWidth || 600;
      const currentSpan = startRight - startLeft;
      const dt = (dx / containerWidth) * currentSpan;
      
      let newLeft = startLeft - dt;
      let newRight = startRight - dt;

      // Limit range
      if (newLeft < bounds.min) {
        newLeft = bounds.min;
        newRight = bounds.min + currentSpan;
      }
      if (newRight > bounds.max) {
        newRight = bounds.max;
        newLeft = bounds.max - currentSpan;
      }

      setZoomRange({ left: newLeft, right: newRight });
    }
  };

  const handleMouseUp = () => {
    if (toolMode === "zoom" && refAreaLeft !== null && refAreaRight !== null) {
      let l = refAreaLeft;
      let r = refAreaRight;
      if (l > r) {
        const temp = l;
        l = r;
        r = temp;
      }
      if (r - l > 1000) {
        setZoomRange({ left: l, right: r });
      }
    }
    setRefAreaLeft(null);
    setRefAreaRight(null);
    setIsPanning(false);
    setStartX(null);
  };

  const resetZoom = () => {
    setZoomRange({ left: null, right: null });
  };

  const formatDateTick = (tick) => {
    const date = new Date(tick);
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      className="mb-4 bg-background-paper border border-border-theme rounded-[24px] p-6 shadow-xs relative overflow-hidden group/chart"
    >
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-4 select-none">
        <div>
          <h3 className="text-xs font-black text-text-theme-secondary uppercase tracking-widest">
            Activity Density (Recent Logs)
          </h3>
          <p className="text-[10px] text-text-theme-secondary mt-0.5">
            {toolMode === "zoom"
              ? "Click & drag on chart area to zoom in"
              : "Click & drag on chart area to pan timeline"}
          </p>
        </div>

        <div className="flex items-center gap-2">
          {/* Reset Zoom Button */}
          <AnimatePresence>
            {isZoomed && (
              <motion.button
                initial={{ opacity: 0, scale: 0.9, x: 10 }}
                animate={{ opacity: 1, scale: 1, x: 0 }}
                exit={{ opacity: 0, scale: 0.9, x: 10 }}
                onClick={resetZoom}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-rose-500/10 text-rose-500 hover:bg-rose-500/20 text-[11px] font-bold rounded-xl transition-all cursor-pointer border border-rose-500/20"
              >
                <MagnifyingGlassMinusIcon className="w-3.5 h-3.5" />
                Reset Zoom
              </motion.button>
            )}
          </AnimatePresence>

          {/* Tool Toggle Button Group */}
          <div className="bg-background-default border border-border-theme rounded-xl p-0.5 flex items-center shadow-xs">
            <button
              onClick={() => setToolMode("zoom")}
              className={`p-1.5 rounded-lg text-xs font-bold flex items-center gap-1 transition-all cursor-pointer ${
                toolMode === "zoom"
                  ? "bg-[#1E90FF] text-white shadow-xs"
                  : "text-text-theme-secondary hover:text-text-theme-primary"
              }`}
              title="Zoom Tool (Drag to select area)"
            >
              <svg
                className="w-3.5 h-3.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth="2.5"
              >
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
                <line x1="11" y1="8" x2="11" y2="14" />
                <line x1="8" y1="11" x2="14" y2="11" />
              </svg>
              <span className="hidden md:inline text-[10px] uppercase font-black tracking-wider px-0.5">Zoom</span>
            </button>
            <button
              onClick={() => setToolMode("pan")}
              className={`p-1.5 rounded-lg text-xs font-bold flex items-center gap-1 transition-all cursor-pointer ${
                toolMode === "pan"
                  ? "bg-[#1E90FF] text-white shadow-xs"
                  : "text-text-theme-secondary hover:text-text-theme-primary"
              }`}
              title="Pan Tool (Drag to scroll timeline)"
            >
              <svg
                className="w-3.5 h-3.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth="2.5"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M10.05 5.05a5 5 0 0 1 4.05 4.05M9 18.01l3.6-3.6m0 0L9 10.8m3.6 3.61H3m18-3.6a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
                />
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M8.25 9.75h.008v.008H8.25V9.75Z"
                />
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M7 11.5V14c0 2.5 1.5 4 4 4h1c2.5 0 4-1.5 4-4v-3c0-1-.5-1.5-1.5-1.5s-1.5.5-1.5 1.5V13m-2-3V8.5c0-1-.5-1.5-1.5-1.5S8 7.5 8 8.5V13m-2-1v-2c0-1-.5-1.5-1.5-1.5S3 9.5 3 10.5V15c0 3 2 5 5 5h3c3 0 5-2 5-5v-6c0-1-.5-1.5-1.5-1.5S13 8.5 13 9.5V12"
                />
              </svg>
              <span className="hidden md:inline text-[10px] uppercase font-black tracking-wider px-0.5">Pan</span>
            </button>
          </div>
        </div>
      </div>

      <div
        ref={containerRef}
        className={`w-full h-[200px] select-none ${
          toolMode === "zoom" ? "cursor-crosshair" : isPanning ? "cursor-grabbing" : "cursor-grab"
        }`}
      >
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={chartData}
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            margin={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <defs>
              <linearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#1E90FF" stopOpacity={0.25} />
                <stop offset="100%" stopColor="#1E90FF" stopOpacity={0.0} />
              </linearGradient>
            </defs>
            <CartesianGrid
              vertical={false}
              strokeDasharray="3 3"
              stroke="var(--border-theme)"
              opacity={0.3}
            />
            <XAxis
              dataKey="time"
              type="number"
              domain={[domainLeft, domainRight]}
              scale="time"
              tickFormatter={formatDateTick}
              stroke="#ffffff"
              fontSize={10}
              fontWeight={700}
              tickLine={false}
              axisLine={false}
              dy={10}
              tick={{ fill: "#ffffff", opacity: 0.8 }}
            />
            <YAxis
              allowDecimals={false}
              stroke="#ffffff"
              fontSize={10}
              fontWeight={700}
              tickLine={false}
              axisLine={false}
              width={40}
              tick={{ fill: "#ffffff", opacity: 0.8 }}
            />
            <ChartTooltip
              content={({ active, payload }) => {
                if (active && payload && payload.length) {
                  const item = payload[0].payload;
                  return (
                    <div className="bg-background-paper border border-border-theme p-3 rounded-2xl shadow-xl flex flex-col gap-1 text-[11px] font-bold">
                      <span className="text-text-theme-secondary">
                        {new Date(item.time).toLocaleString()}
                      </span>
                      <span className="text-[#1E90FF]">
                        Events Count: {item.count}
                      </span>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Area
              type="monotone"
              dataKey="count"
              stroke="#1E90FF"
              strokeWidth={3}
              fill="url(#chartGradient)"
              activeDot={{ r: 6, stroke: "#1E90FF", strokeWidth: 2, fill: "#fff" }}
              dot={false}
              isAnimationActive={false}
            />
            {refAreaLeft && refAreaRight ? (
              <ReferenceArea
                x1={refAreaLeft}
                x2={refAreaRight}
                strokeOpacity={0.3}
                fill="#1E90FF"
                fillOpacity={0.15}
              />
            ) : null}
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </motion.div>
  );
};

export default ActivityChart;
