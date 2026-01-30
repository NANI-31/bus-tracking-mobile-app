import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  MapIcon,
  PlusIcon,
  TrashIcon,
  MapPinIcon,
} from "@heroicons/react/24/outline";
import {
  getRoutes,
  createRoute,
  removeRoute,
} from "../slices/collegeAdminSlice";

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
              className="text-sm text-blue-600 hover:text-blue-800 flex items-center mt-2"
            >
              <PlusIcon className="w-4 h-4 mr-1" /> Add Stop
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
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Create Route
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

const Routes = () => {
  const dispatch = useDispatch();
  const { routes, loading } = useSelector((state) => state.collegeAdmin);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    dispatch(getRoutes());
  }, [dispatch]);

  const handleAddRoute = (routeData) => {
    // Transform lat/lng strings to numbers if needed
    const formattedData = {
      ...routeData,
      stops: routeData.stops.map((stop) => ({
        ...stop,
        lat: parseFloat(stop.lat) || 0,
        lng: parseFloat(stop.lng) || 0,
      })),
    };
    dispatch(createRoute(formattedData));
  };

  const handleDeleteRoute = (routeId) => {
    if (window.confirm("Are you sure you want to delete this route?")) {
      dispatch(removeRoute(routeId));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Route Management</h1>
        <button
          onClick={() => setIsModalOpen(true)}
          className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <PlusIcon className="w-5 h-5 mr-2" />
          Add Route
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <AnimatePresence>
          {routes.map((route) => (
            <motion.div
              key={route._id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              layout
              className="bg-white rounded-xl shadow-sm p-6 border border-gray-100"
            >
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center space-x-3">
                  <div className="p-2 bg-purple-50 rounded-lg">
                    <MapIcon className="w-6 h-6 text-purple-600" />
                  </div>
                  <h3 className="text-lg font-bold text-gray-800">
                    {route.name}
                  </h3>
                </div>
                <button
                  onClick={() => handleDeleteRoute(route._id)}
                  className="text-gray-400 hover:text-red-500 transition-colors"
                >
                  <TrashIcon className="w-5 h-5" />
                </button>
              </div>

              <div className="relative pl-4 border-l-2 border-gray-200 ml-4 space-y-6">
                {route.stops.map((stop, index) => (
                  <div key={index} className="relative">
                    <div className="absolute -left-[25px] bg-white border-2 border-blue-500 rounded-full w-4 h-4"></div>
                    <p className="text-sm font-medium text-gray-800">
                      {stop.name}
                    </p>
                    <p className="text-xs text-gray-500">
                      {stop.lat && stop.lng
                        ? `${stop.lat.toFixed(4)}, ${stop.lng.toFixed(4)}`
                        : "Coordinates not set"}
                    </p>
                  </div>
                ))}
              </div>

              <div className="mt-6 pt-4 border-t border-gray-100 flex justify-between text-sm text-gray-500">
                <span>{route.stops.length} Stops</span>
                <span>ID: {route._id.substring(0, 8)}...</span>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {routes.length === 0 && !loading && (
        <div className="text-center py-12 text-gray-500">
          <MapIcon className="w-16 h-16 mx-auto mb-4 text-gray-300" />
          <p className="text-lg">No routes defined. Create your first route!</p>
        </div>
      )}

      <RouteFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleAddRoute}
      />
    </div>
  );
};

export default Routes;
