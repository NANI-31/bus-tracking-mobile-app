import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  ChartBarIcon,
  UserMinusIcon,
  ArrowPathIcon,
  ArrowTrendingUpIcon as TrendingUpIcon,
} from "@heroicons/react/24/outline";
import { getAdvancedAnalytics } from "@/features/super-admin/slices/superAdminSlice";
import GlassmorphicTooltip from "@/components/common/GlassmorphicTooltip";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";

import ChartSkeleton from "@/components/common/ChartSkeleton";

const AdvancedAnalytics = () => {
  const dispatch = useDispatch();
  const { advancedAnalytics, analyticsLoading } = useSelector(
    (state) => state.superAdmin,
  );

  useEffect(() => {
    dispatch(getAdvancedAnalytics());
  }, [dispatch]);

  if (analyticsLoading) {
    return (
      <div className="space-y-8">
        <div>
          <h1 className="text-scale-h1 text-slate-800 dark:text-slate-100">Advanced Business Intelligence</h1>
          <p className="text-text-theme-secondary mt-1">Deep dive into user retention and renewal behavior</p>
        </div>

        {/* 3 StatCard skeletons */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-background-paper p-6 rounded-2xl shadow-sm border border-border-theme flex items-center space-x-4">
              <div className="p-3 w-14 h-14 shimmer rounded-xl shrink-0" />
              <div className="space-y-2 flex-1">
                <div className="h-3 shimmer rounded-md w-20" />
                <div className="h-6 shimmer rounded-md w-16" />
              </div>
            </div>
          ))}
        </div>

        {/* 2 ChartSkeletons */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div>
            <ChartSkeleton type="area" />
          </div>
          <div>
            <ChartSkeleton type="bar" />
          </div>
        </div>
      </div>
    );
  }

  if (!advancedAnalytics) return null;

  const churnData = [
    { name: "Retained", value: 100 - advancedAnalytics.churnRate },
    { name: "Churned", value: advancedAnalytics.churnRate },
  ];

  const trendData = [
    {
      name: "Standard",
      value:
        advancedAnalytics.totalTransactions -
        advancedAnalytics.earlyRenewalCount,
    },
    { name: "Early Renewal", value: advancedAnalytics.earlyRenewalCount },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-scale-h1 text-slate-800 dark:text-slate-100 flex items-center">
          <ChartBarIcon className="w-8 h-8 mr-2 text-indigo-600 dark:text-indigo-400" />
          Advanced Business Intelligence
        </h1>
        <p className="text-text-theme-secondary mt-1">
          Deep dive into user retention and renewal behavior
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-background-paper p-6 rounded-2xl shadow-sm border border-border-theme flex items-center space-x-4 text-text-theme-primary transition-all duration-300">
          <div className="p-3 bg-red-500/10 text-red-600 dark:text-red-400 rounded-xl shrink-0">
            <UserMinusIcon className="w-8 h-8" />
          </div>
          <div>
            <p className="text-sm font-semibold text-text-theme-secondary uppercase">
              Churn Rate
            </p>
            <h3 className="text-2xl font-bold text-text-theme-primary">
              {advancedAnalytics.churnRate}%
            </h3>
          </div>
        </div>

        <div className="bg-background-paper p-6 rounded-2xl shadow-sm border border-border-theme flex items-center space-x-4 text-text-theme-primary transition-all duration-300">
          <div className="p-3 bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 rounded-xl shrink-0">
            <ArrowPathIcon className="w-8 h-8" />
          </div>
          <div>
            <p className="text-sm font-semibold text-text-theme-secondary uppercase">
              Early Renewals
            </p>
            <h3 className="text-2xl font-bold text-text-theme-primary">
              {advancedAnalytics.earlyRenewalCount}
            </h3>
          </div>
        </div>

        <div className="bg-background-paper p-6 rounded-2xl shadow-sm border border-border-theme flex items-center space-x-4 text-text-theme-primary transition-all duration-300">
          <div className="p-3 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 rounded-xl shrink-0">
            <TrendingUpIcon className="w-8 h-8" />
          </div>
          <div>
            <p className="text-sm font-semibold text-text-theme-secondary uppercase">
              Renewal Trend
            </p>
            <h3 className="text-2xl font-bold text-text-theme-primary">
              {advancedAnalytics.earlyRenewalTrend.toFixed(1)}%
            </h3>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-background-paper p-8 rounded-2xl shadow-sm border border-border-theme text-text-theme-primary transition-all duration-300">
          <h2 className="text-scale-h3 text-text-theme-primary mb-6">
            Retention vs Churn
          </h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <defs>
                  <linearGradient id="pieRetained" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#10b981" stopOpacity={0.9} />
                    <stop offset="100%" stopColor="#059669" stopOpacity={0.9} />
                  </linearGradient>
                  <linearGradient id="pieChurned" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#f43f5e" stopOpacity={0.9} />
                    <stop offset="100%" stopColor="#e11d48" stopOpacity={0.9} />
                  </linearGradient>
                </defs>
                <Pie
                  data={churnData}
                  cx="50%"
                  cy="50%"
                  innerRadius={65}
                  outerRadius={85}
                  paddingAngle={4}
                  stroke="var(--background-paper)"
                  strokeWidth={3}
                  dataKey="value"
                >
                  <Cell key="cell-0" fill="url(#pieRetained)" />
                  <Cell key="cell-1" fill="url(#pieChurned)" />
                </Pie>
                <Tooltip content={<GlassmorphicTooltip />} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-center space-x-6 text-sm font-semibold text-text-theme-secondary mt-4">
            <div className="flex items-center">
              <div className="w-3.5 h-3.5 bg-linear-to-br from-emerald-400 to-emerald-600 rounded-full mr-2 shadow-sm"></div>{" "}
              Retained
            </div>
            <div className="flex items-center">
              <div className="w-3.5 h-3.5 bg-linear-to-br from-rose-400 to-rose-600 rounded-full mr-2 shadow-sm"></div>{" "}
              Churned
            </div>
          </div>
        </div>

        <div className="bg-background-paper p-8 rounded-2xl shadow-sm border border-border-theme text-text-theme-primary transition-all duration-300">
          <h2 className="text-scale-h3 text-text-theme-primary mb-6">
            Payment Composition
          </h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={trendData} barSize={32}>
                <defs>
                  <linearGradient id="barStandard" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#6366f1" stopOpacity={0.9} />
                    <stop offset="100%" stopColor="#4f46e5" stopOpacity={0.9} />
                  </linearGradient>
                  <linearGradient id="barEarly" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#f59e0b" stopOpacity={0.9} />
                    <stop offset="100%" stopColor="#d97706" stopOpacity={0.9} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="4 4" vertical={false} stroke="var(--border-color)" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "var(--text-secondary)", fontWeight: 600 }} dy={8} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "var(--text-secondary)" }} dx={-8} />
                <Tooltip cursor={{ fill: "var(--border-color)", opacity: 0.15 }} content={<GlassmorphicTooltip />} />
                <Bar dataKey="value" radius={[12, 12, 0, 0]}>
                  <Cell key="cell-0" fill="url(#barStandard)" />
                  <Cell key="cell-1" fill="url(#barEarly)" />
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-center space-x-6 text-sm font-semibold text-text-theme-secondary mt-4">
            <div className="flex items-center">
              <div className="w-3.5 h-3.5 bg-linear-to-br from-indigo-400 to-indigo-600 rounded-full mr-2 shadow-sm"></div>{" "}
              Standard
            </div>
            <div className="flex items-center">
              <div className="w-3.5 h-3.5 bg-linear-to-br from-amber-400 to-amber-600 rounded-full mr-2 shadow-sm"></div>{" "}
              Early Renewal
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdvancedAnalytics;
