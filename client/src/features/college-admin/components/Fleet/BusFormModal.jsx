import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { CheckCircleIcon, ExclamationCircleIcon } from "@heroicons/react/24/outline";

const BusFormModal = ({ isOpen, onClose, onSubmit }) => {
  const [formData, setFormData] = useState({
    busNumber: "",
    capacity: "",
    driverId: "",
  });

  const [errors, setErrors] = useState({
    busNumber: "",
    capacity: "",
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    const capacityVal = parseInt(formData.capacity);
    let hasError = false;
    const newErrors = { busNumber: "", capacity: "" };

    if (!formData.busNumber.trim()) {
      newErrors.busNumber = "Bus number is required.";
      hasError = true;
    } else if (!/^[A-Z0-9-]{3,10}$/i.test(formData.busNumber)) {
      newErrors.busNumber = "Must be 3-10 alphanumeric characters/hyphens.";
      hasError = true;
    }

    if (isNaN(capacityVal) || capacityVal <= 0 || capacityVal > 120) {
      newErrors.capacity = "Must be a seat capacity between 1 and 120.";
      hasError = true;
    }

    setErrors(newErrors);
    if (hasError) return;

    onSubmit(formData);
    setFormData({ busNumber: "", capacity: "", driverId: "" });
    setErrors({ busNumber: "", capacity: "" });
    onClose();
  };

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
            className="relative bg-white/75 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-white/30 dark:border-slate-800 shadow-2xl p-6 w-full max-w-md z-10 text-slate-800 dark:text-slate-100"
          >
            <h2 className="text-xl font-bold text-slate-800 dark:text-slate-100 mb-4">Add New Bus</h2>
            <form onSubmit={handleSubmit} className="space-y-2">
              {/* Bus Number Input Block */}
              <div className="relative pb-5">
                <label htmlFor="busNumberInput" className="block text-sm font-semibold text-slate-700 dark:text-slate-350">
                  Bus Number
                </label>
                <div className="relative mt-1">
                  <input
                    id="busNumberInput"
                    type="text"
                    required
                    placeholder="e.g. BUS-402"
                    className={`block w-full border rounded-xl p-2.5 pr-10 text-sm bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus-ring transition-colors ${
                      errors.busNumber 
                        ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5" 
                        : formData.busNumber && !errors.busNumber
                        ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5"
                        : "border-slate-300 dark:border-slate-700"
                    }`}
                    value={formData.busNumber}
                    onChange={(e) => {
                      const val = e.target.value;
                      setFormData({ ...formData, busNumber: val });
                      
                      // Live validation
                      let err = "";
                      if (!val.trim()) {
                        err = "Bus number is required.";
                      } else if (!/^[A-Z0-9-]{3,10}$/i.test(val)) {
                        err = "Must be 3-10 alphanumeric characters/hyphens.";
                      }
                      setErrors(prev => ({ ...prev, busNumber: err }));
                    }}
                  />
                  <div className="absolute right-3.5 top-3 flex items-center pointer-events-none z-10">
                    {formData.busNumber && !errors.busNumber && (
                      <CheckCircleIcon className="w-5 h-5 text-emerald-500" />
                    )}
                    {errors.busNumber && (
                      <ExclamationCircleIcon className="w-5 h-5 text-rose-500 animate-pulse" />
                    )}
                  </div>
                </div>
                <AnimatePresence>
                  {errors.busNumber && (
                    <motion.p
                      initial={{ opacity: 0, y: -2 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -2 }}
                      transition={{ type: "spring", stiffness: 500, damping: 30 }}
                      className="absolute left-1 bottom-0.5 text-[10px] font-bold text-rose-500"
                    >
                      {errors.busNumber}
                    </motion.p>
                  )}
                </AnimatePresence>
              </div>

              {/* Capacity Input Block */}
              <div className="relative pb-5">
                <label htmlFor="capacityInput" className="block text-sm font-semibold text-slate-700 dark:text-slate-350">
                  Capacity (Seats)
                </label>
                <div className="relative mt-1">
                  <input
                    id="capacityInput"
                    type="number"
                    required
                    placeholder="e.g. 40"
                    className={`block w-full border rounded-xl p-2.5 pr-10 text-sm bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus-ring transition-colors ${
                      errors.capacity 
                        ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5" 
                        : formData.capacity && !errors.capacity
                        ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5"
                        : "border-slate-300 dark:border-slate-700"
                    }`}
                    value={formData.capacity}
                    onChange={(e) => {
                      const val = e.target.value;
                      setFormData({ ...formData, capacity: val });
                      
                      // Live validation
                      const capacityVal = parseInt(val);
                      let err = "";
                      if (!val.trim()) {
                        err = "Capacity is required.";
                      } else if (isNaN(capacityVal) || capacityVal <= 0 || capacityVal > 120) {
                        err = "Must be between 1 and 120 seats.";
                      }
                      setErrors(prev => ({ ...prev, capacity: err }));
                    }}
                  />
                  <div className="absolute right-3.5 top-3 flex items-center pointer-events-none z-10">
                    {formData.capacity && !errors.capacity && (
                      <CheckCircleIcon className="w-5 h-5 text-emerald-500" />
                    )}
                    {errors.capacity && (
                      <ExclamationCircleIcon className="w-5 h-5 text-rose-500 animate-pulse" />
                    )}
                  </div>
                </div>
                <AnimatePresence>
                  {errors.capacity && (
                    <motion.p
                      initial={{ opacity: 0, y: -2 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -2 }}
                      transition={{ type: "spring", stiffness: 500, damping: 30 }}
                      className="absolute left-1 bottom-0.5 text-[10px] font-bold text-rose-500"
                    >
                      {errors.capacity}
                    </motion.p>
                  )}
                </AnimatePresence>
              </div>

              <div className="flex justify-end space-x-3 pt-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-4 py-2.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 focus-ring rounded-xl text-sm font-bold transition-all cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 bg-[#1E90FF] text-white focus-ring rounded-xl text-sm font-bold hover:bg-[#1C64F2] shadow-lg shadow-blue-500/20 active:scale-95 transition-all cursor-pointer"
                >
                  Add Bus
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

export default BusFormModal;
