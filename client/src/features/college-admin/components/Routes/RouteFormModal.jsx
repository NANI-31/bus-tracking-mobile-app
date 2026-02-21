import React, { useState } from "react";
import { motion } from "framer-motion";
import { PlusIcon, TrashIcon, XCircleIcon } from "@heroicons/react/24/outline";

const RouteFormModal = ({ isOpen, onClose, onSubmit }) => {
  const [formData, setFormData] = useState({
    name: "",
    stops: [{ name: "", lat: "", lng: "" }], // Initial stop
  });

  if (!isOpen) return null;

  const handleAddStop = () => {
    setFormData({
      ...formData,
      stops: [...formData.stops, { name: "", lat: "", lng: "" }],
    });
  };

  const handleStopChange = (index, field, value) => {
    const newStops = [...formData.stops];
    newStops[index][field] = value;
    setFormData({ ...formData, stops: newStops });
  };

  const handleRemoveStop = (index) => {
    const newStops = formData.stops.filter((_, i) => i !== index);
    setFormData({ ...formData, stops: newStops });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
    setFormData({ name: "", stops: [{ name: "", lat: "", lng: "" }] });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 overflow-y-auto">
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.9 }}
        className="bg-white rounded-xl shadow-lg p-6 w-full max-w-lg my-8"
      >
        <h2 className="text-xl font-bold mb-4">Add New Route</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Route Name
            </label>
            <input
              type="text"
              required
              className="mt-1 block w-full border rounded-md p-2"
              placeholder="e.g., Route A - Main Campus"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Stops
            </label>
            {formData.stops.map((stop, index) => (
              <div key={index} className="flex space-x-2 mb-2 items-start">
                <div className="flex-1 space-y-2">
                  <input
                    type="text"
                    required
                    placeholder="Stop Name"
                    className="block w-full border rounded-md p-2 text-sm"
                    value={stop.name}
                    onChange={(e) =>
                      handleStopChange(index, "name", e.target.value)
                    }
                  />
                  <div className="flex space-x-2">
                    <input
                      type="number"
                      step="any"
                      placeholder="Lat"
                      className="block w-1/2 border rounded-md p-2 text-xs"
                      value={stop.lat}
                      onChange={(e) =>
                        handleStopChange(index, "lat", e.target.value)
                      }
                    />
                    <input
                      type="number"
                      step="any"
                      placeholder="Lng"
                      className="block w-1/2 border rounded-md p-2 text-xs"
                      value={stop.lng}
                      onChange={(e) =>
                        handleStopChange(index, "lng", e.target.value)
                      }
                    />
                  </div>
                </div>
                {formData.stops.length > 1 && (
                  <button
                    type="button"
                    onClick={() => handleRemoveStop(index)}
                    className="text-red-500 hover:text-red-700 mt-2"
                  >
                    <TrashIcon className="w-5 h-5" />
                  </button>
                )}
              </div>
            ))}
            <button
              type="button"
              onClick={handleAddStop}
              className="text-sm text-[#1E90FF] hover:text-[#1C64F2] font-bold flex items-center mt-2"
            >
              <PlusIcon className="w-4 h-4 mr-1 stroke-2" /> Add Stop
            </button>
          </div>

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
              className="px-6 py-2.5 bg-[#1E90FF] text-white rounded-xl font-bold hover:bg-[#1C64F2] shadow-lg shadow-blue-500/20 active:scale-95 transition-all"
            >
              Create Route
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

export default RouteFormModal;
