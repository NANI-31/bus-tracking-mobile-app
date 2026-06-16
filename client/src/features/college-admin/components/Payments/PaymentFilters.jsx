import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import DatePicker from "@/components/common/DatePicker";

const PaymentFilters = ({
  showFilters,
  plan,
  setPlan,
  startDate,
  setStartDate,
  endDate,
  setEndDate,
  resetFilters,
}) => {
  return (
    <AnimatePresence>
      {showFilters && (
        <motion.div
          initial={{ height: 0, opacity: 0 }}
          animate={{ height: "auto", opacity: 1 }}
          exit={{ height: 0, opacity: 0 }}
          className="overflow-hidden"
        >
          <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="space-y-2">
              <label className="text-sm font-semibold text-slate-700 block">
                Plan Type
              </label>
              <select
                className="w-full border border-slate-200 rounded-lg p-2 focus:ring-2 focus:ring-blue-500 bg-slate-50"
                value={plan}
                onChange={(e) => setPlan(e.target.value)}
              >
                <option value="">All Plans</option>
                <option value="monthly">Monthly</option>
                <option value="semester">Semesterly</option>
              </select>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-semibold text-slate-700 block">
                Date Range
              </label>
              <div className="flex space-x-2">
                <DatePicker
                  value={startDate}
                  onChange={setStartDate}
                  placeholder="Start Date"
                  className="w-1/2"
                />
                <DatePicker
                  value={endDate}
                  onChange={setEndDate}
                  placeholder="End Date"
                  className="w-1/2"
                />
              </div>
            </div>

            <div className="flex items-end">
              <button
                onClick={resetFilters}
                className="w-full py-2 text-slate-600 hover:text-[#1E90FF] hover:bg-blue-50 rounded-lg border border-slate-200 transition-colors"
              >
                Clear All Filters
              </button>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default PaymentFilters;
