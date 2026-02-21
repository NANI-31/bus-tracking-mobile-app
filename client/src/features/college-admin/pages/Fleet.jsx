import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  TruckIcon,
  PlusIcon,
  TrashIcon,
  PencilSquareIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
} from "@heroicons/react/24/outline";
import {
  getBuses,
  createBus,
  removeBus,
} from "@/features/college-admin/slices/collegeAdminSlice";
import ConfirmationModal from "@/components/common/ConfirmationModal";

import BusCard from "../components/Fleet/BusCard";
import BusFormModal from "../components/Fleet/BusFormModal";

const Fleet = () => {
  const dispatch = useDispatch();
  const { buses, loading } = useSelector((state) => state.collegeAdmin);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [deleteModal, setDeleteModal] = useState({
    isOpen: false,
    busId: null,
  });
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  useEffect(() => {
    dispatch(getBuses());
  }, [dispatch]);

  const handleAddBus = (busData) => {
    dispatch(createBus(busData));
  };

  const handleDeleteBus = (busId) => {
    setDeleteModal({ isOpen: true, busId });
  };

  const confirmDeleteBus = () => {
    if (deleteModal.busId) {
      dispatch(removeBus(deleteModal.busId));
    }
  };

  const filteredBuses = (Array.isArray(buses) ? buses : []).filter((bus) => {
    const matchesSearch = bus.busNumber
      .toLowerCase()
      .includes(searchQuery.toLowerCase());
    const matchesStatus =
      statusFilter === "all" ||
      (statusFilter === "active" && (bus.status === "active" || !bus.status)) ||
      bus.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <h1 className="text-2xl font-bold text-gray-800">Fleet Management</h1>
        <div className="flex flex-col sm:flex-row w-full sm:w-auto gap-3">
          <div className="relative flex-1 sm:w-64">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-gray-400" />
            <input
              type="text"
              placeholder="Search bus number..."
              className="w-full pl-10 pr-4 py-2 border rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <select
            className="px-4 py-2 border rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white cursor-pointer transition-all"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="on-time">On Time</option>
            <option value="delayed">Delayed</option>
            <option value="not-running">Not Running</option>
          </select>
          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center justify-center px-4 py-2 bg-[#1E90FF] text-white rounded-xl hover:bg-[#1E90FF] transition-all shadow-sm hover:shadow-md"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Add Bus
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence mode="popLayout">
          {filteredBuses.map((bus) => (
            <BusCard key={bus._id} bus={bus} onDelete={handleDeleteBus} />
          ))}
        </AnimatePresence>
      </div>

      {filteredBuses.length === 0 && !loading && (
        <div className="text-center py-20 bg-gray-50/50 rounded-3xl border-2 border-dashed border-gray-200">
          <TruckIcon className="w-16 h-16 mx-auto mb-4 text-gray-300" />
          <p className="text-lg text-gray-500 font-medium">
            {searchQuery
              ? `No buses found matching "${searchQuery}"`
              : "No buses in flight. Add your first bus!"}
          </p>
        </div>
      )}

      <BusFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleAddBus}
      />

      <ConfirmationModal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, busId: null })}
        onConfirm={confirmDeleteBus}
        title="Remove Bus"
        message="Are you sure you want to remove this bus from the fleet? This action cannot be undone."
        confirmText="Remove"
      />
    </div>
  );
};

export default Fleet;
