import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  UsersIcon,
  TruckIcon,
  MapIcon,
  CheckCircleIcon,
} from "@heroicons/react/24/outline";
import {
  getUsers,
  getBuses,
  getRoutes,
} from "@/features/college-admin/slices/collegeAdminSlice";

import StatCard from "../components/Dashboard/StatCard";

const Dashboard = () => {
  const dispatch = useDispatch();
  const { users, buses, routes, loading } = useSelector(
    (state) => state.collegeAdmin,
  );

  useEffect(() => {
    dispatch(getUsers());
    dispatch(getBuses());
    dispatch(getRoutes());
  }, [dispatch]);

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
      title: "System Status",
      value: "Online",
      icon: CheckCircleIcon,
      color: "bg-gradient-to-br from-[#00FFD1] to-[#0D9488]",
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

      {/* Recent Activity or Charts placeholder */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.4 }}
        className="bg-white rounded-xl shadow-sm p-6"
      >
        <h2 className="text-lg font-bold text-gray-800 mb-4">
          Recent Activity
        </h2>
        <div className="text-gray-500 text-sm">
          Activity logs and charts will appear here.
        </div>
      </motion.div>
    </div>
  );
};

export default Dashboard;
