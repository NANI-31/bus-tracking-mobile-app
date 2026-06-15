import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  CreditCardIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  CalendarIcon,
  CheckBadgeIcon,
} from "@heroicons/react/24/outline";
import {
  getTransactions,
  getSubscriptionAnalytics,
} from "@/features/college-admin/slices/collegeAdminSlice";
import SubscriptionAnalytics from "../components/Payments/SubscriptionAnalytics";

import PaymentTable from "../components/Payments/PaymentTable";
import PaymentFilters from "../components/Payments/PaymentFilters";
import DensitySelector from "@/components/common/DensitySelector";

const Payments = () => {
  const dispatch = useDispatch();
  const { transactions, analytics, loading } = useSelector(
    (state) => state.collegeAdmin,
  );

  const [search, setSearch] = useState("");
  const [density, setDensity] = useState("default");
  const [showFilters, setShowFilters] = useState(false);
  const [plan, setPlan] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  useEffect(() => {
    const params = {};
    if (plan) params.plan = plan;
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    if (search) params.search = search;

    dispatch(getTransactions(params));
    dispatch(getSubscriptionAnalytics());
  }, [dispatch, plan, startDate, endDate, search]);

  const resetFilters = () => {
    setPlan("");
    setStartDate("");
    setEndDate("");
    setSearch("");
  };

  return (
    <div className="space-y-6">
      {/* Header Snippet */}
      <div className="flex justify-between items-center bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <div>
          <h1 className="text-scale-h1 text-slate-800 flex items-center">
            <CreditCardIcon className="w-8 h-8 mr-2 text-[#1E90FF]" />
            Premium Subscriptions
          </h1>
          <p className="text-slate-500 mt-1">
            Manage payments and student plans
          </p>
        </div>
        <div className="flex items-center space-x-3">
          <DensitySelector currentDensity={density} onChange={setDensity} />
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center px-4 py-2 rounded-lg border transition-all ${
              showFilters
                ? "bg-blue-50 border-blue-200 text-[#1E90FF]"
                : "bg-white border-slate-300 text-slate-700 hover:bg-slate-50"
            }`}
          >
            <FunnelIcon className="w-5 h-5 mr-2" />
            Filters
          </button>
          <div className="relative">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search student, order..."
              className="pl-10 pr-4 py-2 w-64 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>
      </div>

      <PaymentFilters
        showFilters={showFilters}
        plan={plan}
        setPlan={setPlan}
        startDate={startDate}
        setStartDate={setStartDate}
        endDate={endDate}
        setEndDate={setEndDate}
        resetFilters={resetFilters}
      />

      <SubscriptionAnalytics data={analytics} />

      <PaymentTable transactions={transactions} loading={loading} density={density} />
    </div>
  );
};

export default Payments;
