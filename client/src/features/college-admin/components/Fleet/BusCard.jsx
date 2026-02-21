import React from "react";
import { motion } from "framer-motion";
import { TruckIcon, TrashIcon } from "@heroicons/react/24/outline";

const BusCard = ({ bus, onDelete }) => {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      layout
      className="bg-white rounded-2xl shadow-sm p-6 border border-gray-100 hover:shadow-md transition-all group"
    >
      <div className="flex justify-between items-start mb-4">
        <div className="p-3 bg-indigo-50 rounded-lg">
          <TruckIcon className="w-8 h-8 text-[#1E90FF]" />
        </div>
        <div className="flex space-x-2">
          <button
            onClick={() => onDelete(bus._id)}
            className="text-red-400 hover:text-red-600"
          >
            <TrashIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      <h3 className="text-lg font-bold text-gray-800">Bus {bus.busNumber}</h3>
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
  );
};

export default BusCard;
