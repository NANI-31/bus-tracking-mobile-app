import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  XCircleIcon,
  CheckCircleIcon,
  TrashIcon,
  CurrencyDollarIcon,
} from "@heroicons/react/24/outline";

const UserActionModal = ({
  isOpen,
  onClose,
  selectedUser,
  handleApprove,
  handleReject,
  handleActivatePremium,
  handleDelete,
  currentCollege,
}) => {
  return (
    <AnimatePresence>
      {isOpen && selectedUser && (
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
            className="relative bg-white/75 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-white/30 dark:border-slate-800 shadow-2xl w-full max-w-md overflow-hidden z-10 text-slate-800 dark:text-slate-100"
          >
            <div className="p-6 border-b border-slate-100 dark:border-slate-800 flex justify-between items-center bg-slate-50 dark:bg-slate-900/50">
              <h2 className="text-xl font-bold text-slate-800 dark:text-slate-100">Manage User</h2>
              <button
                onClick={onClose}
                className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
              >
                <XCircleIcon className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* User Info */}
              <div className="flex items-center space-x-4">
                <div className="h-16 w-16 rounded-full bg-blue-100 dark:bg-blue-950/40 flex items-center justify-center text-[#1E90FF] text-2xl font-bold shrink-0">
                  {selectedUser.fullName.charAt(0)}
                </div>
                <div>
                  <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">
                    {selectedUser.fullName}
                  </h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400">{selectedUser.email}</p>
                  <span className="px-2 py-0.5 inline-flex text-xs font-semibold rounded-full bg-slate-100 dark:bg-slate-850 text-slate-800 dark:text-slate-200 uppercase mt-1">
                    {selectedUser.role}
                  </span>
                </div>
              </div>

              <div className="space-y-4">
                {/* Approval Status */}
                <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-850/50 border border-slate-100 dark:border-slate-800/80 rounded-xl">
                  <div>
                    <h4 className="font-bold text-slate-800 dark:text-slate-200">Access Status</h4>
                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                      {selectedUser.approved
                        ? "This user is currently approved."
                        : "This user is pending approval."}
                    </p>
                  </div>
                  {selectedUser.approved ? (
                    <button
                      onClick={() => handleReject(selectedUser._id)}
                      className="flex items-center space-x-2 text-yellow-600 dark:text-yellow-400 bg-yellow-50 dark:bg-yellow-950/20 px-3 py-1.5 rounded-lg hover:bg-yellow-100 dark:hover:bg-yellow-950/40 transition-colors cursor-pointer font-bold text-xs"
                    >
                      <XCircleIcon className="w-4 h-4" />
                      <span>Revoke</span>
                    </button>
                  ) : (
                    <button
                      onClick={() => handleApprove(selectedUser._id)}
                      className="flex items-center space-x-2 text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-950/20 px-3 py-1.5 rounded-lg hover:bg-green-100 dark:hover:bg-green-950/40 transition-colors cursor-pointer font-bold text-xs"
                    >
                      <CheckCircleIcon className="w-4 h-4" />
                      <span>Approve</span>
                    </button>
                  )}
                </div>

                {/* Manual Premium - For Students only */}
                {currentCollege?.allowManualPremium &&
                  selectedUser.role === "student" && (
                    <div className="p-4 border border-indigo-100 dark:border-indigo-950/50 bg-indigo-50/30 dark:bg-indigo-950/10 rounded-xl">
                      <h4 className="font-bold text-indigo-950 dark:text-indigo-300 mb-3 flex items-center">
                        <CurrencyDollarIcon className="w-5 h-5 mr-1" />
                        Manual Premium Grant
                      </h4>
                      <div className="grid grid-cols-2 gap-3">
                        <button
                          onClick={() =>
                            handleActivatePremium(selectedUser._id, "monthly")
                          }
                          className="flex flex-col items-center justify-center p-2 bg-[#1E90FF] text-white rounded-lg hover:bg-[#1C64F2] transition-all active:scale-95 cursor-pointer"
                        >
                          <span className="font-bold text-sm">Monthly</span>
                          <span className="text-[10px] opacity-85">30 Days</span>
                        </button>
                        <button
                          onClick={() =>
                            handleActivatePremium(selectedUser._id, "semesterly")
                          }
                          className="flex flex-col items-center justify-center p-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-all active:scale-95 cursor-pointer"
                        >
                          <span className="font-bold text-sm">Semesterly</span>
                          <span className="text-[10px] opacity-85">120 Days</span>
                        </button>
                      </div>
                    </div>
                  )}

                {/* Delete Option */}
                <div className="pt-4 border-t border-slate-100 dark:border-slate-800">
                  <button
                    onClick={() => handleDelete(selectedUser._id)}
                    className="w-full flex items-center justify-center space-x-2 text-red-600 bg-red-50 dark:bg-red-950/20 py-3 rounded-xl hover:bg-red-100 dark:hover:bg-red-950/40 transition-colors font-bold cursor-pointer"
                  >
                    <TrashIcon className="w-5 h-5" />
                    <span>Delete Account</span>
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

export default UserActionModal;
