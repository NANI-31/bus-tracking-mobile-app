import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  UsersIcon,
  TruckIcon,
  MapIcon,
  CheckCircleIcon,
  CloudIcon,
} from "@heroicons/react/24/outline";
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from "recharts";
import {
  getUsers,
  getBuses,
  getRoutes,
  getCollegeStats,
  getStorageHistory,
} from "@/features/college-admin/slices/collegeAdminSlice";

import StatCard from "../components/Dashboard/StatCard";
import GlassmorphicTooltip from "@/components/common/GlassmorphicTooltip";
import ChartSkeleton from "@/components/common/ChartSkeleton";

const Dashboard = () => {
  const dispatch = useDispatch();
  const { users, buses, routes, collegeStats, storageHistory, loading } =
    useSelector((state) => state.collegeAdmin);

  useEffect(() => {
    dispatch(getUsers());
    dispatch(getBuses());
    dispatch(getRoutes());
    dispatch(getCollegeStats());
    dispatch(getStorageHistory());
  }, [dispatch]);

  const trendData = storageHistory.map((entry) => ({
    date: new Date(entry.date).toLocaleDateString([], {
      month: "short",
      day: "numeric",
    }),
    db: entry.estimatedStorageMB,
    s3: entry.s3StorageMB || 0,
  }));

  const stats = [
    {
      title: "Total Users",
      value: users.length,
      icon: UsersIcon,
      color: "bg-linear-to-br from-[#1E90FF] to-[#1C64F2]",
      delay: 0,
    },
    {
      title: "Active Buses",
      value: buses.length,
      icon: TruckIcon,
      color: "bg-linear-to-br from-[#4ADE80] to-[#22C55E]",
      delay: 0.1,
    },
    {
      title: "Total Routes",
      value: routes.length,
      icon: MapIcon,
      color: "bg-linear-to-br from-[#A78BFA] to-[#8B5CF6]",
      delay: 0.2,
    },
    {
      title: "S3 Audio Storage",
      value: collegeStats?.s3?.totalSize || "0 MB",
      icon: CloudIcon,
      color: "bg-linear-to-br from-[#FF9900] to-[#FFB84D]",
      delay: 0.3,
    },
  ];

  if (loading && users.length === 0) {
    return (
      <div className="space-y-8">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-gray-800">Dashboard Overview</h1>
          <p className="text-gray-500 text-xs sm:text-sm">Welcome back, Administrator</p>
        </div>

        {/* 4 StatCard Skeletons */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-white rounded-[24px] border border-slate-100 p-6 flex items-center space-x-5 shadow-sm">
              <div className="p-4 rounded-2xl w-16 h-16 shimmer shrink-0" />
              <div className="space-y-2 flex-1">
                <div className="h-3.5 shimmer rounded-md w-16" />
                <div className="h-6 shimmer rounded-md w-24" />
              </div>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Storage trends chart skeleton */}
          <div className="lg:col-span-2">
            <ChartSkeleton type="area" />
          </div>

          {/* System Insights skeleton */}
          <div className="bg-white rounded-[24px] shadow-sm border border-slate-100 p-6 h-[380px] flex flex-col justify-between">
            <div className="space-y-4">
              <div className="h-4 shimmer rounded-md w-32 mb-6" />
              {[1, 2].map((i) => (
                <div key={i} className="p-4 bg-slate-50/50 rounded-2xl border border-slate-100 space-y-2.5">
                  <div className="h-3.5 shimmer rounded-md w-20" />
                  <div className="h-3 shimmer rounded-md w-full" />
                  <div className="h-3 shimmer rounded-md w-2/3" />
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      <div>
        <h1 className="text-scale-h1 text-slate-800 dark:text-slate-100">Dashboard Overview</h1>
        <p className="text-text-theme-secondary text-xs sm:text-sm">Welcome back, Administrator</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        {stats.map((stat) => (
          <StatCard key={stat.title} {...stat} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 lg:gap-6">
        {/* Storage Trends Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="lg:col-span-2 bg-background-paper rounded-xl shadow-sm border border-border-theme p-6 text-text-theme-primary transition-all duration-300"
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-scale-h3 text-text-theme-primary">Storage Trends</h2>
            <div className="flex items-center space-x-2 text-xs text-text-theme-secondary">
              <span className="flex items-center">
                <span className="w-2 h-2 rounded-full bg-[#1E90FF] mr-1"></span>{" "}
                Database
              </span>
              <span className="flex items-center">
                <span className="w-2 h-2 rounded-full bg-[#FF9900] mr-1"></span>{" "}
                S3 Assets
              </span>
            </div>
          </div>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={trendData}>
                <defs>
                  <linearGradient id="colorDB" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#1E90FF" stopOpacity={0.35} />
                    <stop offset="50%" stopColor="#1E90FF" stopOpacity={0.12} />
                    <stop offset="95%" stopColor="#1E90FF" stopOpacity={0.01} />
                  </linearGradient>
                  <linearGradient id="colorS3" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#FF9900" stopOpacity={0.35} />
                    <stop offset="50%" stopColor="#FF9900" stopOpacity={0.12} />
                    <stop offset="95%" stopColor="#FF9900" stopOpacity={0.01} />
                  </linearGradient>
                </defs>
                <CartesianGrid
                  strokeDasharray="4 4"
                  vertical={false}
                  stroke="var(--border-color)"
                />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 11, fill: "var(--text-secondary)", fontWeight: 500 }}
                  axisLine={false}
                  tickLine={false}
                  dy={10}
                />
                <YAxis
                  tick={{ fontSize: 11, fill: "var(--text-secondary)", fontWeight: 500 }}
                  axisLine={false}
                  tickLine={false}
                  dx={-10}
                  label={{
                    value: "MB",
                    angle: -90,
                    position: "insideLeft",
                    fontSize: 10,
                    fill: "var(--text-secondary)",
                    fontWeight: 605,
                  }}
                />
                <Tooltip content={<GlassmorphicTooltip />} cursor={{ stroke: "var(--border-color)", strokeWidth: 1 }} />
                <Area
                  type="monotone"
                  dataKey="db"
                  stroke="#1E90FF"
                  strokeWidth={4}
                  dot={{ r: 0 }}
                  activeDot={{ r: 6, stroke: "var(--background-paper)", strokeWidth: 3 }}
                  fillOpacity={1}
                  fill="url(#colorDB)"
                  name="DB Storage"
                />
                <Area
                  type="monotone"
                  dataKey="s3"
                  stroke="#FF9900"
                  strokeWidth={4}
                  dot={{ r: 0 }}
                  activeDot={{ r: 6, stroke: "var(--background-paper)", strokeWidth: 3 }}
                  fillOpacity={1}
                  fill="url(#colorS3)"
                  name="S3 Assets"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </motion.div>

        {/* Quick Info / Platform Updates */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="bg-background-paper rounded-xl shadow-sm border border-border-theme p-6 text-text-theme-primary transition-all duration-300"
        >
          <h2 className="text-scale-h3 text-text-theme-primary mb-4">
            System Insights
          </h2>
          <div className="space-y-4">
            <div className="p-3 bg-blue-500/10 rounded-lg border border-blue-500/20">
              <p className="text-xs font-bold text-[#1E90FF] dark:text-blue-400 uppercase mb-1">
                Data Policy
              </p>
              <p className="text-[11px] text-text-theme-secondary leading-snug">
                Audio assets are automatically purged after 5 days of inactivity
                to optimize storage costs.
              </p>
            </div>
            <div className="p-3 bg-amber-500/10 rounded-lg border border-amber-500/20">
              <p className="text-xs font-bold text-amber-700 dark:text-amber-400 uppercase mb-1">
                Usage Alert
              </p>
              <p className="text-[11px] text-text-theme-secondary leading-snug">
                S3 Storage is calculated in real-time. History samples are taken
                daily at midnight.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default Dashboard;
