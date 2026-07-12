import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import { toast } from "react-hot-toast";
import {
  TruckIcon,
  UserIcon,
  MapPinIcon,
  ArrowPathIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  MagnifyingGlassIcon,
  XMarkIcon,
  ChevronDownIcon,
  SparklesIcon,
} from "@heroicons/react/24/outline";
import {
  getBuses,
  getRoutes,
  getUsers,
  modifyBus,
} from "@/features/college-admin/slices/collegeAdminSlice";
import ConfirmationModal from "@/components/common/ConfirmationModal";
import axios from "@/api/axios";
import { getSocket } from "@/services/socket";

const CoordinatorDashboard = () => {
  const dispatch = useDispatch();
  const { buses, routes, users, loading } = useSelector(
    (state) => state.collegeAdmin
  );
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedBus, setSelectedBus] = useState(null);
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [isRevokeModalOpen, setIsRevokeModalOpen] = useState(false);
  // Assignment form states
  const [selectedDriverId, setSelectedDriverId] = useState("");
  const [selectedRouteId, setSelectedRouteId] = useState("");

  // Override requests states
  const [activeTab, setActiveTab] = useState("assignments");
  const [overrideRequests, setOverrideRequests] = useState([]);
  const [loadingOverrides, setLoadingOverrides] = useState(false);

  const fetchOverrideRequests = async () => {
    setLoadingOverrides(true);
    try {
      const res = await axios.get("/buses/teacher-override/requests");
      setOverrideRequests(res.data);
    } catch (err) {
      console.error("Error fetching override requests:", err);
    } finally {
      setLoadingOverrides(false);
    }
  };

  useEffect(() => {
    dispatch(getBuses());
    dispatch(getRoutes());
    dispatch(getUsers({ role: "driver", limit: 1000 }));
    fetchOverrideRequests();

    const socket = getSocket();
    if (socket) {
      const handleBusListUpdated = () => {
        dispatch(getBuses());
        fetchOverrideRequests();
      };
      socket.on("bus_list_updated", handleBusListUpdated);
      return () => {
        socket.off("bus_list_updated", handleBusListUpdated);
      };
    }
  }, [dispatch]);

  const handleRefresh = () => {
    dispatch(getBuses());
    dispatch(getRoutes());
    dispatch(getUsers({ role: "driver", limit: 1000 }));
    fetchOverrideRequests();
    toast.success("Dashboard data refreshed");
  };

  const handleResolveOverride = async (requestId, status) => {
    try {
      await axios.put(`/buses/teacher-override/request/${requestId}`, { status });
      toast.success(`Override request ${status === "approved" ? "approved" : "rejected"} successfully`);
      fetchOverrideRequests();
      dispatch(getBuses());
    } catch (err) {
      toast.error(err?.response?.data?.message || err.message || "Failed to resolve override request");
    }
  };

  const openAssignModal = (bus) => {
    setSelectedBus(bus);
    setSelectedDriverId(bus.driverId || "");
    setSelectedRouteId(bus.routeId || "");
    setIsAssignModalOpen(true);
  };

  const handleAssignSubmit = (e) => {
    e.preventDefault();
    if (!selectedBus) return;
    if (!selectedDriverId || !selectedRouteId) {
      toast.error("Please select both a driver and a route");
      return;
    }
    dispatch(
      modifyBus({
        busId: selectedBus._id,
        busData: {
          driverId: selectedDriverId,
          routeId: selectedRouteId,
          assignmentStatus: "pending",
        },
      })
    )
      .unwrap()
      .then(() => {
        toast.success(`Assignment set to pending driver acceptance for Bus ${selectedBus.busNumber}`);
        setIsAssignModalOpen(false);
        setSelectedBus(null);
      })
      .catch((err) => {
        toast.error(err?.message || "Failed to update assignment");
      });
  };

  const openRevokeModal = (bus) => {
    setSelectedBus(bus);
    setIsRevokeModalOpen(true);
  };

  const handleRevokeConfirm = () => {
    if (!selectedBus) return;
    dispatch(
      modifyBus({
        busId: selectedBus._id,
        busData: {
          driverId: "",
          routeId: "",
          assignmentStatus: "unassigned",
          status: "not-running",
        },
      })
    )
      .unwrap()
      .then(() => {
        toast.success(`Assignment revoked for Bus ${selectedBus.busNumber}`);
        setIsRevokeModalOpen(false);
        setSelectedBus(null);
      })
      .catch((err) => {
        toast.error(err?.message || "Failed to revoke assignment");
      });
  };

  // Drivers in college
  const driversList = (Array.isArray(users) ? users : []).filter(
    (u) => u.role === "driver" && u.approved
  );

  // Helper to find driver name
  const getDriverName = (driverId) => {
    const d = driversList.find((u) => u._id === driverId);
    return d ? d.fullName : "N/A";
  };

  // Helper to find route details
  const getRouteDetails = (routeId) => {
    const r = (Array.isArray(routes) ? routes : []).find((route) => route._id === routeId);
    return r ? `${r.routeName} (${r.startPoint?.name || "Start"} ➔ ${r.endPoint?.name || "End"})` : "N/A";
  };

  // Check if a driver is already assigned to a different bus
  const getDriverCurrentAssignment = (driverId, currentBusId) => {
    const assignedBus = (Array.isArray(buses) ? buses : []).find(
      (b) => b.driverId === driverId && b._id !== currentBusId
    );
    return assignedBus ? `Assigned to Bus ${assignedBus.busNumber}` : null;
  };

  // Filtered bus list
  const filteredBuses = (Array.isArray(buses) ? buses : []).filter((bus) => {
    const matchesSearch = bus.busNumber
      .toLowerCase()
      .includes(searchQuery.toLowerCase());
    
    const matchesStatus =
      statusFilter === "all" ||
      (statusFilter === "unassigned" && (!bus.assignmentStatus || bus.assignmentStatus === "unassigned")) ||
      bus.assignmentStatus === statusFilter;
    return matchesSearch && matchesStatus;
  });

  // Calculate statistics
  const totalBusesCount = buses?.length || 0;
  const unassignedCount = buses?.filter((b) => !b.assignmentStatus || b.assignmentStatus === "unassigned").length || 0;
  const pendingCount = buses?.filter((b) => b.assignmentStatus === "pending").length || 0;
  const acceptedCount = buses?.filter((b) => b.assignmentStatus === "accepted").length || 0;

  // Helper helper to build confirm detail rows
  const _buildConfirmDetailRow = (context, label, value, icon) => {
    const Icon = icon;
    return (
      <div className="flex items-center gap-3">
        <div className="p-2.5 bg-slate-100 dark:bg-slate-800 rounded-xl text-slate-500 dark:text-slate-400">
          <Icon className="w-5 h-5" />
        </div>
        <div>
          <p className="text-[10px] font-black uppercase tracking-wider text-text-theme-secondary">{label}</p>
          <p className="text-sm font-bold text-text-theme-primary mt-0.5">{value}</p>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6 min-h-screen bg-background-default -m-6 p-6">
      {/* Title Header Card */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 100, damping: 15 }}
        className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 bg-background-paper p-6 rounded-3xl border border-border-theme/40 shadow-xs"
      >
        <div>
          <h1 className="text-xl sm:text-2xl font-black text-text-theme-primary tracking-tight flex items-center gap-2">
            <SparklesIcon className="w-6 h-6 text-primary-main animate-pulse" />
            Coordinator Hub: Driver Assignments
          </h1>
          <p className="text-text-theme-secondary text-sm font-semibold mt-1">
            Dispatch drivers, allocate routes, and govern college fleet dispatch lifecycles
          </p>
        </div>
        <div className="flex flex-col sm:flex-row items-center gap-3 w-full lg:w-auto">
          {activeTab === "assignments" && (
            <>
              {/* Search */}
              <div className="relative w-full sm:w-64 group">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <MagnifyingGlassIcon className="w-5 h-5 text-text-theme-secondary group-focus-within:text-primary-main transition-colors" />
                </div>
                <input
                  type="text"
                  placeholder="Search bus number..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="block w-full pl-11 pr-10 py-2.5 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary placeholder:text-text-theme-secondary focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 outline-none transition-all duration-200"
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
                  <option value="all">All Assignments</option>
                  <option value="unassigned">Unassigned Only</option>
                  <option value="pending">Pending Drivers</option>
                  <option value="accepted">Accepted / Active</option>
                </select>
                <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-text-theme-secondary">
                  <ChevronDownIcon className="w-4 h-4" />
                </div>
              </div>
            </>
          )}
          {/* Refresh Button */}
          <button
            onClick={handleRefresh}
            className="flex items-center justify-center p-3.5 bg-background-paper border border-border-theme text-text-theme-primary hover:text-primary-main rounded-2xl font-bold shadow-xs active:scale-95 transition-all cursor-pointer w-full sm:w-auto shrink-0"
            title="Refresh Fleet Status"
          >
            <ArrowPathIcon className={`w-4.5 h-4.5 ${loading ? "animate-spin" : ""}`} />
          </button>
        </div>
      </motion.div>

      {/* Tab Switcher */}
      <div className="flex border-b border-border-theme/45 gap-6">
        <button
          onClick={() => setActiveTab("assignments")}
          className={`pb-3 text-sm font-bold border-b-2 transition-all cursor-pointer ${
            activeTab === "assignments"
              ? "border-primary-main text-primary-main"
              : "border-transparent text-text-theme-secondary hover:text-text-theme-primary"
          }`}
        >
          Driver Assignments
        </button>
        <button
          onClick={() => setActiveTab("overrides")}
          className={`pb-3 text-sm font-bold border-b-2 transition-all cursor-pointer relative ${
            activeTab === "overrides"
              ? "border-primary-main text-primary-main"
              : "border-transparent text-text-theme-secondary hover:text-text-theme-primary"
          }`}
        >
          Teacher Override Requests
          {overrideRequests.length > 0 && (
            <span className="absolute -top-1.5 -right-3.5 bg-rose-500 text-white text-[10px] font-black w-4.5 h-4.5 rounded-full flex items-center justify-center animate-bounce">
              {overrideRequests.length}
            </span>
          )}
        </button>
      </div>

      {activeTab === "assignments" && (
        <>
          {/* Analytics Stats Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              {
                title: "Total Fleet Buses",
                value: totalBusesCount,
                icon: TruckIcon,
                color: "from-primary-main/15 to-primary-light/5 text-primary-main border-primary-main/15",
                hoverColor: "hover:border-primary-main/30",
                delay: 0,
              },
              {
                title: "Unassigned Vehicles",
                value: unassignedCount,
                icon: ExclamationTriangleIcon,
                color: "from-rose-500/15 to-rose-400/5 text-rose-500 border-rose-500/15",
                hoverColor: "hover:border-rose-500/30",
                delay: 0.05,
              },
              {
                title: "Pending Driver Acceptance",
                value: pendingCount,
                icon: ArrowPathIcon,
                color: "from-amber-500/15 to-amber-400/5 text-amber-500 border-amber-500/15",
                hoverColor: "hover:border-amber-500/30",
                delay: 0.1,
              },
              {
                title: "Accepted & Active",
                value: acceptedCount,
                icon: CheckCircleIcon,
                color: "from-emerald-500/15 to-emerald-400/5 text-emerald-500 border-emerald-500/15",
                hoverColor: "hover:border-emerald-500/30",
                delay: 0.15,
              },
            ].map((stat, idx) => {
              const Icon = stat.icon;
              return (
                <motion.div
                  key={idx}
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ type: "spring", stiffness: 100, damping: 15, delay: stat.delay }}
                  whileHover={{ y: -4, scale: 1.015 }}
                  className={`bg-background-paper border border-border-theme/40 rounded-3xl p-5 shadow-xs hover:shadow-md transition-all duration-300 flex items-center gap-4 cursor-pointer group ${stat.hoverColor}`}
                >
                  <div className={`p-3 rounded-2xl bg-linear-to-tr border transition-transform duration-300 group-hover:scale-105 ${stat.color}`}>
                    <Icon className="w-5 h-5 shrink-0" />
                  </div>
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-0.5">{stat.title}</p>
                    <p className="text-xl font-black text-text-theme-primary leading-none">{stat.value}</p>
                  </div>
                </motion.div>
              );
            })}
          </div>

          {/* Main Buses List */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <AnimatePresence mode="popLayout">
              {loading && (!buses || buses.length === 0) ? (
                Array.from({ length: 6 }).map((_, idx) => (
                  <div
                    key={`skeleton-${idx}`}
                    className="bg-background-paper border border-border-theme/40 rounded-3xl p-6 shadow-xs flex flex-col space-y-4 relative overflow-hidden"
                  >
                    <div className="w-[48px] h-[48px] rounded-2xl shimmer" />
                    <div className="h-5 rounded-lg w-1/2 shimmer" />
                    <div className="h-3 rounded-lg w-1/3 shimmer" />
                    <div className="border-t border-border-theme/45 pt-4 space-y-2">
                      <div className="h-3 rounded-lg w-full shimmer" />
                      <div className="h-3 rounded-lg w-2/3 shimmer" />
                    </div>
                  </div>
                ))
              ) : (
                filteredBuses.map((bus) => {
                  const hasDriver = !!bus.driverId;
                  const hasRoute = !!bus.routeId;
                  const assignmentStatus = bus.assignmentStatus || "unassigned";
                  let badgeStyle = "bg-slate-100 text-slate-600 dark:bg-slate-900/60 dark:text-slate-400 border-slate-200 dark:border-slate-800";
                  let statusLabel = "Unassigned";
                  if (assignmentStatus === "pending") {
                    badgeStyle = "bg-amber-500/10 text-amber-500 border-amber-500/20";
                    statusLabel = "Pending Driver Acceptance";
                  } else if (assignmentStatus === "accepted") {
                    badgeStyle = "bg-emerald-500/10 text-emerald-500 border-emerald-500/20";
                    statusLabel = "Accepted & Running";
                  }
                  return (
                    <motion.div
                      key={bus._id}
                      layout
                      initial={{ opacity: 0, scale: 0.95 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      whileHover={{ y: -4 }}
                      className="bg-background-paper rounded-3xl p-6 border border-border-theme/40 shadow-xs flex flex-col justify-between hover:shadow-md transition-all duration-300 relative overflow-hidden"
                    >
                      <div>
                        {/* Header */}
                        <div className="flex justify-between items-start mb-4">
                          <div className="p-3 bg-linear-to-tr from-slate-100 to-slate-50 dark:from-slate-800 dark:to-slate-850 rounded-2xl border border-border-theme">
                            <TruckIcon className="w-6 h-6 text-primary-main" />
                          </div>
                          <span className={`px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider border ${badgeStyle}`}>
                            {statusLabel}
                          </span>
                        </div>
                        {/* Bus ID/Number */}
                        <div>
                          <h3 className="text-lg font-black text-text-theme-primary tracking-tight">
                            Bus {bus.busNumber}
                          </h3>
                          <p className="text-[10px] font-semibold text-text-theme-secondary uppercase tracking-widest mt-0.5">
                            Capacity: {bus.capacity} Seats
                          </p>
                        </div>
                        {/* Driver & Route Assignments */}
                        <div className="mt-5 pt-4 border-t border-border-theme/40 space-y-3">
                          {/* Driver */}
                          <div className="flex items-start gap-2.5">
                            <UserIcon className="w-4 h-4 text-text-theme-secondary mt-0.5 shrink-0" />
                            <div className="text-xs">
                              <p className="font-semibold text-text-theme-secondary text-[10px] uppercase tracking-wider">Assigned Driver</p>
                              <p className={`font-bold mt-0.5 ${hasDriver ? "text-text-theme-primary" : "text-text-theme-secondary italic"}`}>
                                {hasDriver ? getDriverName(bus.driverId) : "No driver assigned"}
                              </p>
                            </div>
                          </div>
                          {/* Route */}
                          <div className="flex items-start gap-2.5">
                            <MapPinIcon className="w-4 h-4 text-text-theme-secondary mt-0.5 shrink-0" />
                            <div className="text-xs">
                              <p className="font-semibold text-text-theme-secondary text-[10px] uppercase tracking-wider">Assigned Route</p>
                              <p className={`font-bold mt-0.5 ${hasRoute ? "text-text-theme-primary" : "text-text-theme-secondary italic"}`}>
                                {hasRoute ? getRouteDetails(bus.routeId) : "No route assigned"}
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>
                      {/* Actions Panel */}
                      <div className="mt-6 pt-4 border-t border-border-theme/40 flex gap-2">
                        {assignmentStatus === "unassigned" ? (
                          <button
                            onClick={() => openAssignModal(bus)}
                            className="w-full py-2 bg-primary-main hover:bg-primary-dark text-white rounded-xl text-xs font-bold shadow-xs active:scale-95 transition-all cursor-pointer border-none"
                          >
                            Assign Driver & Route
                          </button>
                        ) : (
                          <>
                            <button
                              onClick={() => openAssignModal(bus)}
                              className="flex-1 py-2 bg-background-default hover:bg-background-default/80 border border-border-theme text-text-theme-primary rounded-xl text-xs font-bold active:scale-95 transition-all cursor-pointer"
                            >
                              Modify
                            </button>
                            <button
                              onClick={() => openRevokeModal(bus)}
                              className="flex-1 py-2 bg-rose-500/10 hover:bg-rose-500 text-rose-600 hover:text-white border border-rose-500/20 hover:border-transparent rounded-xl text-xs font-bold active:scale-95 transition-all cursor-pointer"
                            >
                              Revoke
                            </button>
                          </>
                        )}
                      </div>
                    </motion.div>
                  );
                })
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
                {searchQuery ? "No matches found" : "No buses in college fleet"}
              </h3>
              <p className="text-text-theme-secondary text-sm font-semibold max-w-sm mx-auto">
                {searchQuery
                  ? `We couldn't find any fleet vehicles matching "${searchQuery}"`
                  : "Get started by adding fleet buses in the Fleet module first."}
              </p>
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery("")}
                  className="mt-4 text-primary-main font-bold text-sm hover:underline cursor-pointer bg-transparent border-none"
                >
                  Clear Search
                </button>
              )}
            </motion.div>
          )}
        </>
      )}

      {activeTab === "overrides" && (
        <div className="space-y-6">
          {loadingOverrides ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {Array.from({ length: 3 }).map((_, idx) => (
                <div
                  key={`skeleton-override-${idx}`}
                  className="bg-background-paper border border-border-theme/40 rounded-3xl p-6 shadow-xs flex flex-col space-y-4 relative overflow-hidden"
                >
                  <div className="h-5 rounded-lg w-1/2 shimmer" />
                  <div className="h-3 rounded-lg w-1/3 shimmer" />
                  <div className="border-t border-border-theme/45 pt-4 space-y-2">
                    <div className="h-3 rounded-lg w-full shimmer" />
                    <div className="h-3 rounded-lg w-2/3 shimmer" />
                  </div>
                </div>
              ))}
            </div>
          ) : overrideRequests.length === 0 ? (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-background-paper rounded-3xl border border-dashed border-border-theme py-16 text-center shadow-inner"
            >
              <div className="bg-background-default w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 border border-border-theme shadow-sm">
                <CheckCircleIcon className="w-8 h-8 text-emerald-500" />
              </div>
              <h3 className="text-lg font-black text-text-theme-primary mb-1">
                No Pending Override Requests
              </h3>
              <p className="text-text-theme-secondary text-sm font-semibold max-w-sm mx-auto">
                All teacher override authorization requests have been resolved.
              </p>
            </motion.div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {overrideRequests.map((request) => (
                <motion.div
                  key={request._id}
                  layout
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  whileHover={{ y: -4 }}
                  className="bg-background-paper rounded-3xl p-6 border border-border-theme/40 shadow-xs flex flex-col justify-between hover:shadow-md transition-all duration-300 relative overflow-hidden"
                >
                  <div>
                    {/* Header */}
                    <div className="flex justify-between items-start mb-4">
                      <div className="p-3 bg-linear-to-tr from-amber-500/10 to-amber-500/5 rounded-2xl border border-amber-500/20">
                        <SparklesIcon className="w-6 h-6 text-amber-500" />
                      </div>
                      <span className="px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider border bg-amber-500/10 text-amber-500 border-amber-500/20 animate-pulse">
                        Pending Approval
                      </span>
                    </div>
                    {/* Details */}
                    <div>
                      <h3 className="text-lg font-black text-text-theme-primary tracking-tight">
                        Bus {request.busId?.busNumber || "N/A"} Override
                      </h3>
                      <p className="text-[10px] font-semibold text-text-theme-secondary uppercase tracking-widest mt-0.5">
                        Requested by: {request.teacherId?.fullName || "Teacher"}
                      </p>
                    </div>
                    <div className="mt-5 pt-4 border-t border-border-theme/40 space-y-3 text-xs">
                      <div>
                        <p className="font-semibold text-text-theme-secondary text-[10px] uppercase tracking-wider">Teacher Contact</p>
                        <p className="font-bold text-text-theme-primary mt-0.5">
                          {request.teacherId?.email || "N/A"}
                        </p>
                        {request.teacherId?.phoneNumber && (
                          <p className="font-medium text-text-theme-secondary mt-0.5">
                            {request.teacherId.phoneNumber}
                          </p>
                        )}
                      </div>
                      <div>
                        <p className="font-semibold text-text-theme-secondary text-[10px] uppercase tracking-wider">Request Time</p>
                        <p className="font-bold text-text-theme-primary mt-0.5">
                          {new Date(request.createdAt).toLocaleString()}
                        </p>
                      </div>
                    </div>
                  </div>
                  {/* Actions */}
                  <div className="mt-6 pt-4 border-t border-border-theme/40 flex gap-2">
                    <button
                      onClick={() => handleResolveOverride(request._id, "approved")}
                      className="flex-1 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold active:scale-95 transition-all cursor-pointer border-none"
                    >
                      Approve
                    </button>
                    <button
                      onClick={() => handleResolveOverride(request._id, "rejected")}
                      className="flex-1 py-2.5 bg-rose-500/10 hover:bg-rose-500 text-rose-600 hover:text-white border border-rose-500/20 hover:border-transparent rounded-xl text-xs font-bold active:scale-95 transition-all cursor-pointer"
                    >
                      Reject
                    </button>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Revocation Confirmation */}
      <ConfirmationModal
        isOpen={isRevokeModalOpen}
        onClose={() => setIsRevokeModalOpen(false)}
        onConfirm={handleRevokeConfirm}
        title="Revoke Bus Assignment"
        message={`Are you sure you want to revoke driver and route assignments for Bus ${selectedBus?.busNumber}? This resets its status to Unassigned and halts active tracking sessions.`}
        confirmText="Revoke Assignment"
      />

      {/* Assign Driver & Route Modal */}
      <AnimatePresence>
        {isAssignModalOpen && (
          <div className="fixed inset-0 z-100 flex items-center justify-center p-4 sm:p-6">
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => {
                setIsAssignModalOpen(false);
                setSelectedBus(null);
              }}
              className="absolute inset-0 modal-backdrop"
            />

            {/* Modal content */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              transition={{ type: "spring", damping: 25, stiffness: 350 }}
              className="relative w-full max-w-lg overflow-hidden rounded-3xl backdrop-blur-xl bg-white/75 dark:bg-slate-900/90 border border-white/30 dark:border-slate-850 p-6 shadow-2xl z-10"
            >
              <div className="flex items-center justify-between pb-4 border-b border-border-theme/40">
                <h3 className="text-lg font-black text-text-theme-primary flex items-center gap-2">
                  <SparklesIcon className="w-5 h-5 text-primary-main" />
                  Assign Driver & Route: Bus {selectedBus?.busNumber}
                </h3>
                <button
                  type="button"
                  onClick={() => {
                    setIsAssignModalOpen(false);
                    setSelectedBus(null);
                  }}
                  className="rounded-full p-1 text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-500 dark:hover:text-slate-300 transition-colors"
                >
                  <XMarkIcon className="h-6 w-6" />
                </button>
              </div>

              <form onSubmit={handleAssignSubmit} className="mt-4 space-y-4">
                {/* Driver Field */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-black uppercase tracking-wider text-text-theme-secondary">
                    Select Driver
                  </label>
                  <select
                    value={selectedDriverId}
                    onChange={(e) => setSelectedDriverId(e.target.value)}
                    className="block w-full px-4 py-3 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 outline-none transition-all duration-200 cursor-pointer"
                  >
                    <option value="">Select a driver</option>
                    {driversList.map((driver) => {
                      const assignment = getDriverCurrentAssignment(driver._id, selectedBus?._id);
                      return (
                        <option key={driver._id} value={driver._id}>
                          {driver.fullName} {assignment ? `(${assignment})` : ""}
                        </option>
                      );
                    })}
                  </select>
                </div>

                {/* Route Field */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-black uppercase tracking-wider text-text-theme-secondary">
                    Select Route
                  </label>
                  <select
                    value={selectedRouteId}
                    onChange={(e) => setSelectedRouteId(e.target.value)}
                    className="block w-full px-4 py-3 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 outline-none transition-all duration-200 cursor-pointer"
                  >
                    <option value="">Select a route</option>
                    {(Array.isArray(routes) ? routes : []).map((route) => (
                      <option key={route._id} value={route._id}>
                        {route.routeName} ({route.startPoint?.name} ➔ {route.endPoint?.name})
                      </option>
                    ))}
                  </select>
                </div>

                <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end pt-4 border-t border-border-theme/40">
                  <button
                    type="button"
                    onClick={() => {
                      setIsAssignModalOpen(false);
                      setSelectedBus(null);
                    }}
                    className="w-full inline-flex justify-center items-center rounded-xl bg-white dark:bg-slate-800 px-4 py-2.5 text-sm font-semibold text-slate-900 dark:text-slate-100 shadow-sm ring-1 ring-inset ring-slate-300 dark:ring-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 sm:w-auto transition-all"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="w-full inline-flex justify-center items-center rounded-xl bg-primary-main hover:bg-primary-dark px-4 py-2.5 text-sm font-semibold text-white shadow-sm sm:w-auto transition-all border-none"
                  >
                    Save Assignment
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

// Simple helper wrapper to avoid nested motion issues
const AssignModalWrapper = ({ children }) => {
  return <>{children}</>;
};

export default CoordinatorDashboard;
