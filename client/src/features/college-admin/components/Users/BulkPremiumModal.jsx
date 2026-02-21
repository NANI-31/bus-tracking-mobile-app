import React from "react";
import { motion } from "framer-motion";
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
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md"
      >
        <div className="flex justify-between items-start mb-4">
          <h2 className="text-xl font-bold text-gray-800 flex items-center">
            <CloudArrowUpIcon className="w-6 h-6 mr-2 text-[#1E90FF]" />
            Bulk Premium Activation
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <XCircleIcon className="w-6 h-6" />
          </button>
        </div>
        <p className="text-sm text-gray-500 mb-6">
          Upload an Excel file (.xlsx) containing a column for "Roll Number" or
          "Email" to activate premium in bulk.
        </p>

        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Plan Duration
            </label>
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setPlanType("monthly")}
                className={`px-4 py-2 rounded-lg text-sm border transition-colors ${
                  planType === "monthly"
                    ? "bg-[#1E90FF] text-white border-[#1E90FF]"
                    : "bg-white text-gray-600 border-gray-200"
                }`}
              >
                Monthly (30 Days)
              </button>
              <button
                type="button"
                onClick={() => setPlanType("semesterly")}
                className={`px-4 py-2 rounded-lg text-sm border transition-colors ${
                  planType === "semesterly"
                    ? "bg-[#1E90FF] text-white border-[#1E90FF]"
                    : "bg-white text-gray-600 border-gray-200"
                }`}
              >
                Semesterly (120 Days)
              </button>
            </div>
          </div>

          <div className="border-2 border-dashed border-gray-200 rounded-xl p-8 text-center bg-gray-50">
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
              <CloudArrowUpIcon className="w-12 h-12 text-gray-400 mb-2" />
              <span className="text-sm text-gray-600">
                {uploadFile ? uploadFile.name : "Click to select Excel file"}
              </span>
            </label>
          </div>

          <div className="flex space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border rounded-lg text-gray-600 hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!uploadFile}
              className={`flex-1 px-4 py-2 rounded-lg text-white font-medium ${
                !uploadFile
                  ? "bg-gray-300 cursor-not-allowed"
                  : "bg-[#1E90FF] hover:bg-indigo-700"
              }`}
            >
              Start Upload
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

export default BulkPremiumModal;
