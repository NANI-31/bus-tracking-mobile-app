import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  CircleStackIcon,
  ServerIcon,
  ArrowPathIcon,
  ChartBarIcon,
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

const MetricRow = ({ label, value, subtext }) => (
  <div className="flex justify-between items-center py-2 border-b border-slate-50 last:border-0">
    <span className="text-slate-500 text-sm">{label}</span>
    <div className="text-right">
      <span className="text-slate-800 font-semibold text-sm">{value}</span>
      {subtext && (
        <p className="text-[10px] text-slate-400 leading-none">{subtext}</p>
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
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8 text-center">
        <ArrowPathIcon className="w-8 h-8 text-indigo-500 animate-spin mx-auto mb-2" />
        <p className="text-slate-500 text-sm">Analyzing storage usage...</p>
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
      color: "#c7d2fe",
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
  }));

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* MongoDB Analysis */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col"
        >
          <div className="bg-[#1E90FF] p-4 flex justify-between items-center text-white">
            <div className="flex items-center space-x-2">
              <CircleStackIcon className="w-5 h-5" />
              <h2 className="font-bold">MongoDB Analysis</h2>
            </div>
            <button
              onClick={refreshStats}
              className="p-1 hover:bg-white/20 rounded-full transition-colors"
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
                  >
                    {mongoChartData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip
                    contentStyle={{
                      borderRadius: "8px",
                      border: "none",
                      boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                    }}
                    formatter={(value) => [`${value.toFixed(2)} MB`, "Size"]}
                  />
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
          className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col"
        >
          <div className="bg-rose-600 p-4 flex justify-between items-center text-white">
            <div className="flex items-center space-x-2">
              <ServerIcon className="w-5 h-5" />
              <h2 className="font-bold">Redis Cloud Analysis</h2>
            </div>
            <button
              onClick={refreshStats}
              className="p-1 hover:bg-white/20 rounded-full transition-colors"
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
                  <RechartsTooltip
                    cursor={{ fill: "#fff5f5" }}
                    contentStyle={{
                      borderRadius: "8px",
                      border: "none",
                      boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                    }}
                  />
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
              <div className="mt-4 p-3 bg-slate-50 rounded-lg border border-slate-100 italic text-[11px] text-slate-500 ring-1 ring-slate-200 ring-inset">
                Real-time memory pressure for Pub/Sub adapter and session cache.
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
        className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden"
      >
        <div className="p-4 border-b border-slate-100 flex items-center space-x-2">
          <ChartBarIcon className="w-5 h-5 text-slate-400" />
          <h2 className="font-bold text-slate-800 uppercase tracking-wider text-xs">
            24-Hour Storage Trends
          </h2>
        </div>
        <div className="p-6 h-[250px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={trendData}>
              <defs>
                <linearGradient id="colorMongo" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1E90FF" stopOpacity={0.1} />
                  <stop offset="95%" stopColor="#1E90FF" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorRedis" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.1} />
                  <stop offset="95%" stopColor="#f43f5e" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid
                strokeDasharray="3 3"
                vertical={false}
                stroke="#f1f5f9"
              />
              <XAxis
                dataKey="time"
                tick={{ fontSize: 10, fill: "#94a3b8" }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                tick={{ fontSize: 10, fill: "#94a3b8" }}
                axisLine={false}
                tickLine={false}
                label={{
                  value: "MB",
                  angle: -90,
                  position: "insideLeft",
                  fontSize: 10,
                  fill: "#cbd5e1",
                }}
              />
              <RechartsTooltip
                contentStyle={{
                  borderRadius: "12px",
                  border: "none",
                  boxShadow: "0 10px 15px -3px rgb(0 0 0 / 0.1)",
                }}
              />
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
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </motion.div>
    </div>
  );
};

export default StorageAnalysis;
