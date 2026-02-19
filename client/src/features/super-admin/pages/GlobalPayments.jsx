import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  CreditCardIcon,
  MagnifyingGlassIcon,
  GlobeAltIcon,
  FunnelIcon,
  CalendarIcon,
  BuildingLibraryIcon,
} from "@heroicons/react/24/outline";
import { getTransactions, getColleges } from "../slices/superAdminSlice";

const GlobalPayments = () => {
  const dispatch = useDispatch();
  const { transactions, colleges, loading } = useSelector(
    (state) => state.superAdmin,
  );

  const [search, setSearch] = useState("");
  const [showFilters, setShowFilters] = useState(false);
  const [plan, setPlan] = useState("");
  const [collegeId, setCollegeId] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  useEffect(() => {
    dispatch(getColleges());
  }, [dispatch]);

  useEffect(() => {
    const params = {};
    if (plan) params.plan = plan;
    if (collegeId) params.collegeId = collegeId;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    if (search) params.search = search;

    dispatch(getTransactions(params));
  }, [dispatch, plan, collegeId, startDate, endDate, search]);

  const resetFilters = () => {
    setPlan("");
    setCollegeId("");
    setStartDate("");
    setEndDate("");
    setSearch("");
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 flex items-center">
            <GlobeAltIcon className="w-8 h-8 mr-2 text-indigo-600" />
            Global Revenue & Subscriptions
          </h1>
          <p className="text-slate-500 mt-1">
            Monitor across {colleges.length} colleges
          </p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center px-4 py-2 rounded-lg border transition-all ${showFilters ? "bg-indigo-50 border-indigo-200 text-indigo-600 shadow-inner" : "bg-white border-slate-300 text-slate-700 hover:bg-slate-50 shadow-sm"}`}
          >
            <FunnelIcon className="w-5 h-5 mr-2" />
            Filters
            {(plan || collegeId || startDate || endDate) && (
              <span className="ml-2 w-2 h-2 bg-indigo-600 rounded-full"></span>
            )}
          </button>
          <div className="relative">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search user, order..."
              className="pl-10 pr-4 py-2 w-64 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 shadow-sm transition-all"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>
      </div>

      {/* Filters Panel */}
      <AnimatePresence>
        {showFilters && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="overflow-hidden"
          >
            <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {/* Plan Filter */}
              <div className="space-y-2">
                <label className="text-sm font-semibold text-slate-700 block">
                  Subscription Plan
                </label>
                <div className="relative">
                  <CreditCardIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
                  <select
                    className="pl-10 pr-4 py-2 w-full border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-slate-50/50 appearance-none"
                    value={plan}
                    onChange={(e) => setPlan(e.target.value)}
                  >
                    <option value="">All Plans</option>
                    <option value="monthly">Monthly</option>
                    <option value="semester">Semesterly</option>
                  </select>
                </div>
              </div>

              {/* College Filter */}
              <div className="space-y-2">
                <label className="text-sm font-semibold text-slate-700 block">
                  College
                </label>
                <div className="relative">
                  <BuildingLibraryIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
                  <select
                    className="pl-10 pr-4 py-2 w-full border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-slate-50/50 appearance-none"
                    value={collegeId}
                    onChange={(e) => setCollegeId(e.target.value)}
                  >
                    <option value="">All Colleges</option>
                    {colleges.map((college) => (
                      <option key={college._id} value={college._id}>
                        {college.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Date Start */}
              <div className="space-y-2">
                <label className="text-sm font-semibold text-slate-700 block">
                  From Date
                </label>
                <div className="relative">
                  <CalendarIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
                  <input
                    type="date"
                    className="pl-10 pr-4 py-2 w-full border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-slate-50/50"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                </div>
              </div>

              {/* Date End */}
              <div className="space-y-2 flex flex-col justify-end">
                <label className="text-sm font-semibold text-slate-700 block">
                  To Date
                </label>
                <div className="flex space-x-2">
                  <div className="relative grow">
                    <CalendarIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
                    <input
                      type="date"
                      className="pl-10 pr-4 py-2 w-full border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-slate-50/50"
                      value={endDate}
                      onChange={(e) => setEndDate(e.target.value)}
                    />
                  </div>
                  <button
                    onClick={resetFilters}
                    className="px-4 py-2 text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors border border-slate-200"
                  >
                    Reset
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Transactions Table */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  User & College
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Payment Details
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Plan & Amount
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-slate-200">
              <AnimatePresence mode="popLayout">
                {transactions.map((tx) => (
                  <motion.tr
                    key={tx._id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="hover:bg-slate-50/50 transition-colors"
                  >
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-600 font-bold border border-slate-200">
                          {tx.userId?.fullName?.charAt(0) || "?"}
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-semibold text-slate-900">
                            {tx.userId?.fullName || "Deleted User"}
                          </div>
                          <div className="text-xs text-slate-500 font-mono">
                            College: {tx.collegeId || "N/A"}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-xs font-medium text-slate-700">
                        Order:{" "}
                        <span className="text-slate-500">{tx.orderId}</span>
                      </div>
                      <div className="text-xs font-medium text-slate-700 mt-0.5">
                        Pay:{" "}
                        <span className="text-slate-500">{tx.paymentId}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-bold uppercase ${tx.planType === "semester" ? "bg-purple-100 text-purple-700" : "bg-blue-100 text-blue-700"}`}
                      >
                        {tx.planType}
                      </span>
                      <div className="text-sm font-bold text-slate-900 mt-1">
                        ₹{(tx.amount / 100).toFixed(2)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-700">
                        {new Date(tx.createdAt).toLocaleDateString("en-IN", {
                          day: "2-digit",
                          month: "short",
                          year: "numeric",
                        })}
                      </div>
                      <div className="text-xs text-slate-400">
                        {new Date(tx.createdAt).toLocaleTimeString([], {
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right">
                      <span className="px-2.5 py-1 inline-flex text-xs leading-5 font-bold rounded-full bg-emerald-100 text-emerald-700 border border-emerald-200 shadow-sm">
                        Captured
                      </span>
                    </td>
                  </motion.tr>
                ))}
              </AnimatePresence>

              {transactions.length === 0 && !loading && (
                <tr>
                  <td colSpan="5" className="px-6 py-20 text-center">
                    <div className="flex flex-col items-center justify-center opacity-40">
                      <CreditCardIcon className="w-16 h-16 text-slate-400 mb-4" />
                      <p className="text-lg font-medium text-slate-500">
                        No transactions found
                      </p>
                      <p className="text-sm text-slate-400">
                        Try adjusting your filters or search query
                      </p>
                    </div>
                  </td>
                </tr>
              )}

              {loading && (
                <tr>
                  <td colSpan="5" className="px-6 py-20 text-center">
                    <div className="flex flex-col items-center justify-center">
                      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
                      <p className="mt-4 text-slate-500 font-medium">
                        Loading transactions...
                      </p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default GlobalPayments;
