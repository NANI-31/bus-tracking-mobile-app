import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { PlusIcon, TrashIcon, XCircleIcon, CheckCircleIcon, ExclamationCircleIcon } from "@heroicons/react/24/outline";

const RouteFormModal = ({ isOpen, onClose, onSubmit, route }) => {
  const [formData, setFormData] = useState({
    name: "",
    color: "#1E90FF",
    stops: [{ id: Math.random().toString(36).substring(2, 9), name: "", lat: "", lng: "" }],
  });

  const [errors, setErrors] = useState({
    name: "",
    stops: [{ name: "", lat: "", lng: "" }],
  });

  const [step, setStep] = useState(1);

  const handleNextStep = () => {
    if (!formData.name.trim()) {
      setErrors((prev) => ({ ...prev, name: "Route name is required." }));
      return;
    }
    setStep(2);
  };

  // Geocoding suggestions states
  const [suggestions, setSuggestions] = useState({});
  const [activeSearchIndex, setActiveSearchIndex] = useState(null);
  const [loadingSuggestions, setLoadingSuggestions] = useState(false);
  const [draggedIndex, setDraggedIndex] = useState(null);
  const searchTimeoutRef = React.useRef(null);

  useEffect(() => {
    if (isOpen) {
      setStep(1);
      setSuggestions({});
      setActiveSearchIndex(null);
      setLoadingSuggestions(false);
      setDraggedIndex(null);
      if (route) {
        setFormData({
          name: route.routeName || "",
          color: route.color || "#1E90FF",
          stops: route.stopPoints?.map((stop) => ({
            id: stop._id || Math.random().toString(36).substring(2, 9),
            name: stop.name || "",
            lat: stop.location?.lat?.toString() || "",
            lng: stop.location?.lng?.toString() || "",
          })) || [{ id: Math.random().toString(36).substring(2, 9), name: "", lat: "", lng: "" }],
        });
        setErrors({
          name: "",
          stops: route.stopPoints?.map(() => ({ name: "", lat: "", lng: "" })) || [{ name: "", lat: "", lng: "" }],
        });
      } else {
        setFormData({
          name: "",
          color: "#1E90FF",
          stops: [{ id: Math.random().toString(36).substring(2, 9), name: "", lat: "", lng: "" }],
        });
        setErrors({
          name: "",
          stops: [{ name: "", lat: "", lng: "" }],
        });
      }
    }
  }, [isOpen, route]);

  const handleAddStop = () => {
    setFormData({
      ...formData,
      stops: [...formData.stops, { id: Math.random().toString(36).substring(2, 9), name: "", lat: "", lng: "" }],
    });
    setErrors({
      ...errors,
      stops: [...errors.stops, { name: "", lat: "", lng: "" }],
    });
  };

  const handleStopChange = (index, field, value) => {
    const newStops = [...formData.stops];
    newStops[index][field] = value;
    setFormData({ ...formData, stops: newStops });

    const newStopErrors = [...errors.stops];
    if (!newStopErrors[index]) {
      newStopErrors[index] = { name: "", lat: "", lng: "" };
    }

    if (field === "name") {
      newStopErrors[index].name = value.trim() ? "" : "Name is required.";
    } else if (field === "lat") {
      const latVal = parseFloat(value);
      if (!value.trim()) {
        newStopErrors[index].lat = "Required.";
      } else if (isNaN(latVal) || latVal < -90 || latVal > 90) {
        newStopErrors[index].lat = "Must be -90 to 90.";
      } else {
        newStopErrors[index].lat = "";
      }
    } else if (field === "lng") {
      const lngVal = parseFloat(value);
      if (!value.trim()) {
        newStopErrors[index].lng = "Required.";
      } else if (isNaN(lngVal) || lngVal < -180 || lngVal > 180) {
        newStopErrors[index].lng = "Must be -180 to 180.";
      } else {
        newStopErrors[index].lng = "";
      }
    }
    setErrors({ ...errors, stops: newStopErrors });
  };

  const handleSearchStopName = (index, value) => {
    const newStops = [...formData.stops];
    newStops[index].name = value;
    setFormData({ ...formData, stops: newStops });

    const newStopErrors = [...errors.stops];
    if (newStopErrors[index]) {
      newStopErrors[index].name = value.trim() ? "" : "Name is required.";
      setErrors({ ...errors, stops: newStopErrors });
    }

    if (!value.trim() || value.length < 3) {
      setSuggestions((prev) => ({ ...prev, [index]: [] }));
      return;
    }

    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }

    setActiveSearchIndex(index);
    searchTimeoutRef.current = setTimeout(async () => {
      try {
        setLoadingSuggestions(true);
        const res = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&limit=5&q=${encodeURIComponent(value)}`
        );
        const data = await res.json();
        setSuggestions((prev) => ({
          ...prev,
          [index]: data.map((item) => ({
            display_name: item.display_name,
            lat: item.lat,
            lon: item.lon,
          })),
        }));
      } catch (error) {
        console.error("Geocoding fetch failed", error);
      } finally {
        setLoadingSuggestions(false);
      }
    }, 450);
  };

  const handleSelectSuggestion = (index, sug) => {
    const newStops = [...formData.stops];
    const displayNameParts = sug.display_name.split(",");
    const shortName = displayNameParts[0];

    newStops[index] = {
      ...newStops[index],
      name: shortName,
      lat: parseFloat(sug.lat).toFixed(6),
      lng: parseFloat(sug.lon).toFixed(6),
    };
    setFormData({ ...formData, stops: newStops });
    
    const newStopErrors = [...errors.stops];
    if (newStopErrors[index]) {
      newStopErrors[index] = { name: "", lat: "", lng: "" };
      setErrors({ ...errors, stops: newStopErrors });
    }

    setSuggestions((prev) => ({ ...prev, [index]: [] }));
    setActiveSearchIndex(null);
  };

  const moveStop = (index, direction) => {
    const newStops = [...formData.stops];
    const targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= newStops.length) return;

    // Swap stops
    const temp = newStops[index];
    newStops[index] = newStops[targetIndex];
    newStops[targetIndex] = temp;

    // Swap errors
    const newStopErrors = [...errors.stops];
    const tempErr = newStopErrors[index];
    newStopErrors[index] = newStopErrors[targetIndex];
    newStopErrors[targetIndex] = tempErr;

    setFormData({ ...formData, stops: newStops });
    setErrors({ ...errors, stops: newStopErrors });
  };

  const handleRemoveStop = (index) => {
    const newStops = formData.stops.filter((_, i) => i !== index);
    const newStopErrors = errors.stops.filter((_, i) => i !== index);
    setFormData({ ...formData, stops: newStops });
    setErrors({ ...errors, stops: newStopErrors });
  };

  const handleNameChange = (e) => {
    const val = e.target.value;
    setFormData({ ...formData, name: val });
    setErrors({
      ...errors,
      name: val.trim() ? "" : "Route name is required.",
    });
  };

  // Drag and Drop handlers
  const handleDragStart = (e, index) => {
    setDraggedIndex(index);
    e.dataTransfer.effectAllowed = "move";
  };

  const handleDragOver = (e, index) => {
    e.preventDefault();
    if (draggedIndex === null || draggedIndex === index) return;

    const newStops = [...formData.stops];
    const item = newStops[draggedIndex];
    newStops.splice(draggedIndex, 1);
    newStops.splice(index, 0, item);

    const newStopErrors = [...errors.stops];
    const errItem = newStopErrors[draggedIndex];
    newStopErrors.splice(draggedIndex, 1);
    newStopErrors.splice(index, 0, errItem);

    setFormData({ ...formData, stops: newStops });
    setErrors({ ...errors, stops: newStopErrors });
    setDraggedIndex(index);
  };

  const handleDragEnd = () => {
    setDraggedIndex(null);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    let hasError = false;
    const newErrors = {
      name: "",
      stops: [],
    };

    if (!formData.name.trim()) {
      newErrors.name = "Route name is required.";
      hasError = true;
    }

    formData.stops.forEach((stop, i) => {
      const stopError = { name: "", lat: "", lng: "" };
      const latVal = parseFloat(stop.lat);
      const lngVal = parseFloat(stop.lng);

      if (!stop.name.trim()) {
        stopError.name = "Stop name is required.";
        hasError = true;
      }
      if (isNaN(latVal) || latVal < -90 || latVal > 90) {
        stopError.lat = "Lat must be -90 to 90.";
        hasError = true;
      }
      if (isNaN(lngVal) || lngVal < -180 || lngVal > 180) {
        stopError.lng = "Lng must be -180 to 180.";
        hasError = true;
      }
      newErrors.stops[i] = stopError;
    });

    setErrors(newErrors);

    if (formData.stops.length < 2) {
      alert("A route must have at least 2 stops.");
      return;
    }

    if (hasError) return;

    onSubmit(formData);
    setFormData({ name: "", color: "#1E90FF", stops: [{ id: Math.random().toString(36).substring(2, 9), name: "", lat: "", lng: "" }] });
    setErrors({ name: "", stops: [{ name: "", lat: "", lng: "" }] });
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 modal-backdrop"
          />

          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 350 }}
            className="relative bg-white/75 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-white/30 dark:border-slate-800 shadow-2xl p-6 w-full max-w-lg my-8 z-10 text-slate-800 dark:text-slate-100"
          >
            <h2 className="text-xl font-bold text-slate-800 dark:text-slate-100 mb-4">{route ? "Edit Route" : "Add New Route"}</h2>
            
            {/* Step Progress Stepper */}
            <div className="flex items-center justify-between mb-6 px-1">
              <div className="flex items-center space-x-2.5">
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-black transition-all cursor-pointer ${
                    step === 1 
                      ? "bg-[#1E90FF] text-white shadow-md shadow-blue-500/20" 
                      : "bg-emerald-500 text-white"
                  }`}
                >
                  {step > 1 ? (
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="3">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  ) : "1"}
                </button>
                <span className={`text-xs font-extrabold transition-colors ${
                  step === 1 ? "text-slate-800 dark:text-slate-100" : "text-slate-400 dark:text-slate-500"
                }`}>
                  Details
                </span>
              </div>
              <div className="flex-1 h-0.5 mx-4 bg-slate-150 dark:bg-slate-800 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-[#1E90FF] transition-all duration-300"
                  style={{ width: step === 2 ? "100%" : "0%" }}
                />
              </div>
              <div className="flex items-center space-x-2.5">
                <button
                  type="button"
                  onClick={handleNextStep}
                  className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-black transition-all cursor-pointer ${
                    step === 2 
                      ? "bg-[#1E90FF] text-white shadow-md shadow-blue-500/20" 
                      : "bg-slate-105 dark:bg-slate-850 text-slate-455 dark:text-slate-500"
                  }`}
                >
                  2
                </button>
                <span className={`text-xs font-extrabold transition-colors ${
                  step === 2 ? "text-slate-800 dark:text-slate-100" : "text-slate-400 dark:text-slate-500"
                }`}>
                  Waypoints
                </span>
              </div>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <AnimatePresence mode="wait">
                {step === 1 && (
                  <motion.div
                    key="step1"
                    initial={{ opacity: 0, x: -12 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 12 }}
                    transition={{ duration: 0.18 }}
                    className="space-y-4"
                  >
                    {/* Route Name */}
                    <div className="relative pb-5">
                      <label htmlFor="routeNameInput" className="block text-sm font-semibold text-slate-700 dark:text-slate-350">
                        Route Name
                      </label>
                      <div className="relative mt-1">
                        <input
                          id="routeNameInput"
                          type="text"
                          required
                          className={`block w-full border rounded-xl p-2.5 pr-10 text-sm bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus-ring transition-colors ${
                            errors.name
                              ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5"
                              : formData.name && !errors.name
                              ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5"
                              : "border-slate-300 dark:border-slate-700"
                          }`}
                          placeholder="e.g., Route A - Main Campus"
                          value={formData.name}
                          onChange={handleNameChange}
                        />
                        <div className="absolute right-3.5 top-3 flex items-center pointer-events-none z-10">
                          {formData.name && !errors.name && (
                            <CheckCircleIcon className="w-5 h-5 text-emerald-500" />
                          )}
                          {errors.name && (
                            <ExclamationCircleIcon className="w-5 h-5 text-rose-500 animate-pulse" />
                          )}
                        </div>
                      </div>
                      <AnimatePresence>
                        {errors.name && (
                          <motion.p
                            initial={{ opacity: 0, y: -2 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -2 }}
                            transition={{ type: "spring", stiffness: 500, damping: 30 }}
                            className="absolute left-1 bottom-0.5 text-[10px] font-bold text-rose-500"
                          >
                            {errors.name}
                          </motion.p>
                        )}
                      </AnimatePresence>
                    </div>

                    {/* Color Identifier Selection */}
                    <div>
                      <label className="block text-sm font-semibold text-slate-700 dark:text-slate-350 mb-2">
                        Route Color Identifier
                      </label>
                      <div className="flex items-center space-x-3.5 bg-slate-50/50 dark:bg-slate-850/20 p-2.5 rounded-2xl border border-slate-100 dark:border-slate-800/80">
                        {[
                          { hex: "#1E90FF", name: "Blue" },
                          { hex: "#10B981", name: "Green" },
                          { hex: "#F97316", name: "Orange" },
                          { hex: "#8B5CF6", name: "Purple" },
                          { hex: "#F43F5E", name: "Rose" },
                        ].map((colorOption) => (
                          <button
                            key={colorOption.hex}
                            type="button"
                            onClick={() => setFormData({ ...formData, color: colorOption.hex })}
                            className="relative w-8 h-8 rounded-full border-2 transition-all cursor-pointer flex items-center justify-center hover:scale-110 active:scale-95"
                            style={{
                              backgroundColor: colorOption.hex,
                              borderColor: formData.color === colorOption.hex ? "#ffffff" : "transparent",
                              boxShadow: formData.color === colorOption.hex 
                                ? `0 0 0 2px ${colorOption.hex}, 0 4px 12px ${colorOption.hex}50`
                                : "none",
                            }}
                            title={colorOption.name}
                          >
                            {formData.color === colorOption.hex && (
                              <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="3">
                                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                              </svg>
                            )}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div className="flex justify-end space-x-3 pt-4 border-t border-slate-150 dark:border-slate-800">
                      <button
                        type="button"
                        onClick={onClose}
                        className="px-4 py-2.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl font-bold text-sm cursor-pointer"
                      >
                        Cancel
                      </button>
                      <button
                        type="button"
                        onClick={handleNextStep}
                        className="px-6 py-2.5 bg-[#1E90FF] text-white rounded-xl font-bold hover:bg-[#1C64F2] shadow-lg shadow-blue-500/20 active:scale-95 transition-all text-sm cursor-pointer"
                      >
                        Next: Waypoints
                      </button>
                    </div>
                  </motion.div>
                )}

                {step === 2 && (
                  <motion.div
                    key="step2"
                    initial={{ opacity: 0, x: 12 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -12 }}
                    transition={{ duration: 0.18 }}
                    className="space-y-4"
                  >
                    {/* Stops Section */}
                    <div>
                      <span className="block text-sm font-semibold text-slate-700 dark:text-slate-350 mb-2">
                        Stop Waypoints (Drag handles or click arrows to sort)
                      </span>
                      <div className="max-h-[280px] overflow-y-auto space-y-2 pr-1">
                        <AnimatePresence initial={false}>
                          {formData.stops.map((stop, index) => (
                            <motion.div
                              key={stop.id}
                              layout
                              initial={{ opacity: 0, y: 10 }}
                              animate={{ opacity: 1, y: 0 }}
                              exit={{ opacity: 0, scale: 0.95 }}
                              transition={{ type: "spring", stiffness: 500, damping: 30 }}
                              draggable={true}
                              onDragStart={(e) => handleDragStart(e, index)}
                              onDragOver={(e) => handleDragOver(e, index)}
                              onDragEnd={handleDragEnd}
                              className={`flex space-x-2 items-start bg-slate-50/50 dark:bg-slate-850/30 p-3 rounded-2xl border transition-all duration-150 ${
                                draggedIndex === index
                                  ? "border-blue-500 bg-blue-500/5 shadow-md scale-[0.99]"
                                  : "border-slate-100 dark:border-slate-800/80"
                              }`}
                            >
                              {/* Drag Handle */}
                              <div className="mt-2.5 mr-1 cursor-grab active:cursor-grabbing select-none shrink-0" title="Drag to reorder">
                                <svg className="w-4.5 h-4.5 text-slate-400 dark:text-slate-650" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
                                  <path strokeLinecap="round" strokeLinejoin="round" d="M8 9h.01M12 9h.01M16 9h.01M8 15h.01M12 15h.01M16 15h.01" />
                                </svg>
                              </div>

                              {/* Move Up/Down Arrow Swappers */}
                              <div className="flex flex-col items-center mt-1 space-y-0.5 shrink-0">
                                <button
                                  type="button"
                                  onClick={() => moveStop(index, -1)}
                                  disabled={index === 0}
                                  className="p-0.5 rounded hover:bg-slate-200 dark:hover:bg-slate-800 text-slate-400 dark:text-slate-600 disabled:opacity-20 cursor-pointer transition-colors"
                                  title="Move Up"
                                >
                                  <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 15l7-7 7 7" />
                                  </svg>
                                </button>
                                <button
                                  type="button"
                                  onClick={() => moveStop(index, 1)}
                                  disabled={index === formData.stops.length - 1}
                                  className="p-0.5 rounded hover:bg-slate-200 dark:hover:bg-slate-800 text-slate-400 dark:text-slate-600 disabled:opacity-20 cursor-pointer transition-colors"
                                  title="Move Down"
                                >
                                  <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
                                  </svg>
                                </button>
                              </div>

                              <div className="flex-1 space-y-1">
                                {/* Stop Name input */}
                                <div className="relative pb-5">
                                  <label htmlFor={`stopNameInput-${stop.id}`} className="sr-only">Stop Name {index + 1}</label>
                                  <div className="relative">
                                    <input
                                      id={`stopNameInput-${stop.id}`}
                                      type="text"
                                      required
                                      placeholder={`Stop #${index + 1} Name (Search location...)`}
                                      className={`block w-full border rounded-xl p-2 pr-10 text-sm bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus-ring transition-colors ${
                                        errors.stops[index]?.name
                                          ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5"
                                          : stop.name && !errors.stops[index]?.name
                                          ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5"
                                          : "border-slate-300 dark:border-slate-700"
                                      }`}
                                      value={stop.name}
                                      onChange={(e) =>
                                        handleSearchStopName(index, e.target.value)
                                      }
                                      autoComplete="off"
                                    />
                                    <div className="absolute right-3 top-2 flex items-center space-x-1.5 z-10">
                                      {loadingSuggestions && activeSearchIndex === index ? (
                                        <span className="flex h-4 w-4">
                                          <svg className="animate-spin h-4 w-4 text-[#1E90FF]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                          </svg>
                                        </span>
                                      ) : (
                                        <>
                                          {stop.name && !errors.stops[index]?.name && (
                                            <CheckCircleIcon className="w-5 h-5 text-emerald-500" />
                                          )}
                                          {errors.stops[index]?.name && (
                                            <ExclamationCircleIcon className="w-5 h-5 text-rose-500 animate-pulse" />
                                          )}
                                        </>
                                      )}
                                    </div>
                                  </div>

                                  {activeSearchIndex === index && suggestions[index] && suggestions[index].length > 0 && (
                                    <div className="absolute left-0 right-0 mt-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-xl z-50 max-h-48 overflow-y-auto">
                                      {suggestions[index].map((sug, sIdx) => (
                                        <button
                                          key={sIdx}
                                          type="button"
                                          onClick={() => handleSelectSuggestion(index, sug)}
                                          className="w-full text-left px-3 py-2 text-xs hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-100 border-b border-slate-100 dark:border-slate-800 last:border-0 truncate font-semibold cursor-pointer block"
                                        >
                                          {sug.display_name}
                                        </button>
                                      ))}
                                    </div>
                                  )}
                                  <AnimatePresence>
                                    {errors.stops[index]?.name && (
                                      <motion.p
                                        initial={{ opacity: 0, y: -2 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        exit={{ opacity: 0, y: -2 }}
                                        transition={{ type: "spring", stiffness: 500, damping: 30 }}
                                        className="absolute left-1 bottom-0.5 text-[10px] font-bold text-rose-500"
                                      >
                                        {errors.stops[index].name}
                                      </motion.p>
                                    )}
                                  </AnimatePresence>
                                </div>
                                {/* Lat & Lng input row */}
                                <div className="flex space-x-2">
                                  <div className="flex-1 relative pb-5">
                                    <label htmlFor={`stopLatInput-${stop.id}`} className="sr-only">Latitude {index + 1}</label>
                                    <div className="relative">
                                      <input
                                        id={`stopLatInput-${stop.id}`}
                                        type="number"
                                        step="any"
                                        placeholder="Latitude"
                                        className={`block w-full border rounded-xl p-2 pr-8 text-xs bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus-ring transition-colors ${
                                          errors.stops[index]?.lat
                                            ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5"
                                            : stop.lat && !errors.stops[index]?.lat
                                            ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5"
                                            : "border-slate-300 dark:border-slate-700"
                                        }`}
                                        value={stop.lat}
                                        onChange={(e) =>
                                          handleStopChange(index, "lat", e.target.value)
                                        }
                                      />
                                      <div className="absolute right-2 top-2 flex items-center pointer-events-none z-10">
                                        {stop.lat && !errors.stops[index]?.lat && (
                                          <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                                        )}
                                        {errors.stops[index]?.lat && (
                                          <ExclamationCircleIcon className="w-4 h-4 text-rose-500 animate-pulse" />
                                        )}
                                      </div>
                                    </div>
                                    <AnimatePresence>
                                      {errors.stops[index]?.lat && (
                                        <motion.p
                                          initial={{ opacity: 0, y: -2 }}
                                          animate={{ opacity: 1, y: 0 }}
                                          exit={{ opacity: 0, y: -2 }}
                                          transition={{ type: "spring", stiffness: 500, damping: 30 }}
                                          className="absolute left-1 bottom-0.5 text-[9px] font-bold text-rose-500 whitespace-nowrap"
                                        >
                                          {errors.stops[index].lat}
                                        </motion.p>
                                      )}
                                    </AnimatePresence>
                                  </div>
                                  <div className="flex-1 relative pb-5">
                                    <label htmlFor={`stopLngInput-${stop.id}`} className="sr-only">Longitude {index + 1}</label>
                                    <div className="relative">
                                      <input
                                        id={`stopLngInput-${stop.id}`}
                                        type="number"
                                        step="any"
                                        placeholder="Longitude"
                                        className={`block w-full border rounded-xl p-2 pr-8 text-xs bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus-ring transition-colors ${
                                          errors.stops[index]?.lng
                                            ? "border-rose-500 focus-ring-rose-500 bg-rose-500/5"
                                            : stop.lng && !errors.stops[index]?.lng
                                            ? "border-emerald-500 focus-ring-emerald-500 bg-emerald-500/5"
                                            : "border-slate-300 dark:border-slate-700"
                                        }`}
                                        value={stop.lng}
                                        onChange={(e) =>
                                          handleStopChange(index, "lng", e.target.value)
                                        }
                                      />
                                      <div className="absolute right-2 top-2 flex items-center pointer-events-none z-10">
                                        {stop.lng && !errors.stops[index]?.lng && (
                                          <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                                        )}
                                        {errors.stops[index]?.lng && (
                                          <ExclamationCircleIcon className="w-4 h-4 text-rose-500 animate-pulse" />
                                        )}
                                      </div>
                                    </div>
                                    <AnimatePresence>
                                      {errors.stops[index]?.lng && (
                                        <motion.p
                                          initial={{ opacity: 0, y: -2 }}
                                          animate={{ opacity: 1, y: 0 }}
                                          exit={{ opacity: 0, y: -2 }}
                                          transition={{ type: "spring", stiffness: 500, damping: 30 }}
                                          className="absolute left-1 bottom-0.5 text-[9px] font-bold text-rose-500 whitespace-nowrap"
                                        >
                                          {errors.stops[index].lng}
                                        </motion.p>
                                      )}
                                    </AnimatePresence>
                                  </div>
                                </div>
                              </div>
                              {formData.stops.length > 1 && (
                                <button
                                  type="button"
                                  onClick={() => handleRemoveStop(index)}
                                  aria-label={`Remove Stop ${index + 1}`}
                                  className="text-red-500 hover:text-red-700 dark:hover:text-red-400 focus-ring p-1.5 rounded-lg mt-1 transition-colors cursor-pointer shrink-0"
                                >
                                  <TrashIcon className="w-5 h-5" />
                                </button>
                              )}
                            </motion.div>
                          ))}
                        </AnimatePresence>
                      </div>
                      <button
                        type="button"
                        onClick={handleAddStop}
                        className="text-sm text-[#1E90FF] hover:text-[#1C64F2] font-bold flex items-center mt-2.5 cursor-pointer"
                      >
                        <PlusIcon className="w-4 h-4 mr-1 stroke-2" /> Add Stop
                      </button>
                    </div>

                    <div className="flex justify-between pt-4 border-t border-slate-150 dark:border-slate-800">
                      <button
                        type="button"
                        onClick={() => setStep(1)}
                        className="px-4 py-2.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl font-bold text-sm cursor-pointer"
                      >
                        Back to Details
                      </button>
                      <div className="flex space-x-3">
                        <button
                          type="button"
                          onClick={onClose}
                          className="px-4 py-2.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl font-bold text-sm cursor-pointer"
                        >
                          Cancel
                        </button>
                        <button
                          type="submit"
                          className="px-6 py-2.5 bg-[#1E90FF] text-white rounded-xl font-bold hover:bg-[#1C64F2] shadow-lg shadow-blue-500/20 active:scale-95 transition-all text-sm cursor-pointer"
                        >
                          {route ? "Save Changes" : "Create Route"}
                        </button>
                      </div>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

export default RouteFormModal;
