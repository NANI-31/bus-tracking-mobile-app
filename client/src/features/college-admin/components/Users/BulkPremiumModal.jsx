import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { CloudArrowUpIcon, XCircleIcon } from "@heroicons/react/24/outline";

const BulkPremiumModal = ({
  isOpen,
  onClose,
  onSubmit,
  planType,
  setPlanType,
  uploadFile,
  setUploadFile,
}) => {
  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 modal-backdrop"
          />

          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 350 }}
            className="relative bg-white/75 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-white/30 dark:border-slate-800 shadow-2xl p-6 w-full max-w-md z-10 text-slate-850 dark:text-slate-100"
          >
            <div className="flex justify-between items-start mb-4">
              <h2 className="text-xl font-bold text-slate-800 dark:text-slate-100 flex items-center">
                <CloudArrowUpIcon className="w-6 h-6 mr-2 text-[#1E90FF]" />
                Bulk Premium Activation
              </h2>
              <button
                onClick={onClose}
                className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
              >
                <XCircleIcon className="w-6 h-6" />
              </button>
            </div>
            <p className="text-sm text-slate-500 dark:text-slate-400 mb-6">
              Upload an Excel file (.xlsx) containing a column for "Roll Number" or
              "Email" to activate premium in bulk.
            </p>

            <form onSubmit={onSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                  Plan Duration
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => setPlanType("monthly")}
                    className={`px-4 py-2.5 rounded-lg text-sm font-semibold border transition-colors cursor-pointer ${
                      planType === "monthly"
                        ? "bg-[#1E90FF] text-white border-[#1E90FF]"
                        : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700"
                    }`}
                  >
                    Monthly (30 Days)
                  </button>
                  <button
                    type="button"
                    onClick={() => setPlanType("semesterly")}
                    className={`px-4 py-2.5 rounded-lg text-sm font-semibold border transition-colors cursor-pointer ${
                      planType === "semesterly"
                        ? "bg-[#1E90FF] text-white border-[#1E90FF]"
                        : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700"
                    }`}
                  >
                    Semesterly (120 Days)
                  </button>
                </div>
              </div>

              <div className="border-2 border-dashed border-slate-250 dark:border-slate-700 rounded-xl p-8 text-center bg-slate-50/50 dark:bg-slate-850/30">
                <input
                  type="file"
                  accept=".xlsx, .xls"
                  onChange={(e) => setUploadFile(e.target.files[0])}
                  className="hidden"
                  id="excel-upload"
                />
                <label
                  htmlFor="excel-upload"
                  className="cursor-pointer flex flex-col items-center"
                >
                  <CloudArrowUpIcon className="w-12 h-12 text-slate-400 dark:text-slate-500 mb-2" />
                  <span className="text-sm font-semibold text-slate-600 dark:text-slate-300">
                    {uploadFile ? uploadFile.name : "Click to select Excel file"}
                  </span>
                </label>
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  type="button"
                  onClick={onClose}
                  className="flex-1 px-4 py-2.5 border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 font-bold transition-all text-sm cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!uploadFile}
                  className={`flex-1 px-4 py-2.5 rounded-xl text-white font-bold transition-all active:scale-95 text-sm cursor-pointer ${
                    !uploadFile
                      ? "bg-slate-200 dark:bg-slate-800 text-slate-400 dark:text-slate-600 cursor-not-allowed"
                      : "bg-[#1E90FF] hover:bg-[#1C64F2]"
                  }`}
                >
                  Start Upload
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

export default BulkPremiumModal;
