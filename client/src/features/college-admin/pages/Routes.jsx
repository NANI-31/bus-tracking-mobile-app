import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  MapIcon,
  PlusIcon,
  TrashIcon,
  MapPinIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  MapPinIcon as PinIcon,
  EllipsisHorizontalIcon,
  MagnifyingGlassIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import {
  getRoutes,
  createRoute,
  removeRoute,
} from "../slices/collegeAdminSlice";
import {
  Card,
  CardContent,
  IconButton,
  Collapse,
  Tooltip,
  Avatar,
  Box,
  Typography,
} from "@mui/material";
import ConfirmationModal from "@/components/common/ConfirmationModal";

import RouteFormModal from "../components/Routes/RouteFormModal";
import RouteCard from "../components/Routes/RouteCard";

const Routes = () => {
  const dispatch = useDispatch();
  const { routes, loading } = useSelector((state) => state.collegeAdmin);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [deleteModal, setDeleteModal] = useState({
    isOpen: false,
    routeId: null,
  });

  useEffect(() => {
    dispatch(getRoutes());
  }, [dispatch]);

  const filteredRoutes = routes?.filter((route) => {
    const q = searchQuery.toLowerCase();
    const matchesName = route.routeName?.toLowerCase().includes(q);
    const matchesStops = route.stopPoints?.some((stop) =>
      stop.name?.toLowerCase().includes(q),
    );
    return matchesName || matchesStops;
  });

  const handleAddRoute = (routeData) => {
    // Transform data to match IRoute model
    const formattedData = {
      routeName: routeData.name,
      routeType: "pickup", // Default to pickup for now
      stopPoints: routeData.stops.map((stop) => ({
        name: stop.name,
        location: {
          lat: parseFloat(stop.lat) || 0,
          lng: parseFloat(stop.lng) || 0,
        },
      })),
      // Set start and end points from stops
      startPoint: {
        name: routeData.stops[0].name,
        location: {
          lat: parseFloat(routeData.stops[0].lat) || 0,
          lng: parseFloat(routeData.stops[0].lng) || 0,
        },
      },
      endPoint: {
        name: routeData.stops[routeData.stops.length - 1].name,
        location: {
          lat: parseFloat(routeData.stops[routeData.stops.length - 1].lat) || 0,
          lng: parseFloat(routeData.stops[routeData.stops.length - 1].lng) || 0,
        },
      },
    };
    dispatch(createRoute(formattedData));
  };

  const handleDeleteRoute = (routeId) => {
    setDeleteModal({ isOpen: true, routeId });
  };

  const confirmDeleteRoute = () => {
    if (deleteModal.routeId) {
      dispatch(removeRoute(deleteModal.routeId));
    }
  };

  return (
    <div className="space-y-6 min-h-screen bg-[#f8fafc] -m-6 p-6">
      <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 bg-white p-6 rounded-2xl border border-slate-100 shadow-sm">
        <div>
          <h1 className="text-2xl font-black text-slate-800 tracking-tight">
            Route Management
          </h1>
          <p className="text-slate-500 text-sm font-medium">
            Manage campus transportation pathways and stops
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-center gap-3 w-full lg:w-auto">
          {/* Search Bar */}
          <div className="relative w-full sm:w-80 group">
            <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <MagnifyingGlassIcon className="h-5 h-5 text-slate-400 group-focus-within:text-[#1E90FF] transition-colors" />
            </div>
            <input
              type="text"
              placeholder="Search by route or stop name..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="block w-full pl-11 pr-10 py-2.5 bg-slate-50 border-2 border-slate-100 rounded-xl text-sm font-bold text-slate-700 placeholder:text-slate-400 placeholder:font-medium focus:bg-white focus:border-[#1E90FF] focus:ring-4 focus:ring-blue-50 transition-all outline-none"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            )}
          </div>

          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center justify-center space-x-2 px-6 py-2.5 bg-[#1E90FF] text-white rounded-xl font-bold hover:bg-[#1C64F2] hover:shadow-lg hover:shadow-blue-200 active:scale-95 transition-all w-full sm:w-auto"
          >
            <PlusIcon className="w-5 h-5" />
            <span>Add New Route</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        <AnimatePresence mode="popLayout">
          {Array.isArray(filteredRoutes) &&
            filteredRoutes.map((route) => (
              <RouteCard
                key={route._id}
                route={route}
                onDelete={handleDeleteRoute}
              />
            ))}
        </AnimatePresence>
      </div>

      {(!filteredRoutes || filteredRoutes.length === 0) && !loading && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl border-2 border-dashed border-slate-200 py-20 text-center"
        >
          <div className="bg-slate-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4 border-4 border-white shadow-sm">
            <MapIcon className="w-10 h-10 text-slate-300" />
          </div>
          <h3 className="text-xl font-black text-slate-800 mb-1">
            {searchQuery ? "No matches found" : "No routes yet"}
          </h3>
          <p className="text-slate-500 font-medium">
            {searchQuery
              ? `We couldn't find any routes or stops matching "${searchQuery}"`
              : "Get started by creating your first transportation route."}
          </p>
          {searchQuery && (
            <button
              onClick={() => setSearchQuery("")}
              className="mt-6 text-[#1E90FF] font-black text-sm hover:underline"
            >
              Clear Search
            </button>
          )}
        </motion.div>
      )}

      <RouteFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleAddRoute}
      />

      <ConfirmationModal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, routeId: null })}
        onConfirm={confirmDeleteRoute}
        title="Delete Route"
        message="Are you sure you want to delete this route? All associated bus schedules for this route will also be affected."
        confirmText="Delete"
      />
    </div>
  );
};

export default Routes;
