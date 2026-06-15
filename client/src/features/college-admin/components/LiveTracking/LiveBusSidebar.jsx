import React, { useEffect, useState } from "react";
import { useLiveTracking } from "@/components/common/LiveTrackingContext";
import {
  TruckIcon,
  MagnifyingGlassIcon,
  MapPinIcon,
  BoltIcon,
  ClockIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";

const LiveBusSidebarItem = ({
  bus,
  selectedBus,
  setSelectedBus,
  getBusStatus,
}) => {
  const { subscribeToBus } = useLiveTracking();
  const [locationData, setLocationData] = useState(() => bus.lastLocation || null);

  useEffect(() => {
    const unsubscribe = subscribeToBus(bus._id, (newLoc) => {
      setLocationData(newLoc);
    });
    return unsubscribe;
  }, [bus._id, subscribeToBus]);

  const dynamicBus = {
    ...bus,
    lastLocation: locationData,
    speed: locationData?.speed ?? bus.speed ?? 0,
    heading: locationData?.heading ?? bus.heading ?? 0,
    delay: locationData?.delay ?? bus.delay ?? 0,
  };

  const status = getBusStatus(dynamicBus);
  const isSelected = selectedBus?._id === bus._id;

  return (
    <button
      onClick={() => setSelectedBus(dynamicBus)}
      className={`w-full text-left p-3 rounded-xl border transition-all ${
        isSelected
          ? "border-blue-500 bg-blue-50/50 shadow-sm"
          : "border-gray-100 hover:border-gray-300 hover:bg-gray-50"
      }`}
    >
      <div className="flex justify-between items-start mb-1">
        <span className="font-bold text-gray-800 text-xs">
          Bus {bus.busNumber}
        </span>
        <span
          className={`text-[9px] font-bold uppercase px-1.5 py-0.5 rounded-md ${status.color}`}
        >
          {status.label}
        </span>
      </div>
      <div className="grid grid-cols-2 gap-2 text-[10px] text-gray-500">
        <div className="flex items-center">
          <BoltIcon className="w-3 h-3 mr-1" />
          {(dynamicBus.speed || 0).toFixed(2)} km/h
        </div>
        <div className="flex items-center">
          <ClockIcon className="w-3 h-3 mr-1" />
          {dynamicBus.delay || 0}m delay
        </div>
      </div>
    </button>
  );
};

const SelectedBusDetails = ({ bus, setSelectedBus, getBusStatus }) => {
  const { subscribeToBus } = useLiveTracking();
  const [locationData, setLocationData] = useState(() => bus.lastLocation || null);

  useEffect(() => {
    const unsubscribe = subscribeToBus(bus._id, (newLoc) => {
      setLocationData(newLoc);
    });
    return unsubscribe;
  }, [bus._id, subscribeToBus]);

  const dynamicBus = {
    ...bus,
    lastLocation: locationData,
    speed: locationData?.speed ?? bus.speed ?? 0,
    heading: locationData?.heading ?? bus.heading ?? 0,
    delay: locationData?.delay ?? bus.delay ?? 0,
  };

  const status = getBusStatus(dynamicBus);

  return (
    <div className="p-4 bg-[#1E90FF] text-white rounded-t-2xl">
      <div className="flex justify-between items-center mb-3">
        <h3 className="font-bold text-sm">Bus Details</h3>
        <button
          onClick={() => setSelectedBus(null)}
          className="text-white/80 hover:text-white"
        >
          <XMarkIcon className="w-5 h-5" />
        </button>
      </div>
      <div className="space-y-2">
        <div className="flex justify-between text-xs">
          <span className="opacity-80">Status</span>
          <span
            className={`font-bold px-2 py-0.5 rounded-lg text-[10px] uppercase border border-white/20 ${status.color.replace("bg-", "bg-opacity-20 ")}`}
          >
            {status.label}
          </span>
        </div>
        <div className="flex justify-between text-xs">
          <span className="opacity-80">Bus Number</span>
          <span className="font-bold">{dynamicBus.busNumber}</span>
        </div>
        <div className="flex justify-between text-xs">
          <span className="opacity-80">Speed</span>
          <span className="font-bold">
            {(dynamicBus.speed || 0).toFixed(2)} km/h
          </span>
        </div>
        <button className="w-full mt-2 bg-white text-[#1E90FF] py-2 rounded-xl text-xs font-bold hover:bg-blue-50 transition-colors">
          View Driver Profile
        </button>
      </div>
    </div>
  );
};

const LiveBusSidebar = ({
  buses,
  searchTerm,
  setSearchTerm,
  selectedBus,
  setSelectedBus,
  getBusStatus,
}) => {
  const activeBuses = buses.filter((b) => b.lastLocation);
  const filteredBuses = activeBuses.filter((b) =>
    b.busNumber.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  return (
    <div className="w-full lg:w-80 h-[400px] lg:h-auto bg-white rounded-2xl border border-gray-200 shadow-sm flex flex-col overflow-hidden">
      <div className="p-4 border-b border-gray-100 bg-gray-50/50">
        <h2 className="font-bold text-gray-800 flex items-center text-sm">
          <TruckIcon className="w-4 h-4 mr-2 text-[#1E90FF]" />
          Active Fleet ({activeBuses.length})
        </h2>
      </div>

      <div className="p-4 border-b border-gray-100">
        <div className="relative">
          <MagnifyingGlassIcon className="w-4 h-4 absolute left-3 top-2.5 text-gray-400" />
          <input
            type="text"
            placeholder="Search bus number..."
            className="w-full pl-9 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-500 outline-none transition-all"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {filteredBuses.length > 0 ? (
          filteredBuses.map((bus) => (
            <LiveBusSidebarItem
              key={bus._id}
              bus={bus}
              selectedBus={selectedBus}
              setSelectedBus={setSelectedBus}
              getBusStatus={getBusStatus}
            />
          ))
        ) : (
          <div className="text-center py-12 text-gray-400">
            <MapPinIcon className="w-8 h-8 mx-auto mb-2 opacity-20" />
            <p className="text-xs">No buses currently active.</p>
          </div>
        )}
      </div>

      {selectedBus && (
        <SelectedBusDetails
          bus={selectedBus}
          setSelectedBus={setSelectedBus}
          getBusStatus={getBusStatus}
        />
      )}
    </div>
  );
};

export default LiveBusSidebar;
