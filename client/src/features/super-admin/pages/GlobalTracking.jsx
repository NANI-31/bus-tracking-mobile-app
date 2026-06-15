import React, { useEffect, useState, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Map, useMap, AdvancedMarker, InfoWindow } from "@vis.gl/react-google-maps";
import { getGlobalBuses, getColleges } from "../slices/superAdminSlice";
import { LiveTrackingProvider, useLiveTracking } from "@/components/common/LiveTrackingContext";
import {
  TruckIcon,
  MapPinIcon,
  ClockIcon,
  BoltIcon,
  XMarkIcon,
  AcademicCapIcon,
  MagnifyingGlassIcon,
} from "@heroicons/react/24/outline";

// Distance-based simple clustering helper
const getClusters = (buses, zoom) => {
  if (zoom >= 12) {
    return buses.map((bus) => ({
      id: `single-${bus._id}`,
      center: bus.lastLocation,
      buses: [bus],
      isCluster: false,
    }));
  }

  // Determine distance threshold in degrees depending on zoom
  const threshold = 1.2 / Math.pow(2, zoom);
  const clusters = [];

  buses.forEach((bus) => {
    if (!bus.lastLocation) return;
    const { lat, lng } = bus.lastLocation;

    let foundCluster = null;
    for (const c of clusters) {
      const latDiff = Math.abs(c.center.lat - lat);
      const lngDiff = Math.abs(c.center.lng - lng);
      if (latDiff < threshold && lngDiff < threshold) {
        foundCluster = c;
        break;
      }
    }

    if (foundCluster) {
      foundCluster.buses.push(bus);
      const count = foundCluster.buses.length;
      foundCluster.center = {
        lat: (foundCluster.center.lat * (count - 1) + lat) / count,
        lng: (foundCluster.center.lng * (count - 1) + lng) / count,
      };
    } else {
      clusters.push({
        id: `cluster-${bus._id}`,
        center: { lat, lng },
        buses: [bus],
        isCluster: true,
      });
    }
  });

  return clusters.map((c) => {
    if (c.buses.length === 1) {
      return {
        id: `single-${c.buses[0]._id}`,
        center: c.buses[0].lastLocation,
        buses: c.buses,
        isCluster: false,
      };
    }
    return c;
  });
};

const ClusterMarker = ({ cluster, onClick }) => {
  const count = cluster.buses.length;
  const size = count > 10 ? "w-10 h-10 text-sm" : "w-8 h-8 text-xs";

  return (
    <AdvancedMarker position={cluster.center} onClick={() => onClick(cluster)}>
      <div 
        className={`${size} rounded-full bg-blue-600 border-2 border-white text-white flex items-center justify-center font-bold shadow-lg cursor-pointer cluster-marker-inner`}
        style={{
          animation: "clusterScaleIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1) forwards",
        }}
      >
        <style dangerouslySetInnerHTML={{__html: `
          @keyframes clusterScaleIn {
            0% { opacity: 0; transform: scale(0.4); }
            100% { opacity: 1; transform: scale(1); }
          }
          .cluster-marker-inner {
            transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1) !important;
          }
          .cluster-marker-inner:hover {
            transform: scale(1.15) !important;
          }
        `}} />
        {count}
      </div>
    </AdvancedMarker>
  );
};

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
  const { subscribeToBus } = useLiveTracking();
  const [locationData, setLocationData] = useState(() => bus.lastLocation || null);

  useEffect(() => {
    const unsubscribe = subscribeToBus(bus._id, (newLoc) => {
      setLocationData(newLoc);
    });
    return unsubscribe;
  }, [bus._id, subscribeToBus]);

  if (!locationData) return null;

  const rotation = locationData.heading || 0;

  const handleMarkerClick = () => {
    onClick({
      ...bus,
      lastLocation: locationData,
      speed: locationData.speed,
      heading: locationData.heading,
      delay: locationData.delay,
    });
  };

  return (
    <AdvancedMarker
      position={{ lat: locationData.lat, lng: locationData.lng }}
      onClick={handleMarkerClick}
    >
      <div
        style={{
          width: "32px",
          height: "32px",
          animation: "markerScaleIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1) forwards",
        }}
      >
        <style dangerouslySetInnerHTML={{__html: `
          @keyframes markerScaleIn {
            0% { opacity: 0; transform: scale(0.4); }
            100% { opacity: 1; transform: scale(1); }
          }
          .bus-marker-rotate {
            transition: transform 0.3s ease-in-out, filter 0.2s ease !important;
          }
          .bus-marker-rotate:hover {
            transform: rotate(var(--rotation)) scale(1.2) !important;
            filter: drop-shadow(0 4px 6px rgba(59, 130, 246, 0.4));
          }
        `}} />
        <div
          className="bus-marker-rotate"
          style={{
            transform: `rotate(${rotation}deg)`,
            "--rotation": `${rotation}deg`,
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
      </div>
    </AdvancedMarker>
  );
};

const GlobalBusSidebarItem = ({
  bus,
  selectedBus,
  setSelectedBus,
  colleges,
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
          ? "border-[#1E90FF] bg-indigo-50/50 shadow-sm"
          : "border-slate-100 hover:border-slate-300 hover:bg-slate-50"
      }`}
    >
      <div className="flex justify-between items-start mb-1">
        <div className="flex flex-col">
          <span className="font-bold text-slate-800 text-xs">
            Bus {bus.busNumber}
          </span>
          <span className="text-[9px] text-slate-400">
            {colleges.find((c) => c._id === bus.collegeId)?.name || "Unknown"}
          </span>
        </div>
        <span
          className={`text-[9px] font-bold uppercase px-1.5 py-0.5 rounded-md ${status.color}`}
        >
          {status.label}
        </span>
      </div>
      <div className="grid grid-cols-2 gap-2 text-[10px] text-slate-500 mt-2">
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

const GlobalSelectedBusDetails = ({
  bus,
  setSelectedBus,
  colleges,
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

  return (
    <div className="p-4 bg-slate-900 text-white rounded-t-2xl">
      <div className="flex justify-between items-center mb-3">
        <h3 className="font-bold text-sm text-indigo-400">System Details</h3>
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
            {colleges.find((c) => c._id === dynamicBus.collegeId)?.name || "Unknown"}
          </span>
        </div>
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
          <span className="font-bold text-indigo-400">
            {dynamicBus.busNumber}
          </span>
        </div>
        <div className="flex justify-between text-xs">
          <span className="opacity-80">Speed</span>
          <span className="font-bold">
            {(dynamicBus.speed || 0).toFixed(2)} km/h
          </span>
        </div>
        <button className="w-full mt-2 bg-[#1E90FF] text-white py-2 rounded-xl text-xs font-bold hover:bg-indigo-700 transition-colors">
          Contact Coordinator
        </button>
      </div>
    </div>
  );
};

const GlobalTrackingContent = () => {
  const dispatch = useDispatch();
  const { buses, colleges } = useSelector((state) => state.superAdmin);
  const { isOnline } = useLiveTracking();
  const [selectedBus, setSelectedBus] = useState(null);
  const [selectedCollegeId, setSelectedCollegeId] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");
  const [zoom, setZoom] = useState(5);
  const map = useMap();

  useEffect(() => {
    dispatch(getGlobalBuses());
    dispatch(getColleges());
  }, [dispatch]);

  // Track map zoom level
  useEffect(() => {
    if (!map) return;
    setZoom(map.getZoom() || 5);

    const listener = map.addListener("zoom_changed", () => {
      setZoom(map.getZoom());
    });
    return () => {
      google.maps.event.removeListener(listener);
    };
  }, [map]);

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

  // Group active buses into clusters based on zoom
  const clusters = useMemo(() => {
    return getClusters(filteredBuses, zoom);
  }, [filteredBuses, zoom]);

  const handleClusterClick = (cluster) => {
    if (map) {
      map.panTo(cluster.center);
      map.setZoom(Math.min(map.getZoom() + 3, 15));
    }
  };

  return (
    <div className="h-auto lg:h-[calc(100vh-140px)] flex flex-col">
      {/* Offline Status Banner */}
      <div
        className={`transition-all duration-300 overflow-hidden ${
          !isOnline ? "max-h-16 opacity-100 mb-4" : "max-h-0 opacity-0"
        }`}
      >
        <div className="bg-amber-500 text-white px-4 py-3 rounded-xl flex items-center justify-between shadow-sm border border-amber-600">
          <div className="flex items-center space-x-2">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-white"></span>
            </span>
            <span className="font-semibold text-xs uppercase tracking-wider">
              Connection Lost — Showing Last Cached Location. Reconnecting...
            </span>
          </div>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-4 justify-between lg:items-center bg-white p-4 rounded-xl shadow-sm border border-slate-200 mb-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-slate-800 tracking-tight flex items-center">
            <MapPinIcon className="w-6 h-6 sm:w-8 sm:h-8 mr-2 text-[#1E90FF]" />
            Global Fleet Tracking
          </h1>
          <p className="text-slate-500 text-xs sm:text-sm">
            Cross-college real-time monitoring (Performance Isolated & Clustered)
          </p>
        </div>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center w-full lg:w-auto">
          <div className="flex items-center space-x-2 w-full sm:w-auto">
            <AcademicCapIcon className="w-5 h-5 text-slate-400 shrink-0" />
            <select
              value={selectedCollegeId}
              onChange={(e) => setSelectedCollegeId(e.target.value)}
              className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm focus:ring-2 focus:ring-[#1E90FF] outline-none w-full sm:w-auto cursor-pointer"
            >
              <option value="all">All Colleges</option>
              {colleges.map((c) => (
                <option key={c._id} value={c._id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
          <div className={`flex items-center justify-center px-3 py-1.5 rounded-full text-xs font-semibold border w-full sm:w-auto ${
            isOnline 
              ? "bg-indigo-100 text-indigo-700 border-indigo-200 animate-pulse" 
              : "bg-amber-100 text-amber-700 border-amber-200"
          }`}>
            <div className={`w-2 h-2 rounded-full mr-2 ${isOnline ? "bg-[#1E90FF]" : "bg-amber-500"}`}></div>
            {isOnline ? "Global Sync Active" : "Offline"}
          </div>
        </div>
      </div>

      <div className="flex-1 flex flex-col lg:flex-row gap-4 overflow-visible lg:overflow-hidden">
        <div className="w-full h-[400px] lg:h-auto lg:flex-1 relative rounded-2xl overflow-hidden border border-slate-200 shadow-sm bg-white p-2">
          <Map
            defaultCenter={{ lat: 20.5937, lng: 78.9629 }}
            defaultZoom={5}
            mapId="bf51a910020fa566"
            disableDefaultUI={true}
            zoomControl={true}
          >
            {/* Clustered or Single Markers */}
            {clusters.map((cluster) => {
              if (cluster.isCluster) {
                return (
                  <ClusterMarker
                    key={cluster.id}
                    cluster={cluster}
                    onClick={handleClusterClick}
                  />
                );
              }
              const bus = cluster.buses[0];
              return (
                <BusMarker key={bus._id} bus={bus} onClick={setSelectedBus} />
              );
            })}

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

        <div className="w-full lg:w-80 h-[400px] lg:h-auto bg-white rounded-2xl border border-slate-200 shadow-sm flex flex-col overflow-hidden">
          <div className="p-4 border-b border-slate-100 bg-slate-50/50">
            <h2 className="font-bold text-slate-800 flex items-center text-sm">
              <TruckIcon className="w-4 h-4 mr-2 text-[#1E90FF]" />
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
                className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-[#1E90FF] outline-none transition-all"
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
                  <GlobalBusSidebarItem
                    key={bus._id}
                    bus={bus}
                    selectedBus={selectedBus}
                    setSelectedBus={setSelectedBus}
                    colleges={colleges}
                    getBusStatus={getBusStatus}
                  />
                ))
            ) : (
              <div className="text-center py-12 text-slate-400">
                <MapPinIcon className="w-8 h-8 mx-auto mb-2 opacity-20" />
                <p className="text-xs">No active buses detected.</p>
              </div>
            )}
          </div>

          {selectedBus && (
            <GlobalSelectedBusDetails
              bus={selectedBus}
              setSelectedBus={setSelectedBus}
              colleges={colleges}
              getBusStatus={getBusStatus}
            />
          )}
        </div>
      </div>
    </div>
  );
};

const GlobalTracking = () => {
  const { userToken } = useSelector((state) => state.auth);

  return (
    <LiveTrackingProvider userToken={userToken} mode="global">
      <GlobalTrackingContent />
    </LiveTrackingProvider>
  );
};

export default GlobalTracking;
