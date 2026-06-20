
import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import { toast } from "react-hot-toast";
import {
  MapPinIcon,
  ArrowPathIcon,
  TrashIcon,
  SignalIcon,
  SignalSlashIcon,
  SparklesIcon,
} from "@heroicons/react/24/outline";
import { getRoutes } from "@/features/college-admin/slices/collegeAdminSlice";
import ConfirmationModal from "@/components/common/ConfirmationModal";
import { clearRouteDirections } from "@/features/college-admin/api/collegeAdminApi";
const CoordinatorRoutes = () => {
  const dispatch = useDispatch();
  const { routes, loading } = useSelector((state) => state.collegeAdmin);
  const [clearingDirectionsId, setClearingDirectionsId] = useState(null);
  const [isClearDirectionsModalOpen, setIsClearDirectionsModalOpen] = useState(false);
  const [selectedRouteForClear, setSelectedRouteForClear] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("all");
  const [cacheFilter, setCacheFilter] = useState("cached");
  useEffect(() => {
    dispatch(getRoutes());
  }, [dispatch]);
  const handleRefresh = () => {
    dispatch(getRoutes());
    toast.success("Routes refreshed");
  };
  const openClearDirectionsModal = (route) => {
    setSelectedRouteForClear(route);
    setIsClearDirectionsModalOpen(true);
  };
  const handleClearDirectionsConfirm = async () => {
    if (!selectedRouteForClear) return;
    setClearingDirectionsId(selectedRouteForClear._id);
    setIsClearDirectionsModalOpen(false);
    try {
      await clearRouteDirections(selectedRouteForClear._id);
      toast.success(`Directions cleared for "${selectedRouteForClear.routeName}". Fresh data will be fetched from Google on next tracking session.`);
      dispatch(getRoutes());
    } catch (err) {
      toast.error(err?.message || "Failed to clear directions cache");
    } finally {
      setClearingDirectionsId(null);
      setSelectedRouteForClear(null);
    }
  };
  const routesList = Array.isArray(routes) ? routes : [];
  // Filter routes based on search, type, and cache status
  const filteredRoutes = routesList.filter((route) => {
    const matchesSearch = route.routeName
      .toLowerCase()
      .includes(searchQuery.toLowerCase()) ||
      (route.startPoint?.name || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (route.endPoint?.name || "").toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesType = typeFilter === "all" || route.routeType === typeFilter;
    
    const hasDirections = !!(route.directions?.polylinePoints?.length > 0);
    const matchesCache =
      cacheFilter === "all" ||
      (cacheFilter === "cached" && hasDirections) ||
      (cacheFilter === "not-cached" && !hasDirections);

    return matchesSearch && matchesType && matchesCache;
  });
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
            <SparklesIcon className="w-6 h-6 text-violet-500 animate-pulse" />
            Route Directions Manager
          </h1>
          <p className="text-text-theme-secondary text-sm font-semibold mt-1">
            View active college routes and manage Google Maps polyline directions data cache
          </p>
        </div>
        <div className="flex flex-col sm:flex-row items-center gap-3 w-full lg:w-auto">
          {/* Search */}
          <div className="relative w-full sm:w-64 group">
            <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <MapPinIcon className="w-5 h-5 text-text-theme-secondary group-focus-within:text-violet-500 transition-colors" />
            </div>
            <input
              type="text"
              placeholder="Search routes..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="block w-full pl-11 pr-10 py-2.5 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary placeholder:text-text-theme-secondary focus:border-violet-500 focus:ring-4 focus:ring-violet-500/15 outline-none transition-all duration-200"
            />
          </div>
          {/* Type Filter */}
          <div className="relative w-full sm:w-40">
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="block w-full pl-4 pr-10 py-2.5 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary focus:border-violet-500 focus:ring-4 focus:ring-violet-500/15 outline-none transition-all duration-200 cursor-pointer appearance-none"
            >
              <option value="all">All Types</option>
              <option value="pickup">Pickup</option>
              <option value="drop">Drop</option>
            </select>
          </div>
          {/* Cache Filter */}
          <div className="relative w-full sm:w-44">
            <select
              value={cacheFilter}
              onChange={(e) => setCacheFilter(e.target.value)}
              className="block w-full pl-4 pr-10 py-2.5 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary focus:border-violet-500 focus:ring-4 focus:ring-violet-500/15 outline-none transition-all duration-200 cursor-pointer appearance-none"
            >
              <option value="cached">Cached Only</option>
              <option value="not-cached">Not Cached Only</option>
              <option value="all">All Cache Status</option>
            </select>
          </div>
          {/* Refresh Button */}
          <button
            onClick={handleRefresh}
            className="flex items-center justify-center p-3.5 bg-background-paper border border-border-theme text-text-theme-primary hover:text-violet-500 rounded-2xl font-bold shadow-xs active:scale-95 transition-all cursor-pointer w-full sm:w-auto shrink-0"
          >
            <ArrowPathIcon className={`w-4.5 h-4.5 ${loading ? "animate-spin" : ""}`} />
          </button>
        </div>
      </motion.div>
      {/* Routes Grid */}
      <div className="grid grid-cols-1 gap-6">
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-background-paper rounded-3xl border border-border-theme/40 shadow-xs overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-border-theme/40 bg-slate-50/50 dark:bg-slate-900/20">
            <span className="text-xs font-black uppercase tracking-wider text-text-theme-primary">Route Details</span>
            <span className="text-xs font-black uppercase tracking-wider text-text-theme-primary text-center">Cache Status</span>
          </div>
          {loading && filteredRoutes.length === 0 ? (
            <div className="p-12 text-center">
              <ArrowPathIcon className="w-8 h-8 text-violet-500 animate-spin mx-auto mb-3" />
              <p className="text-sm font-bold text-text-theme-secondary">Loading routes...</p>
            </div>
          ) : filteredRoutes.length === 0 ? (
            <div className="py-16 text-center">
              <MapPinIcon className="w-12 h-12 text-text-theme-secondary/40 mx-auto mb-4" />
              <h3 className="text-lg font-black text-text-theme-primary mb-1">No routes found</h3>
              <p className="text-text-theme-secondary text-sm font-semibold max-w-sm mx-auto">
                No routes match your search or filter criteria.
              </p>
            </div>
          ) : (
            <div className="divide-y divide-border-theme/30">
              {filteredRoutes.map((route, idx) => {
                const hasDirections = !!(route.directions?.polylinePoints?.length > 0);
                const isClearing = clearingDirectionsId === route._id;
                const stopCount = route.stopPoints?.length || 0;
                return (
                  <motion.div
                    key={route._id}
                    initial={{ opacity: 0, x: -8 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: idx * 0.03 }}
                    className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 px-6 py-5 hover:bg-background-default/40 transition-colors"
                  >
                    {/* Route Details */}
                    <div className="flex items-start gap-4 min-w-0">
                      <div className="p-3 rounded-2xl bg-linear-to-tr from-violet-500/10 to-violet-400/5 border border-violet-500/15 shrink-0 mt-0.5">
                        <MapPinIcon className="w-5 h-5 text-violet-500" />
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <h3 className="text-base font-black text-text-theme-primary truncate">
                            {route.routeName}
                          </h3>
                          <span className="text-[10px] font-black uppercase tracking-widest px-2 py-0.5 rounded-lg bg-violet-500/10 text-violet-500 border border-violet-500/15">
                            {route.routeType}
                          </span>
                        </div>
                        <p className="text-xs font-bold text-text-theme-secondary mt-1">
                          <span className="text-text-theme-primary">{route.startPoint?.name || "Start"}</span>
                          <span className="mx-2">➔</span>
                          <span className="text-text-theme-primary">{route.endPoint?.name || "End"}</span>
                        </p>
                        <p className="text-[11px] font-semibold text-text-theme-secondary mt-0.5">
                          Stops: {stopCount} Stop points configured
                        </p>
                      </div>
                    </div>
                    {/* Cache Actions */}
                    <div className="flex items-center gap-4 sm:self-center self-end">
                      {/* Cache status badge */}
                      <div>
                        {hasDirections ? (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-wider bg-emerald-500/10 text-emerald-500 border border-emerald-500/20">
                            <SignalIcon className="w-3.5 h-3.5" />
                            Cached ({route.directions.polylinePoints.length} pts)
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-wider bg-amber-500/10 text-amber-500 border border-amber-500/20">
                            <SignalSlashIcon className="w-3.5 h-3.5" />
                            Not Cached
                          </span>
                        )}
                      </div>
                      {/* Clear Button */}
                      <button
                        onClick={() => openClearDirectionsModal(route)}
                        disabled={!hasDirections || isClearing}
                        className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-black border transition-all active:scale-95 cursor-pointer ${
                          !hasDirections || isClearing
                            ? "opacity-30 cursor-not-allowed bg-transparent border-border-theme text-text-theme-secondary"
                            : "bg-rose-500/10 hover:bg-rose-500 text-rose-500 hover:text-white border-rose-500/20 hover:border-transparent"
                        }`}
                      >
                        {isClearing ? (
                          <ArrowPathIcon className="w-4 h-4 animate-spin" />
                        ) : (
                          <TrashIcon className="w-4 h-4" />
                        )}
                        {isClearing ? "Clearing..." : "Clear Cache"}
                      </button>
                    </div>
                  </motion.div>
                );
              })}
            </div>
          )}
        </motion.div>
      </div>
      {/* Confirmation Modal */}
      <ConfirmationModal
        isOpen={isClearDirectionsModalOpen}
        onClose={() => {
          setIsClearDirectionsModalOpen(false);
          setSelectedRouteForClear(null);
        }}
        onConfirm={handleClearDirectionsConfirm}
        title="Clear Route Directions Cache"
        message={`Are you sure you want to clear cached Google directions for "${selectedRouteForClear?.routeName}"? This will delete the stored polyline/directions data from the database. The system will make a fresh call to the Google Directions API on the next driver tracking session.`}
        confirmText="Clear Directions Cache"
      />
    </div>
  );
};
export default CoordinatorRoutes;
