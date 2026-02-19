import React, { useEffect, useState, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  Map,
  useMap,
  AdvancedMarker,
  InfoWindow,
} from "@vis.gl/react-google-maps";
import {
  getGlobalBuses,
  updateGlobalBusLocation,
  getColleges,
} from "../slices/superAdminSlice";
import { initiateSocketConnection } from "../../../services/socket";
import {
  TruckIcon,
  MapPinIcon,
  ClockIcon,
  BoltIcon,
  XMarkIcon,
  AcademicCapIcon,
  MagnifyingGlassIcon,
} from "@heroicons/react/24/outline";

const getBusStatus = (bus) => {
  if (!bus.lastLocation || !bus.lastLocation.timestamp) {
    return { label: "Not Running", color: "bg-gray-100 text-gray-600" };
  }

  const lastUpdate = new Date(bus.lastLocation.timestamp).getTime();
  const now = Date.now();
  const diffInMinutes = (now - lastUpdate) / 1000 / 60;

  if (diffInMinutes > 5) {
    return { label: "Not Running", color: "bg-gray-400 text-white" };
  }

  if (bus.speed > 2) {
    if (bus.delay > 10) {
      return { label: "Delayed", color: "bg-red-100 text-red-700" };
    }
    return { label: "On Time", color: "bg-green-100 text-green-700" };
  }

  return { label: "Stationary", color: "bg-amber-100 text-amber-700" };
};

const BusMarker = ({ bus, onClick }) => {
  const rotation = bus.heading || 0;

  return (
    <AdvancedMarker
      position={{ lat: bus.lastLocation.lat, lng: bus.lastLocation.lng }}
      onClick={() => onClick(bus)}
    >
      <div
        style={{
          transform: `rotate(${rotation}deg)`,
          transition: "transform 0.3s ease-in-out",
          width: "32px",
          height: "32px",
        }}
      >
        <svg
          width="32"
          height="32"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <circle
            cx="12"
            cy="12"
            r="10"
            fill="white"
            stroke="#3B82F6"
            strokeWidth="2"
          />
          <path d="M12 6L8 14H16L12 6Z" fill="#3B82F6" />
        </svg>
      </div>
    </AdvancedMarker>
  );
};

const GlobalTracking = () => {
  const dispatch = useDispatch();
  const { buses, colleges } = useSelector((state) => state.superAdmin);
  const { userToken, userInfo } = useSelector((state) => state.auth);
  const [selectedBus, setSelectedBus] = useState(null);
  const [selectedCollegeId, setSelectedCollegeId] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");
  const map = useMap();

  useEffect(() => {
    dispatch(getGlobalBuses());
    dispatch(getColleges());

    if (userToken) {
      const socket = initiateSocketConnection(userToken);

      // Super Admin joins global room or all individual rooms
      // For now, let's assume server will be updated to support 'global_tracking'
      socket.emit("join_global_tracking");

      socket.on("location_updated", (data) => {
        dispatch(updateGlobalBusLocation(data));
      });

      return () => {
        socket.off("location_updated");
      };
    }
  }, [dispatch, userToken]);

  const filteredBuses = useMemo(() => {
    let result = buses;
    if (selectedCollegeId !== "all") {
      result = result.filter((b) => b.collegeId === selectedCollegeId);
    }
    if (searchTerm) {
      result = result.filter((b) =>
        b.busNumber.toLowerCase().includes(searchTerm.toLowerCase()),
      );
    }
    return result;
  }, [buses, selectedCollegeId, searchTerm]);

  useEffect(() => {
    if (map && filteredBuses.length > 0) {
      const activeBuses = filteredBuses.filter((b) => b.lastLocation);
      if (activeBuses.length > 0) {
        const bounds = new google.maps.LatLngBounds();
        activeBuses.forEach((b) => bounds.extend(b.lastLocation));
        map.fitBounds(bounds);
      }
    }
  }, [map, filteredBuses.length]);

  // Pan to selected bus
  useEffect(() => {
    if (map && selectedBus?.lastLocation) {
      map.panTo(selectedBus.lastLocation);
      if (map.getZoom() < 12) map.setZoom(15);
    }
  }, [map, selectedBus?._id]);

  return (
    <div className="h-[calc(100vh-140px)] flex flex-col space-y-4">
      <div className="flex justify-between items-center bg-white p-4 rounded-xl shadow-sm border border-slate-200">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight flex items-center">
            <MapPinIcon className="w-8 h-8 mr-2 text-indigo-600" />
            Global Fleet Tracking
          </h1>
          <p className="text-slate-500 text-sm">
            Cross-college real-time monitoring
          </p>
        </div>
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <AcademicCapIcon className="w-5 h-5 text-slate-400" />
            <select
              value={selectedCollegeId}
              onChange={(e) => setSelectedCollegeId(e.target.value)}
              className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
            >
              <option value="all">All Colleges</option>
              {colleges.map((c) => (
                <option key={c._id} value={c._id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
          <div className="flex items-center px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-xs font-semibold animate-pulse border border-indigo-200">
            <div className="w-2 h-2 bg-indigo-500 rounded-full mr-2"></div>
            Global Sync Active
          </div>
        </div>
      </div>

      <div className="flex-1 flex gap-4 overflow-hidden">
        <div className="flex-1 relative rounded-2xl overflow-hidden border border-slate-200 shadow-sm bg-white p-2">
          <Map
            defaultCenter={{ lat: 20.5937, lng: 78.9629 }}
            defaultZoom={5}
            mapId="bf51a910020fa566"
            disableDefaultUI={true}
            zoomControl={true}
          >
            {filteredBuses
              ?.filter((b) => b.lastLocation)
              .map((bus) => (
                <BusMarker key={bus._id} bus={bus} onClick={setSelectedBus} />
              ))}

            {selectedBus && (
              <InfoWindow
                position={{
                  lat: selectedBus.lastLocation.lat,
                  lng: selectedBus.lastLocation.lng,
                }}
                onCloseClick={() => setSelectedBus(null)}
              >
                <div className="p-1">
                  <p className="font-bold text-slate-800 text-sm">
                    Bus {selectedBus.busNumber}
                  </p>
                  <p className="text-[10px] text-slate-500">
                    {(selectedBus.speed || 0).toFixed(2)} km/h
                  </p>
                </div>
              </InfoWindow>
            )}
          </Map>
        </div>

        <div className="w-80 bg-white rounded-2xl border border-slate-200 shadow-sm flex flex-col overflow-hidden">
          <div className="p-4 border-b border-slate-100 bg-slate-50/50">
            <h2 className="font-bold text-slate-800 flex items-center text-sm">
              <TruckIcon className="w-4 h-4 mr-2 text-indigo-600" />
              Active Global Fleet (
              {filteredBuses.filter((b) => b.lastLocation).length})
            </h2>
          </div>

          <div className="p-4 border-b border-slate-100">
            <div className="relative">
              <MagnifyingGlassIcon className="w-4 h-4 absolute left-3 top-2.5 text-slate-400" />
              <input
                type="text"
                placeholder="Search bus number..."
                className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {filteredBuses?.filter((b) => b.lastLocation).length > 0 ? (
              filteredBuses
                .filter((b) => b.lastLocation)
                .map((bus) => (
                  <button
                    key={bus._id}
                    onClick={() => setSelectedBus(bus)}
                    className={`w-full text-left p-3 rounded-xl border transition-all ${
                      selectedBus?._id === bus._id
                        ? "border-indigo-500 bg-indigo-50/50 shadow-sm"
                        : "border-slate-100 hover:border-slate-300 hover:bg-slate-50"
                    }`}
                  >
                    <div className="flex justify-between items-start mb-1">
                      <div className="flex flex-col">
                        <span className="font-bold text-slate-800 text-xs">
                          Bus {bus.busNumber}
                        </span>
                        <span className="text-[9px] text-slate-400">
                          {colleges.find((c) => c._id === bus.collegeId)
                            ?.name || "Unknown"}
                        </span>
                      </div>
                      <span
                        className={`text-[9px] font-bold uppercase px-1.5 py-0.5 rounded-md ${getBusStatus(bus).color}`}
                      >
                        {getBusStatus(bus).label}
                      </span>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-[10px] text-slate-500 mt-2">
                      <div className="flex items-center">
                        <BoltIcon className="w-3 h-3 mr-1" />
                        {(bus.speed || 0).toFixed(2)} km/h
                      </div>
                      <div className="flex items-center">
                        <ClockIcon className="w-3 h-3 mr-1" />
                        {bus.delay || 0}m delay
                      </div>
                    </div>
                  </button>
                ))
            ) : (
              <div className="text-center py-12 text-slate-400">
                <MapPinIcon className="w-8 h-8 mx-auto mb-2 opacity-20" />
                <p className="text-xs">No active buses detected.</p>
              </div>
            )}
          </div>

          {selectedBus && (
            <div className="p-4 bg-slate-900 text-white rounded-t-2xl">
              <div className="flex justify-between items-center mb-3">
                <h3 className="font-bold text-sm text-indigo-400">
                  System Details
                </h3>
                <button
                  onClick={() => setSelectedBus(null)}
                  className="text-slate-400 hover:text-white"
                >
                  <XMarkIcon className="w-5 h-5" />
                </button>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-xs">
                  <span className="opacity-80">College</span>
                  <span className="font-bold">
                    {colleges.find((c) => c._id === selectedBus.collegeId)
                      ?.name || "Unknown"}
                  </span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="opacity-80">Status</span>
                  <span
                    className={`font-bold px-2 py-0.5 rounded-lg text-[10px] uppercase border border-white/20 ${getBusStatus(selectedBus).color.replace("bg-", "bg-opacity-20 ")}`}
                  >
                    {getBusStatus(selectedBus).label}
                  </span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="opacity-80">Bus Number</span>
                  <span className="font-bold text-indigo-400">
                    {selectedBus.busNumber}
                  </span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="opacity-80">Speed</span>
                  <span className="font-bold">
                    {(selectedBus.speed || 0).toFixed(2)} km/h
                  </span>
                </div>
                <button className="w-full mt-2 bg-indigo-600 text-white py-2 rounded-xl text-xs font-bold hover:bg-indigo-700 transition-colors">
                  Contact Coordinator
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default GlobalTracking;
