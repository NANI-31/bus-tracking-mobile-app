import React, { useState } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";

const CollegeFormModal = ({ isOpen, onClose, onSubmit, loading }) => {
  const [formData, setFormData] = useState({
    name: "",
    allowedDomains: "",
  });

  if (!isOpen) return null;

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const processedData = {
      ...formData,
      allowedDomains: formData.allowedDomains
        .split(",")
        .map((d) => d.trim())
        .filter((d) => d !== ""),
    };
    onSubmit(processedData);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in duration-200">
        <div className="flex justify-between items-center p-6 border-b border-slate-100">
          <h2 className="text-xl font-bold text-slate-800">
            Create New College
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-full transition-colors"
          >
            <XMarkIcon className="w-6 h-6 text-slate-500" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              College Name
            </label>
            <input
              required
              type="text"
              name="name"
              placeholder="e.g. Stanford University"
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-[#1E90FF] focus:border-transparent outline-none transition-all"
              value={formData.name}
              onChange={handleChange}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Allowed Domains (Comma separated)
            </label>
            <input
              type="text"
              name="allowedDomains"
              placeholder="stanford.edu, stanford.ac.in"
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-[#1E90FF] focus:border-transparent outline-none transition-all"
              value={formData.allowedDomains}
              onChange={handleChange}
            />
            <p className="mt-1 text-xs text-slate-500">
              Domains used for student/staff registration.
            </p>
          </div>

          <div className="pt-4 flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 px-4 py-2 bg-[#1E90FF] text-white rounded-lg hover:bg-[#1E90FF]/90 transition-colors font-medium disabled:opacity-50"
            >
              {loading ? "Creating..." : "Create College"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CollegeFormModal;
