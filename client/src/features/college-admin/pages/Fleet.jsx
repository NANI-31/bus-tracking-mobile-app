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
  ChevronDownIcon,
  XMarkIcon,
  ChartBarIcon,
  CheckCircleIcon,
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

  // Stats Computations
  const totalBuses = buses?.length || 0;
  const activeBuses = buses?.filter(b => b.status === "active" || b.status === "on-time" || !b.status).length || 0;
  const totalCapacity = buses?.reduce((acc, b) => acc + (parseInt(b.capacity) || 0), 0) || 0;

  return (
    <div className="space-y-6 min-h-screen bg-background-default -m-6 p-6">
      {/* Title Header Block */}
      <motion.div 
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 100, damping: 15 }}
        className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 bg-background-paper p-6 rounded-3xl border border-border-theme/40 shadow-sm transition-colors duration-300"
      >
        <div>
          <h1 className="text-xl sm:text-2xl font-black text-text-theme-primary tracking-tight">
            Control Center: Fleet
          </h1>
          <p className="text-text-theme-secondary text-sm font-semibold">
            Monitor, deploy, and maintain transit buses and fleet capacity
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-center gap-3 w-full lg:w-auto">
          {/* Search Bar */}
          <div className="relative w-full sm:w-64 group">
            <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <MagnifyingGlassIcon className="w-5 h-5 text-text-theme-secondary group-focus-within:text-primary-main transition-colors" />
            </div>
            <input
              type="text"
              placeholder="Search bus number..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="block w-full pl-11 pr-10 py-2.5 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary placeholder:text-text-theme-secondary placeholder:font-semibold focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 outline-none transition-all duration-200"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-text-theme-secondary hover:text-text-theme-primary transition-colors"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            )}
          </div>

          {/* Status Dropdown */}
          <div className="relative w-full sm:w-48">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="block w-full pl-4 pr-10 py-2.5 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 outline-none transition-all duration-200 cursor-pointer appearance-none"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="on-time">On Time</option>
              <option value="delayed">Delayed</option>
              <option value="not-running">Not Running</option>
            </select>
            <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-text-theme-secondary">
              <ChevronDownIcon className="w-4 h-4" />
            </div>
          </div>

          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center justify-center space-x-2 px-6 py-2.5 bg-primary-main hover:bg-primary-dark text-white rounded-2xl font-bold shadow-lg shadow-primary-main/20 active:scale-[0.98] transition-all cursor-pointer w-full sm:w-auto shrink-0"
          >
            <PlusIcon className="w-5 h-5" />
            <span>Add Bus</span>
          </button>
        </div>
      </motion.div>

      {/* Analytics Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        {[
          {
            title: "Total Fleet Vehicles",
            value: totalBuses,
            icon: TruckIcon,
            color: "from-primary-main/15 to-primary-light/5 text-primary-main border-primary-main/15",
            hoverColor: "hover:shadow-primary-main/5 hover:border-primary-main/30",
            delay: 0,
          },
          {
            title: "Vehicles In-Service",
            value: activeBuses,
            icon: CheckCircleIcon,
            color: "from-emerald-500/15 to-emerald-400/5 text-emerald-500 border-emerald-500/15",
            hoverColor: "hover:shadow-emerald-500/5 hover:border-emerald-500/30",
            delay: 0.08,
          },
          {
            title: "Total Fleet Capacity",
            value: `${totalCapacity} Seats`,
            icon: ChartBarIcon,
            color: "from-violet-500/15 to-violet-400/5 text-violet-500 border-violet-500/15",
            hoverColor: "hover:shadow-violet-500/5 hover:border-violet-500/30",
            delay: 0.16,
          },
        ].map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ type: "spring", stiffness: 100, damping: 15, delay: stat.delay }}
              whileHover={{ 
                y: -6, 
                scale: 1.025, 
                transition: { type: "spring", stiffness: 450, damping: 16 } 
              }}
              className={`bg-background-paper border border-border-theme/40 rounded-3xl p-5 shadow-sm hover:shadow-xl transition-all duration-350 flex items-center gap-4 cursor-pointer group ${stat.hoverColor}`}
            >
              <div className={`p-3.5 rounded-2xl bg-linear-to-tr border transition-transform duration-350 group-hover:scale-110 ${stat.color}`}>
                <Icon className="w-6 h-6 shrink-0" />
              </div>
              <div>
                <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-0.5">{stat.title}</p>
                <p className="text-2xl font-black text-text-theme-primary leading-none">{stat.value}</p>
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Main Grid Section */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
        <AnimatePresence mode="popLayout">
          {loading ? (
            Array.from({ length: 6 }).map((_, idx) => (
              <div
                key={`skeleton-${idx}`}
                className="bg-background-paper border border-border-theme/40 rounded-3xl p-6 shadow-xs flex flex-col space-y-5 relative overflow-hidden"
              >
                <div className="flex justify-between items-start">
                  <div className="w-[52px] h-[52px] rounded-[16px] shimmer shrink-0" />
                  <div className="w-10 h-10 rounded-xl shimmer shrink-0" />
                </div>
                <div className="space-y-2">
                  <div className="h-5 rounded-lg w-1/2 shimmer" />
                  <div className="h-3.5 rounded-lg w-1/3 shimmer" />
                </div>
                <div className="border-t border-border-theme/40 pt-4 space-y-3">
                  <div className="space-y-1.5">
                    <div className="flex justify-between">
                      <div className="h-3.5 rounded-md w-1/4 shimmer" />
                      <div className="h-3.5 rounded-md w-1/5 shimmer" />
                    </div>
                    <div className="w-full h-2 rounded-full shimmer" />
                  </div>
                  <div className="flex justify-between items-center">
                    <div className="h-3.5 rounded-md w-1/3 shimmer" />
                    <div className="h-5 rounded-md w-1/5 shimmer" />
                  </div>
                </div>
              </div>
            ))
          ) : (
            filteredBuses.map((bus) => (
              <BusCard key={bus._id} bus={bus} onDelete={handleDeleteBus} />
            ))
          )}
        </AnimatePresence>
      </div>

      {/* Empty State */}
      {filteredBuses.length === 0 && !loading && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-background-paper rounded-3xl border border-dashed border-border-theme py-16 text-center shadow-inner"
        >
          <div className="bg-background-default w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 border border-border-theme shadow-sm">
            <TruckIcon className="w-8 h-8 text-text-theme-secondary" />
          </div>
          <h3 className="text-lg font-black text-text-theme-primary mb-1">
            {searchQuery ? "No matches found" : "No buses yet"}
          </h3>
          <p className="text-text-theme-secondary text-sm font-semibold max-w-sm mx-auto">
            {searchQuery
              ? `We couldn't find any fleet vehicles matching "${searchQuery}"`
              : "Get started by adding your first operational bus."}
          </p>
          {searchQuery && (
            <button
              onClick={() => setSearchQuery("")}
              className="mt-4 text-primary-main font-bold text-sm hover:underline cursor-pointer"
            >
              Clear Search
            </button>
          )}
        </motion.div>
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
