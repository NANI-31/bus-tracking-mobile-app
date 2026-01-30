import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  TruckIcon,
  PlusIcon,
  TrashIcon,
  PencilSquareIcon,
} from "@heroicons/react/24/outline";
import { getBuses, createBus, removeBus } from "../slices/collegeAdminSlice";

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
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Add Bus
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

const Fleet = () => {
  const dispatch = useDispatch();
  const { buses, loading } = useSelector((state) => state.collegeAdmin);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    dispatch(getBuses());
  }, [dispatch]);

  const handleAddBus = (busData) => {
    dispatch(createBus(busData));
  };

  const handleDeleteBus = (busId) => {
    if (window.confirm("Are you sure you want to remove this bus?")) {
      dispatch(removeBus(busId));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Fleet Management</h1>
        <button
          onClick={() => setIsModalOpen(true)}
          className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <PlusIcon className="w-5 h-5 mr-2" />
          Add Bus
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence>
          {buses.map((bus) => (
            <motion.div
              key={bus._id}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              layout
              className="bg-white rounded-xl shadow-sm p-6 border border-gray-100 hover:shadow-md transition-shadow"
            >
              <div className="flex justify-between items-start mb-4">
                <div className="p-3 bg-indigo-50 rounded-lg">
                  <TruckIcon className="w-8 h-8 text-indigo-600" />
                </div>
                <div className="flex space-x-2">
                  {/* Edit button placeholder */}
                  <button
                    onClick={() => handleDeleteBus(bus._id)}
                    className="text-red-400 hover:text-red-600"
                  >
                    <TrashIcon className="w-5 h-5" />
                  </button>
                </div>
              </div>

              <h3 className="text-lg font-bold text-gray-800">
                Bus {bus.busNumber}
              </h3>
              <div className="mt-4 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Capacity</span>
                  <span className="font-medium">{bus.capacity} Seats</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Status</span>
                  <span
                    className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                      bus.status === "active"
                        ? "bg-green-100 text-green-800"
                        : "bg-gray-100 text-gray-800"
                    }`}
                  >
                    {bus.status || "Active"}
                  </span>
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {buses.length === 0 && !loading && (
        <div className="text-center py-12 text-gray-500">
          <TruckIcon className="w-16 h-16 mx-auto mb-4 text-gray-300" />
          <p className="text-lg">No buses in flight. Add your first bus!</p>
        </div>
      )}

      <BusFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleAddBus}
      />
    </div>
  );
};

export default Fleet;
