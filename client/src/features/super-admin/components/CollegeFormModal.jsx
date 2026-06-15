import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { XMarkIcon, CheckCircleIcon, ExclamationCircleIcon } from "@heroicons/react/24/outline";

const CollegeFormModal = ({ isOpen, onClose, onSubmit, loading }) => {
  const [formData, setFormData] = useState({
    name: "",
    allowedDomains: "",
  });

  const [errors, setErrors] = useState({
    name: "",
    allowedDomains: "",
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });

    let err = "";
    if (name === "name") {
      if (!value.trim()) {
        err = "College name is required.";
      } else if (value.trim().length < 3) {
        err = "College name must be at least 3 characters.";
      }
    } else if (name === "allowedDomains") {
      const domains = value
        .split(",")
        .map((d) => d.trim())
        .filter((d) => d !== "");
      if (domains.length === 0) {
        err = "At least one allowed domain is required.";
      } else {
        const domainRegex = /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/i;
        const invalidDomains = domains.filter((d) => !domainRegex.test(d));
        if (invalidDomains.length > 0) {
          err = `Invalid domain formats: ${invalidDomains.join(", ")}`;
        }
      }
    }

    setErrors((prev) => ({ ...prev, [name]: err }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    let hasError = false;
    const newErrors = { name: "", allowedDomains: "" };

    if (!formData.name.trim()) {
      newErrors.name = "College name is required.";
      hasError = true;
    } else if (formData.name.trim().length < 3) {
      newErrors.name = "College name must be at least 3 characters.";
      hasError = true;
    }

    const domains = formData.allowedDomains
      .split(",")
      .map((d) => d.trim())
      .filter((d) => d !== "");

    if (domains.length === 0) {
      newErrors.allowedDomains = "At least one allowed domain is required.";
      hasError = true;
    } else {
      const domainRegex = /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/i;
      const invalidDomains = domains.filter((d) => !domainRegex.test(d));
      if (invalidDomains.length > 0) {
        newErrors.allowedDomains = `Invalid domain formats: ${invalidDomains.join(", ")}`;
        hasError = true;
      }
    }

    setErrors(newErrors);
    if (hasError) return;

    onSubmit({
      name: formData.name.trim(),
      allowedDomains: domains,
    });
    setFormData({ name: "", allowedDomains: "" });
    setErrors({ name: "", allowedDomains: "" });
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
            className="relative bg-white/80 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-white/30 dark:border-slate-800 shadow-2xl w-full max-w-md overflow-hidden z-10 text-text-theme-primary"
          >
            <div className="flex justify-between items-center p-6 border-b border-slate-100 dark:border-slate-800">
              <h2 className="text-lg font-black tracking-tight text-text-theme-primary">
                Create New College
              </h2>
              <button
                onClick={onClose}
                className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors cursor-pointer"
              >
                <XMarkIcon className="w-5 h-5 text-text-theme-secondary" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-5">
              <div>
                <label htmlFor="collegeNameInput" className="block text-xs font-bold uppercase tracking-wider text-text-theme-secondary mb-1.5">
                  College Name
                </label>
                <div className="relative">
                  <input
                    id="collegeNameInput"
                    required
                    type="text"
                    name="name"
                    placeholder="e.g. Stanford University"
                    className={`w-full px-4 py-2.5 pr-10 border rounded-xl bg-white dark:bg-slate-950 focus-ring transition-all text-sm text-text-theme-primary ${
                      errors.name
                        ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5 dark:bg-rose-500/10"
                        : formData.name && !errors.name
                        ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5 dark:bg-emerald-500/10"
                        : "border-slate-300 dark:border-slate-800"
                    }`}
                    value={formData.name}
                    onChange={handleChange}
                  />
                  <div className="absolute right-3.5 top-3 flex items-center pointer-events-none z-10">
                    {formData.name && !errors.name && (
                      <CheckCircleIcon className="w-5 h-5 text-emerald-500" />
                    )}
                    {errors.name && (
                      <ExclamationCircleIcon className="w-5 h-5 text-rose-500 animate-pulse" />
                    )}
                  </div>
                </div>
                <AnimatePresence>
                  {errors.name && (
                    <motion.p
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ type: "spring", stiffness: 500, damping: 30 }}
                      className="text-xs font-semibold text-rose-500 mt-1.5 overflow-hidden"
                    >
                      {errors.name}
                    </motion.p>
                  )}
                </AnimatePresence>
              </div>

              <div>
                <label htmlFor="collegeDomainsInput" className="block text-xs font-bold uppercase tracking-wider text-text-theme-secondary mb-1.5">
                  Allowed Domains (Comma separated)
                </label>
                <div className="relative">
                  <input
                    id="collegeDomainsInput"
                    type="text"
                    name="allowedDomains"
                    placeholder="stanford.edu, stanford.ac.in"
                    className={`w-full px-4 py-2.5 pr-10 border rounded-xl bg-white dark:bg-slate-950 focus-ring transition-all text-sm text-text-theme-primary ${
                      errors.allowedDomains
                        ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5 dark:bg-rose-500/10"
                        : formData.allowedDomains && !errors.allowedDomains
                        ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5 dark:bg-emerald-500/10"
                        : "border-slate-300 dark:border-slate-800"
                    }`}
                    value={formData.allowedDomains}
                    onChange={handleChange}
                  />
                  <div className="absolute right-3.5 top-3 flex items-center pointer-events-none z-10">
                    {formData.allowedDomains && !errors.allowedDomains && (
                      <CheckCircleIcon className="w-5 h-5 text-emerald-500" />
                    )}
                    {errors.allowedDomains && (
                      <ExclamationCircleIcon className="w-5 h-5 text-rose-500 animate-pulse" />
                    )}
                  </div>
                </div>
                <AnimatePresence>
                  {errors.allowedDomains && (
                    <motion.p
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ type: "spring", stiffness: 500, damping: 30 }}
                      className="text-xs font-semibold text-rose-500 mt-1.5 overflow-hidden"
                    >
                      {errors.allowedDomains}
                    </motion.p>
                  )}
                </AnimatePresence>
                <p className="mt-1.5 text-xs text-text-theme-secondary/70 font-medium">
                  Domains used for student/staff registration.
                </p>
              </div>

              <div className="pt-4 flex gap-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="flex-1 px-4 py-2.5 border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-300 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors font-semibold text-sm focus-ring cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 px-4 py-2.5 bg-[#1E90FF] text-white rounded-xl hover:bg-[#1E90FF]/90 hover:shadow-lg transition-all font-bold text-sm disabled:opacity-50 focus-ring cursor-pointer shadow-md shadow-blue-500/15"
                >
                  {loading ? "Creating..." : "Create College"}
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

export default CollegeFormModal;
