import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  CircleStackIcon,
  ServerIcon,
  ArrowPathIcon,
  ChartBarIcon,
  CloudIcon,
} from "@heroicons/react/24/outline";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip as RechartsTooltip,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Legend,
  AreaChart,
  Area,
  CartesianGrid,
} from "recharts";
import { getStorageStats } from "@/features/super-admin/slices/superAdminSlice";
import GlassmorphicTooltip from "@/components/common/GlassmorphicTooltip";

const MetricRow = ({ label, value, subtext }) => (
  <div className="flex justify-between items-center py-2 border-b border-border-theme/40 last:border-0">
    <span className="text-text-theme-secondary text-sm">{label}</span>
    <div className="text-right">
      <span className="text-text-theme-primary font-semibold text-sm">{value}</span>
      {subtext && (
        <p className="text-[10px] text-text-theme-secondary leading-none mt-0.5">{subtext}</p>
      )}
    </div>
  </div>
);

const StorageAnalysis = () => {
  const dispatch = useDispatch();
  const { storageStats, loading } = useSelector((state) => state.superAdmin);

  useEffect(() => {
    dispatch(getStorageStats());
  }, [dispatch]);

  const refreshStats = () => {
    dispatch(getStorageStats());
  };

  const parseSize = (sizeStr) => {
    if (typeof sizeStr === "number") return sizeStr;
    if (!sizeStr) return 0;
    return parseFloat(sizeStr.split(" ")[0]);
  };

  if (loading && !storageStats) {
    return (
      <div className="bg-background-paper rounded-xl shadow-sm border border-border-theme p-8 text-center text-text-theme-primary transition-colors duration-300">
        <ArrowPathIcon className="w-8 h-8 text-[#1E90FF] animate-spin mx-auto mb-2" />
        <p className="text-text-theme-secondary text-sm">Analyzing storage usage...</p>
      </div>
    );
  }

  if (!storageStats) return null;

  const { mongodb, redis, history } = storageStats;

  // MongoDB Data for Donut Chart
  const mongoChartData = [
    { name: "Data", value: parseSize(mongodb.dataSize), color: "#1E90FF" },
    { name: "Index", value: parseSize(mongodb.indexSize), color: "#8b5cf6" },
    {
      name: "Overhead",
      value: Math.max(
        0,
        parseSize(mongodb.storageSize) -
          parseSize(mongodb.dataSize) -
          parseSize(mongodb.indexSize),
      ),
      color: "#a5b4fc",
    },
  ];

  // Redis Data for Bar Chart
  const redisChartData = [
    {
      name: "Memory",
      used: parseSize(redis.usedMemory),
      peak: parseSize(redis.peakMemory),
    },
  ];

  // History Formatting
  const trendData = (history || []).map((entry) => ({
    time: new Date(entry.timestamp).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    }),
    mongo: parseSize(entry.mongodb.storageSize),
    redis: parseSize(entry.redis.usedMemoryBytes) / (1024 * 1024), // MB
    s3: parseSize(entry.s3?.totalSize || 0),
  }));

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* MongoDB Analysis */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-background-paper rounded-xl shadow-sm border border-border-theme overflow-hidden flex flex-col text-text-theme-primary transition-all duration-300"
        >
          <div className="bg-[#1E90FF] p-4 flex justify-between items-center text-white shrink-0">
            <div className="flex items-center space-x-2">
              <CircleStackIcon className="w-5 h-5" />
              <h2 className="font-bold">MongoDB Analysis</h2>
            </div>
            <button
              onClick={refreshStats}
              className="p-1 hover:bg-white/20 rounded-full transition-colors cursor-pointer"
              title="Refresh"
            >
              <ArrowPathIcon
                className={`w-4 h-4 ${loading ? "animate-spin" : ""}`}
              />
            </button>
          </div>

          <div className="p-5 flex-1 grid grid-cols-1 xl:grid-cols-2 gap-6 items-center">
            <div className="h-[200px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={mongoChartData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                    stroke="var(--background-paper)"
                    strokeWidth={2}
                  >
                    {mongoChartData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip content={<GlassmorphicTooltip formatter={(value) => `${value.toFixed(2)} MB`} />} />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="space-y-1">
              <MetricRow label="Collections" value={mongodb.collections} />
              <MetricRow label="Documents" value={mongodb.objects} />
              <MetricRow label="Data Size" value={mongodb.dataSize} />
              <MetricRow label="Index Size" value={mongodb.indexSize} />
              <MetricRow label="Disk Storage" value={mongodb.storageSize} />
            </div>
          </div>
        </motion.div>

        {/* Redis Analysis */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-background-paper rounded-xl shadow-sm border border-border-theme overflow-hidden flex flex-col text-text-theme-primary transition-all duration-300"
        >
          <div className="bg-rose-650 bg-rose-600 p-4 flex justify-between items-center text-white shrink-0">
            <div className="flex items-center space-x-2">
              <ServerIcon className="w-5 h-5" />
              <h2 className="font-bold">Redis Cloud Analysis</h2>
            </div>
            <button
              onClick={refreshStats}
              className="p-1 hover:bg-white/20 rounded-full transition-colors cursor-pointer"
              title="Refresh"
            >
              <ArrowPathIcon
                className={`w-4 h-4 ${loading ? "animate-spin" : ""}`}
              />
            </button>
          </div>

          <div className="p-5 flex-1 grid grid-cols-1 xl:grid-cols-2 gap-6 items-center">
            <div className="h-[200px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={redisChartData}
                  margin={{ top: 20, right: 30, left: 0, bottom: 0 }}
                >
                  <XAxis dataKey="name" hide />
                  <YAxis hide />
                  <RechartsTooltip cursor={{ fill: "var(--border-color)", opacity: 0.15 }} content={<GlassmorphicTooltip formatter={(value) => `${value} MB`} />} />
                  <Legend verticalAlign="top" iconType="circle" />
                  <Bar
                    dataKey="used"
                    fill="#f43f5e"
                    name="Used MB"
                    radius={[4, 4, 0, 0]}
                  />
                  <Bar
                    dataKey="peak"
                    fill="#fb7185"
                    name="Peak MB"
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div className="space-y-1">
              <MetricRow label="Used Memory" value={redis.usedMemory} />
              <MetricRow label="Peak Memory" value={redis.peakMemory} />
              <MetricRow label="Fragmentation" value={redis.fragmentation} />
              <div className="mt-4 p-3 bg-background-default border border-border-theme italic text-[11px] text-text-theme-secondary rounded-lg">
                Real-time memory pressure for Pub/Sub adapter and session cache.
              </div>
            </div>
          </div>
        </motion.div>

        {/* S3 Storage Analysis */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-background-paper rounded-xl shadow-sm border border-border-theme overflow-hidden flex flex-col text-text-theme-primary transition-all duration-300"
        >
          <div className="bg-[#FF9900] p-4 flex justify-between items-center text-white shrink-0">
            <div className="flex items-center space-x-2">
              <CloudIcon className="w-5 h-5" />
              <h2 className="font-bold">AWS S3 Assets</h2>
            </div>
            <button
              onClick={refreshStats}
              className="p-1 hover:bg-white/20 rounded-full transition-colors cursor-pointer"
              title="Refresh"
            >
              <ArrowPathIcon
                className={`w-4 h-4 ${loading ? "animate-spin" : ""}`}
              />
            </button>
          </div>

          <div className="p-5 flex-1 flex flex-col justify-center">
            <div className="flex items-center justify-center mb-6">
              <div className="text-center">
                <span className="text-4xl font-black text-text-theme-primary">
                  {storageStats.s3?.totalSize || "0 MB"}
                </span>
                <p className="text-text-theme-secondary text-[10px] mt-1.5 uppercase tracking-widest font-black">
                  Total Audio Storage
                </p>
              </div>
            </div>

            <div className="space-y-1">
              <MetricRow
                label="Voice Notes"
                value={storageStats.s3?.objectCount || 0}
              />
              <MetricRow label="Retention" value="5 Days" />
              <div className="mt-4 p-3 bg-background-default border border-border-theme italic text-[11px] text-text-theme-secondary rounded-lg">
                Managed storage for all broadcast and directed voice messages
                across the platform.
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      {/* 24-Hour Trends */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bg-background-paper rounded-xl shadow-sm border border-border-theme overflow-hidden text-text-theme-primary transition-all duration-300"
      >
        <div className="p-4 border-b border-border-theme flex items-center space-x-2 bg-slate-50/50 dark:bg-slate-900/30">
          <ChartBarIcon className="w-5 h-5 text-text-theme-secondary" />
          <h2 className="font-bold text-text-theme-primary uppercase tracking-wider text-xs">
            24-Hour Storage Trends
          </h2>
        </div>
        <div className="p-6 h-[250px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={trendData}>
              <defs>
                <linearGradient id="colorMongo" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1E90FF" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#1E90FF" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorRedis" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#f43f5e" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorS3" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#FF9900" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#FF9900" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid
                strokeDasharray="3 3"
                vertical={false}
                stroke="var(--border-color)"
              />
              <XAxis
                dataKey="time"
                tick={{ fontSize: 10, fill: "var(--text-secondary)" }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                tick={{ fontSize: 10, fill: "var(--text-secondary)" }}
                axisLine={false}
                tickLine={false}
                label={{
                  value: "MB",
                  angle: -90,
                  position: "insideLeft",
                  fontSize: 10,
                  fill: "var(--text-secondary)",
                }}
              />
              <RechartsTooltip content={<GlassmorphicTooltip formatter={(value) => `${value.toFixed(2)} MB`} />} />
              <Legend
                verticalAlign="top"
                align="right"
                iconType="circle"
                wrapperStyle={{ fontSize: "10px", paddingBottom: "10px" }}
              />
              <Area
                type="monotone"
                dataKey="mongo"
                stroke="#1E90FF"
                strokeWidth={2}
                fillOpacity={1}
                fill="url(#colorMongo)"
                name="MongoDB Size"
              />
              <Area
                type="monotone"
                dataKey="redis"
                stroke="#f43f5e"
                strokeWidth={2}
                fillOpacity={1}
                fill="url(#colorRedis)"
                name="Redis Usage"
              />
              <Area
                type="monotone"
                dataKey="s3"
                stroke="#FF9900"
                strokeWidth={2}
                fillOpacity={1}
                fill="url(#colorS3)"
                name="S3 Assets"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </motion.div>
    </div>
  );
};

export default StorageAnalysis;
