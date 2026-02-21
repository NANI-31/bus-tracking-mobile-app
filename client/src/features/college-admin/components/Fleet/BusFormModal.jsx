import React, { useState } from "react";
import { motion } from "framer-motion";

const BusFormModal = ({ isOpen, onClose, onSubmit }) => {
  const [formData, setFormData] = useState({
    busNumber: "",
    capacity: "",
    driverId: "", // Ideally a select dropdown from available drivers
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
    setFormData({ busNumber: "", capacity: "", driverId: "" });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.9 }}
        className="bg-white rounded-xl shadow-lg p-6 w-full max-w-md"
      >
        <h2 className="text-xl font-bold mb-4">Add New Bus</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Bus Number
            </label>
            <input
              type="text"
              required
              className="mt-1 block w-full border rounded-md p-2"
              value={formData.busNumber}
              onChange={(e) =>
                setFormData({ ...formData, busNumber: e.target.value })
              }
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Capacity
            </label>
            <input
              type="number"
              required
              className="mt-1 block w-full border rounded-md p-2"
              value={formData.capacity}
              onChange={(e) =>
                setFormData({ ...formData, capacity: e.target.value })
              }
            />
          </div>
          {/* Driver Selection would go here */}

          <div className="flex justify-end space-x-3 mt-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-[#1E90FF] text-white rounded-lg hover:bg-[#1E90FF]"
            >
              Add Bus
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

export default BusFormModal;
