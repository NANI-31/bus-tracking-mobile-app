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
} from "recharts";

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
      <div className="flex items-center justify-center p-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (!advancedAnalytics) return null;

  const COLORS = ["#10b981", "#6366f1", "#f43f5e", "#f59e0b"];

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
        <h1 className="text-2xl font-bold text-slate-800 flex items-center">
          <ChartBarIcon className="w-8 h-8 mr-2 text-indigo-600" />
          Advanced Business Intelligence
        </h1>
        <p className="text-slate-500 mt-1">
          Deep dive into user retention and renewal behavior
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex items-center space-x-4">
          <div className="p-3 bg-red-100 rounded-xl">
            <UserMinusIcon className="w-8 h-8 text-red-600" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 uppercase">
              Churn Rate
            </p>
            <h3 className="text-2xl font-bold text-slate-800">
              {advancedAnalytics.churnRate}%
            </h3>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex items-center space-x-4">
          <div className="p-3 bg-indigo-100 rounded-xl">
            <ArrowPathIcon className="w-8 h-8 text-indigo-600" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 uppercase">
              Early Renewals
            </p>
            <h3 className="text-2xl font-bold text-slate-800">
              {advancedAnalytics.earlyRenewalCount}
            </h3>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex items-center space-x-4">
          <div className="p-3 bg-emerald-100 rounded-xl">
            <TrendingUpIcon className="w-8 h-8 text-emerald-600" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 uppercase">
              Renewal Trend
            </p>
            <h3 className="text-2xl font-bold text-slate-800">
              {advancedAnalytics.earlyRenewalTrend.toFixed(1)}%
            </h3>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-100">
          <h2 className="text-lg font-bold text-slate-800 mb-6">
            Retention vs Churn
          </h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={churnData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {churnData.map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={COLORS[index === 0 ? 0 : 2]}
                    />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-center space-x-6 text-sm font-medium text-slate-500 mt-4">
            <div className="flex items-center">
              <div className="w-3 h-3 bg-emerald-500 rounded-full mr-2"></div>{" "}
              Retained
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-red-500 rounded-full mr-2"></div>{" "}
              Churned
            </div>
          </div>
        </div>

        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-100">
          <h2 className="text-lg font-bold text-slate-800 mb-6">
            Payment Composition
          </h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={trendData}>
                <XAxis dataKey="name" hide />
                <YAxis />
                <Tooltip cursor={{ fill: "#f8fafc" }} />
                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                  {trendData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index + 1]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-center space-x-6 text-sm font-medium text-slate-500 mt-4">
            <div className="flex items-center">
              <div className="w-3 h-3 bg-indigo-500 rounded-full mr-2"></div>{" "}
              Standard
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-rose-500 rounded-full mr-2"></div>{" "}
              Early Renewal
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdvancedAnalytics;
