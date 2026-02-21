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
  if (!isOpen || !selectedUser) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0.9, opacity: 0 }}
          className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden"
        >
          <div className="p-6 border-b flex justify-between items-center bg-gray-50">
            <h2 className="text-xl font-bold text-gray-800">Manage User</h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
            >
              <XCircleIcon className="w-6 h-6" />
            </button>
          </div>

          <div className="p-6 space-y-6">
            {/* User Info */}
            <div className="flex items-center space-x-4">
              <div className="h-16 w-16 rounded-full bg-indigo-100 flex items-center justify-center text-[#1E90FF] text-2xl font-bold">
                {selectedUser.fullName.charAt(0)}
              </div>
              <div>
                <h3 className="text-lg font-bold text-gray-900">
                  {selectedUser.fullName}
                </h3>
                <p className="text-sm text-gray-500">{selectedUser.email}</p>
                <span className="px-2 py-0.5 inline-flex text-xs font-semibold rounded-full bg-gray-100 text-gray-800 uppercase mt-1">
                  {selectedUser.role}
                </span>
              </div>
            </div>

            <div className="space-y-4">
              {/* Approval Status */}
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                <div>
                  <h4 className="font-bold text-gray-800">Access Status</h4>
                  <p className="text-xs text-gray-500">
                    {selectedUser.approved
                      ? "This user is currently approved."
                      : "This user is pending approval."}
                  </p>
                </div>
                {selectedUser.approved ? (
                  <button
                    onClick={() => handleReject(selectedUser._id)}
                    className="flex items-center space-x-2 text-yellow-600 bg-yellow-50 px-3 py-1.5 rounded-lg hover:bg-yellow-100 transition-colors"
                  >
                    <XCircleIcon className="w-4 h-4" />
                    <span className="text-sm font-bold">Revoke</span>
                  </button>
                ) : (
                  <button
                    onClick={() => handleApprove(selectedUser._id)}
                    className="flex items-center space-x-2 text-green-600 bg-green-50 px-3 py-1.5 rounded-lg hover:bg-green-100 transition-colors"
                  >
                    <CheckCircleIcon className="w-4 h-4" />
                    <span className="text-sm font-bold">Approve</span>
                  </button>
                )}
              </div>

              {/* Manual Premium - For Students only */}
              {currentCollege?.allowManualPremium &&
                selectedUser.role === "student" && (
                  <div className="p-4 border border-indigo-100 bg-indigo-50/30 rounded-xl">
                    <h4 className="font-bold text-indigo-900 mb-3 flex items-center">
                      <CurrencyDollarIcon className="w-5 h-5 mr-1" />
                      Manual Premium Grant
                    </h4>
                    <div className="grid grid-cols-2 gap-3">
                      <button
                        onClick={() =>
                          handleActivatePremium(selectedUser._id, "monthly")
                        }
                        className="flex flex-col items-center justify-center p-2 bg-[#1E90FF] text-white rounded-lg hover:bg-indigo-700 transition-colors"
                      >
                        <span className="font-bold text-sm">Monthly</span>
                        <span className="text-[10px] opacity-80">30 Days</span>
                      </button>
                      <button
                        onClick={() =>
                          handleActivatePremium(selectedUser._id, "semesterly")
                        }
                        className="flex flex-col items-center justify-center p-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                      >
                        <span className="font-bold text-sm">Semesterly</span>
                        <span className="text-[10px] opacity-80">120 Days</span>
                      </button>
                    </div>
                  </div>
                )}

              {/* Delete Option */}
              <div className="pt-4 border-t">
                <button
                  onClick={() => handleDelete(selectedUser._id)}
                  className="w-full flex items-center justify-center space-x-2 text-red-600 bg-red-50 py-3 rounded-xl hover:bg-red-100 transition-colors font-bold"
                >
                  <TrashIcon className="w-5 h-5" />
                  <span>Delete Account</span>
                </button>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};

export default UserActionModal;
