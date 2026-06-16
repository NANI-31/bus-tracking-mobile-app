import React, { useState, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  CalendarDaysIcon,
  BuildingOfficeIcon,
  ChartBarIcon,
  InformationCircleIcon,
  ArrowPathIcon,
} from "@heroicons/react/24/outline";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import {
  getColleges,
  getCollegeStorageHistory,
} from "../slices/superAdminSlice";
import GlassmorphicTooltip from "@/components/common/GlassmorphicTooltip";
import DatePicker from "@/components/common/DatePicker";

const CollegeStorageAnalysis = () => {
  const dispatch = useDispatch();
  const { colleges, collegeStorageHistory, loading } = useSelector(
    (state) => state.superAdmin,
  );

  const [selectedCollege, setSelectedCollege] = useState("");
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
      .toISOString()
      .split("T")[0],
    end: new Date().toISOString().split("T")[0],
  });

  useEffect(() => {
    if (colleges.length === 0) {
      dispatch(getColleges());
    }
  }, [dispatch, colleges.length]);

  useEffect(() => {
    if (selectedCollege) {
      dispatch(
        getCollegeStorageHistory({
          collegeId: selectedCollege,
          startDate: dateRange.start,
          endDate: dateRange.end,
        }),
      );
    }
  }, [dispatch, selectedCollege, dateRange]);

  const handleCollegeChange = (e) => {
    setSelectedCollege(e.target.value);
  };

  const handleDateChange = (e) => {
    setDateRange((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const trendData = collegeStorageHistory.map((entry) => ({
    date: new Date(entry.date).toLocaleDateString([], {
      month: "short",
      day: "numeric",
    }),
    storage: entry.estimatedStorageMB,
    s3: entry.s3StorageMB || 0,
    users: entry.counts?.users || 0,
    buses: entry.counts?.buses || 0,
    docs:
      (entry.counts?.users || 0) +
      (entry.counts?.transactions || 0) +
      (entry.counts?.notifications || 0),
  }));

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      {/* Filters Header */}
      <div className="p-6 border-b border-slate-100 bg-slate-50/50">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-[#1E90FF] rounded-lg text-white">
              <BuildingOfficeIcon className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-800">
                Per-College Analysis
              </h2>
              <p className="text-xs text-slate-500">
                Track storage and document growth by tenant
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center space-x-2 bg-white border border-slate-200 rounded-lg px-3 py-1.5 shadow-sm">
              <BuildingOfficeIcon className="w-4 h-4 text-slate-400" />
              <select
                value={selectedCollege}
                onChange={handleCollegeChange}
                className="text-sm font-medium text-slate-700 outline-none bg-transparent"
              >
                <option value="">Select a College</option>
                {colleges.map((c) => (
                  <option key={c._id} value={c._id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-center space-x-2">
              <DatePicker
                value={dateRange.start}
                onChange={(val) => setDateRange((prev) => ({ ...prev, start: val }))}
                placeholder="Start Date"
                className="w-[140px]"
              />
              <span className="text-slate-400 text-xs font-semibold">to</span>
              <DatePicker
                value={dateRange.end}
                onChange={(val) => setDateRange((prev) => ({ ...prev, end: val }))}
                placeholder="End Date"
                className="w-[140px]"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Content Area */}
      <div className="p-6 min-h-[400px]">
        <AnimatePresence mode="wait">
          {!selectedCollege ? (
            <motion.div
              key="placeholder"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="flex flex-col items-center justify-center h-full py-20 text-center"
            >
              <InformationCircleIcon className="w-12 h-12 text-slate-200 mb-2" />
              <p className="text-slate-400 text-sm">
                Select a college to view storage metrics and trends
              </p>
            </motion.div>
          ) : loading && collegeStorageHistory.length === 0 ? (
            <motion.div
              key="loading"
              className="flex items-center justify-center h-full py-20"
            >
              <ArrowPathIcon className="w-8 h-8 text-indigo-500 animate-spin" />
            </motion.div>
          ) : (
            <motion.div
              key="stats"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="space-y-8"
            >
              {/* Main Chart */}
              <div className="h-[300px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={trendData}>
                    <defs>
                      <linearGradient
                        id="colorStore"
                        x1="0"
                        y1="0"
                        x2="0"
                        y2="1"
                      >
                        <stop
                          offset="5%"
                          stopColor="#1E90FF"
                          stopOpacity={0.1}
                        />
                        <stop
                          offset="95%"
                          stopColor="#1E90FF"
                          stopOpacity={0}
                        />
                      </linearGradient>
                      <linearGradient id="colorS3" x1="0" y1="0" x2="0" y2="1">
                        <stop
                          offset="5%"
                          stopColor="#FF9900"
                          stopOpacity={0.1}
                        />
                        <stop
                          offset="95%"
                          stopColor="#FF9900"
                          stopOpacity={0}
                        />
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
                    />
                    <Tooltip content={<GlassmorphicTooltip />} />
                    <Legend
                      verticalAlign="top"
                      align="right"
                      iconType="circle"
                      wrapperStyle={{ fontSize: "11px", paddingBottom: "20px" }}
                    />
                    <Area
                      type="monotone"
                      dataKey="storage"
                      stroke="#1E90FF"
                      strokeWidth={3}
                      fillOpacity={1}
                      fill="url(#colorStore)"
                      name="DB Storage (MB)"
                    />
                    <Area
                      type="monotone"
                      dataKey="s3"
                      stroke="#FF9900"
                      strokeWidth={3}
                      fillOpacity={1}
                      fill="url(#colorS3)"
                      name="S3 Assets (MB)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>

              {/* Data Breakdown Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                {[
                  {
                    label: "Active Users",
                    value: trendData[trendData.length - 1]?.users || 0,
                    color: "text-blue-600",
                    bg: "bg-blue-50",
                  },
                  {
                    label: "Total Buses",
                    value: trendData[trendData.length - 1]?.buses || 0,
                    color: "text-rose-600",
                    bg: "bg-rose-50",
                  },
                  {
                    label: "S3 Assets",
                    value:
                      (trendData[trendData.length - 1]?.s3 || 0).toFixed(2) +
                      "MB",
                    color: "text-amber-600",
                    bg: "bg-amber-50",
                  },
                ].map((stat, i) => (
                  <div
                    key={i}
                    className={`p-4 rounded-xl ${stat.bg} border border-white/50 shadow-sm transition-transform hover:scale-[1.02]`}
                  >
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      {stat.label}
                    </p>
                    <p className={`text-2xl font-black ${stat.color}`}>
                      {stat.value}
                    </p>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Technical Note */}
      <div className="p-4 bg-slate-50 border-t border-slate-100 flex items-start space-x-2">
        <InformationCircleIcon className="w-4 h-4 text-slate-400 mt-0.5" />
        <p className="text-[11px] text-slate-500 leading-tight">
          Storage metrics for colleges are estimated based on document counts
          across core collections multiplied by the global average object size.
          Detailed byte-level filtering is partially sampled from the primary
          metadata store.
        </p>
      </div>
    </div>
  );
};

export default CollegeStorageAnalysis;
