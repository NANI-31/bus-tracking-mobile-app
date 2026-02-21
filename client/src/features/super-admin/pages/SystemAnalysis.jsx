import React from "react";
import { motion } from "framer-motion";
import { ServerIcon, ArrowLeftIcon } from "@heroicons/react/24/outline";
import { useNavigate } from "react-router-dom";
import StorageAnalysis from "@/features/super-admin/components/StorageAnalysis";
import CollegeStorageAnalysis from "@/features/super-admin/components/CollegeStorageAnalysis";

const SystemAnalysis = () => {
  const navigate = useNavigate();

  return (
    <div className="space-y-12">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 tracking-tight">
            System Analysis
          </h1>
          <p className="text-slate-500 mt-1">
            Infrastructure health and storage consumption metrics across the
            platform.
          </p>
        </div>
        <button
          onClick={() => navigate("/super-admin")}
          className="flex items-center space-x-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-50 transition-all shadow-sm active:scale-95"
        >
          <ArrowLeftIcon className="w-4 h-4" />
          <span className="text-sm font-semibold">Back to Overview</span>
        </button>
      </div>

      {/* Per-College Analysis Section (NEW) */}
      <section>
        <div className="mb-6">
          <h2 className="text-xl font-extrabold text-slate-800 flex items-center space-x-2">
            <span className="w-2 h-6 bg-[#1E90FF] rounded-full inline-block"></span>
            <span>Tenant Distribution</span>
          </h2>
        </div>
        <CollegeStorageAnalysis />
      </section>

      {/* Infrastructure Analysis Section */}
      <section>
        <div className="mb-6">
          <h2 className="text-xl font-extrabold text-slate-800 flex items-center space-x-2">
            <span className="w-2 h-6 bg-slate-800 rounded-full inline-block"></span>
            <span>Global Infrastructure</span>
          </h2>
        </div>
        <motion.div
          initial={{ opacity: 0, scale: 0.98 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.4 }}
        >
          <StorageAnalysis />
        </motion.div>
      </section>

      {/* Additional Stats / Information */}
      <div className="p-6 bg-[#1E90FF] border border-[#1E90FF] rounded-xl">
        <div className="flex items-start space-x-4">
          <div className="p-2 bg-[#1E90FF] rounded-lg text-white">
            <ServerIcon className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-slate-800 mb-1">
              Infrastructure Insight
            </h3>
            <p className="text-slate-600 text-sm leading-relaxed">
              These metrics reflect the current load on the primary storage and
              caching layers. Monitor <strong>fragmentation ratio</strong> and{" "}
              <strong>storage size</strong> closely to ensure optimal
              performance. High fragmentation may indicate a need for cache
              eviction policy reviews.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SystemAnalysis;
