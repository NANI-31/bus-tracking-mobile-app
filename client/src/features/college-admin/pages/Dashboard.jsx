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
      color: "bg-gradient-to-br from-[#1E90FF] to-[#1C64F2]",
      delay: 0,
    },
    {
      title: "Active Buses",
      value: buses.length,
      icon: TruckIcon,
      color: "bg-gradient-to-br from-[#4ADE80] to-[#22C55E]",
      delay: 0.1,
    },
    {
      title: "Total Routes",
      value: routes.length,
      icon: MapIcon,
      color: "bg-gradient-to-br from-[#A78BFA] to-[#8B5CF6]",
      delay: 0.2,
    },
    {
      title: "S3 Audio Storage",
      value: collegeStats?.s3?.totalSize || "0 MB",
      icon: CloudIcon,
      color: "bg-gradient-to-br from-[#FF9900] to-[#FFB84D]",
      delay: 0.3,
    },
  ];

  if (loading && users.length === 0) {
    return (
      <div className="p-8 text-center text-gray-500">
        Loading dashboard data...
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-gray-800">Dashboard Overview</h1>
        <p className="text-gray-500">Welcome back, Administrator</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <StatCard key={stat.title} {...stat} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Storage Trends Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="lg:col-span-2 bg-white rounded-xl shadow-sm border border-slate-100 p-6"
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-bold text-gray-800">Storage Trends</h2>
            <div className="flex items-center space-x-2 text-xs text-slate-500">
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
                    <stop offset="5%" stopColor="#1E90FF" stopOpacity={0.1} />
                    <stop offset="95%" stopColor="#1E90FF" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="colorS3" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#FF9900" stopOpacity={0.1} />
                    <stop offset="95%" stopColor="#FF9900" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                  stroke="#f1f5f9"
                />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  axisLine={false}
                  tickLine={false}
                />
                <YAxis
                  tick={{ fontSize: 11, fill: "#64748b" }}
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
                <Tooltip
                  contentStyle={{
                    borderRadius: "12px",
                    border: "none",
                    boxShadow: "0 10px 15px -3px rgb(0 0 0 / 0.1)",
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="db"
                  stroke="#1E90FF"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorDB)"
                  name="DB Storage"
                />
                <Area
                  type="monotone"
                  dataKey="s3"
                  stroke="#FF9900"
                  strokeWidth={3}
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
          className="bg-white rounded-xl shadow-sm border border-slate-100 p-6"
        >
          <h2 className="text-lg font-bold text-gray-800 mb-4">
            System Insights
          </h2>
          <div className="space-y-4">
            <div className="p-3 bg-blue-50 rounded-lg border border-blue-100">
              <p className="text-xs font-bold text-blue-800 uppercase mb-1">
                Data Policy
              </p>
              <p className="text-[11px] text-blue-600 leading-snug">
                Audio assets are automatically purged after 5 days of inactivity
                to optimize storage costs.
              </p>
            </div>
            <div className="p-3 bg-amber-50 rounded-lg border border-amber-100">
              <p className="text-xs font-bold text-amber-800 uppercase mb-1">
                Usage Alert
              </p>
              <p className="text-[11px] text-amber-600 leading-snug">
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
