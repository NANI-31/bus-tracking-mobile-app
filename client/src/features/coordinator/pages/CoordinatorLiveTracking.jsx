
import React, { useEffect, useState, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Map, useMap, AdvancedMarker, InfoWindow } from "@vis.gl/react-google-maps";
import { getBuses } from "@/features/college-admin/slices/collegeAdminSlice";
import { LiveTrackingProvider, useLiveTracking } from "@/components/common/LiveTrackingContext";
import {
  MapPinIcon,
  TruckIcon,
  MagnifyingGlassIcon,
  BoltIcon,
  ClockIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
// Simple clustering helper
const getClusters = (buses, zoom) => {
  if (zoom >= 12) {
    return buses.map((bus) => ({
      id: `single-${bus._id}`,
      center: bus.lastLocation,
      buses: [bus],
      isCluster: false,
    }));
  }
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
      <div className={`${size} rounded-full bg-blue-600 border-2 border-white text-white flex items-center justify-center font-bold shadow-lg cursor-pointer transition-transform hover:scale-110`}>
        {count}
      </div>
    </AdvancedMarker>
  );
};
const LiveBusMarker = ({ bus, onClick }) => {
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
      <div className="w-8 h-8 transition-transform hover:scale-110 cursor-pointer" style={{ transform: `rotate(${rotation}deg)` }}>
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" fill="white" stroke="#1E90FF" strokeWidth="2.5" />
          <path d="M12 6L7 15H17L12 6Z" fill="#1E90FF" />
        </svg>
      </div>
    </AdvancedMarker>
  );
};
const LiveSidebarItem = ({ bus, selectedBus, setSelectedBus }) => {
  const { subscribeToBus } = useLiveTracking();
  const [locationData, setLocationData] = useState(() => bus.lastLocation || null);
  useEffect(() => {
    const unsubscribe = subscribeToBus(bus._id, (newLoc) => {
      setLocationData(newLoc);
    });
    return unsubscribe;
  }, [bus._id, subscribeToBus]);
  const speed = locationData?.speed ?? bus.speed ?? 0;
  const delay = locationData?.delay ?? bus.delay ?? 0;
  const isSelected = selectedBus?._id === bus._id;
  const getStatus = () => {
    if (!locationData || !locationData.timestamp) {
      return { label: "Not Live", color: "bg-slate-500/10 text-slate-400 border-slate-500/20" };
    }
    const lastUpdate = new Date(locationData.timestamp).getTime();
    const diff = (Date.now() - lastUpdate) / 1000 / 60;
    if (diff > 5) {
      return { label: "Offline", color: "bg-slate-500/10 text-slate-400 border-slate-500/20" };
    }
    if (speed > 2) {
      return { label: "Running", color: "bg-emerald-500/10 text-emerald-500 border-emerald-500/20 animate-pulse" };
    }
    return { label: "Idle", color: "bg-amber-500/10 text-amber-500 border-amber-500/20" };
  };
  const status = getStatus();
  return (
    <button
      onClick={() => setSelectedBus({ ...bus, lastLocation: locationData, speed, delay })}
      className={`w-full text-left p-3.5 rounded-2xl border transition-all ${
        isSelected
          ? "border-primary-main bg-primary-main/5 shadow-xs"
          : "border-border-theme/40 bg-background-paper hover:bg-background-default/50 text-text-theme-primary"
      }`}
    >
      <div className="flex justify-between items-start mb-1.5">
        <span className="font-extrabold text-xs text-text-theme-primary">
          Bus {bus.busNumber}
        </span>
        <span className={`text-[9px] font-black uppercase tracking-wider px-2 py-0.5 rounded-lg border ${status.color}`}>
          {status.label}
        </span>
      </div>
      <div className="grid grid-cols-2 gap-2 text-[10px] text-text-theme-secondary font-semibold">
        <div className="flex items-center">
          <BoltIcon className="w-3.5 h-3.5 mr-1 text-text-theme-secondary" />
          {speed.toFixed(1)} km/h
        </div>
        <div className="flex items-center">
          <ClockIcon className="w-3.5 h-3.5 mr-1 text-text-theme-secondary" />
          {delay}m delay
        </div>
      </div>
    </button>
  );
};
const LiveSidebar = ({ buses, searchTerm, setSearchTerm, selectedBus, setSelectedBus }) => {
  const filteredBuses = buses.filter((b) =>
    b.busNumber.toLowerCase().includes(searchTerm.toLowerCase())
  );
  return (
    <div className="w-full lg:w-80 h-[350px] lg:h-auto bg-background-paper rounded-3xl border border-border-theme/40 shadow-xs flex flex-col overflow-hidden">
      <div className="p-4 border-b border-border-theme/40 bg-background-default/20">
        <h2 className="font-black text-text-theme-primary flex items-center text-xs uppercase tracking-wider">
          <TruckIcon className="w-4.5 h-4.5 mr-2 text-primary-main" />
          Live Fleet ({buses.length})
        </h2>
      </div>
      <div className="p-3 border-b border-border-theme/40">
        <div className="relative">
          <MagnifyingGlassIcon className="w-4 h-4 absolute left-3 top-3 text-text-theme-secondary" />
          <input
            type="text"
            placeholder="Search active bus..."
            className="w-full pl-9 pr-4 py-2 bg-background-default border border-border-theme rounded-xl text-xs font-semibold focus:border-primary-main outline-none transition-all"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>
      <div className="flex-1 overflow-y-auto p-3.5 space-y-3.5">
        {filteredBuses.length > 0 ? (
          filteredBuses.map((bus) => (
            <LiveSidebarItem
              key={bus._id}
              bus={bus}
              selectedBus={selectedBus}
              setSelectedBus={setSelectedBus}
            />
          ))
        ) : (
          <div className="text-center py-12 text-text-theme-secondary">
            <MapPinIcon className="w-8 h-8 mx-auto mb-2 opacity-25" />
            <p className="text-xs font-semibold">No active routes found</p>
          </div>
        )}
      </div>
      {selectedBus && (
        <div className="p-4 bg-primary-main text-white rounded-t-3xl shadow-2xl">
          <div className="flex justify-between items-center mb-3">
            <h3 className="font-black text-xs uppercase tracking-wider">Selected Vehicle</h3>
            <button onClick={() => setSelectedBus(null)} className="text-white/80 hover:text-white p-0.5 rounded-lg hover:bg-white/10">
              <XMarkIcon className="w-5 h-5" />
            </button>
          </div>
          <div className="space-y-1.5 text-xs">
            <div className="flex justify-between">
              <span className="opacity-80">Bus Number</span>
              <span className="font-extrabold">Bus {selectedBus.busNumber}</span>
            </div>
            <div className="flex justify-between">
              <span className="opacity-80">Velocity</span>
              <span className="font-extrabold">{(selectedBus.speed || 0).toFixed(1)} km/h</span>
            </div>
            <div className="flex justify-between">
              <span className="opacity-80">Schedule Delay</span>
              <span className="font-extrabold">{selectedBus.delay || 0} minutes</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
const CoordinatorLiveTrackingContent = () => {
  const dispatch = useDispatch();
  const { buses } = useSelector((state) => state.collegeAdmin);
  const { isOnline } = useLiveTracking();
  const [selectedBus, setSelectedBus] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [zoom, setZoom] = useState(5);
  const map = useMap();
  useEffect(() => {
    dispatch(getBuses());
  }, [dispatch]);
  // Track map zoom
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
  // Center on selected bus
  useEffect(() => {
    if (map && selectedBus?.lastLocation) {
      map.panTo(selectedBus.lastLocation);
      if (map.getZoom() < 12) map.setZoom(15);
    }
  }, [map, selectedBus?._id]);
  // Filter to only accepted buses
  const acceptedBuses = useMemo(() => {
    return (Array.isArray(buses) ? buses : []).filter(
      (b) => b.assignmentStatus === "accepted"
    );
  }, [buses]);
  // Auto-fit bounds
  useEffect(() => {
    if (map && acceptedBuses.length > 0) {
      const activeWithLocation = acceptedBuses.filter((b) => b.lastLocation);
      if (activeWithLocation.length > 0) {
        const bounds = new google.maps.LatLngBounds();
        activeWithLocation.forEach((b) => bounds.extend(b.lastLocation));
        map.fitBounds(bounds);
      }
    }
  }, [map, acceptedBuses]);
  // Group active buses into clusters based on zoom
  const clusters = useMemo(() => {
    const activeWithLocation = acceptedBuses.filter((b) => b.lastLocation);
    const filtered = activeWithLocation.filter((b) =>
      b.busNumber.toLowerCase().includes(searchTerm.toLowerCase())
    );
    return getClusters(filtered, zoom);
  }, [acceptedBuses, searchTerm, zoom]);
  const handleClusterClick = (cluster) => {
    if (map) {
      map.panTo(cluster.center);
      map.setZoom(Math.min(map.getZoom() + 3, 15));
    }
  };
  return (
    <div className="h-auto lg:h-[calc(100vh-140px)] flex flex-col space-y-4 -m-6 p-6">
      {/* Offline Status Banner */}
      <div className={`transition-all duration-300 overflow-hidden ${!isOnline ? "max-h-16 opacity-100" : "max-h-0 opacity-0"}`}>
        <div className="bg-amber-500 text-white px-4 py-3 rounded-2xl flex items-center justify-between shadow-xs border border-amber-600 text-xs font-bold uppercase tracking-wider">
          <span>Connection Lost — Displaying cached vehicle positions. Reconnecting...</span>
        </div>
      </div>
      <div className="flex flex-col sm:flex-row gap-4 justify-between sm:items-center">
        <div>
          <h1 className="text-xl sm:text-2xl font-black text-text-theme-primary tracking-tight">
            Live Fleet Tracking Map
          </h1>
          <p className="text-text-theme-secondary text-xs sm:text-sm font-semibold">
            Track and monitor assigned drivers and routes in real-time
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className={`flex items-center px-3.5 py-1.5 rounded-full text-xs font-black border uppercase tracking-wider ${
            isOnline 
              ? "bg-green-500/10 text-green-500 border-green-500/20" 
              : "bg-amber-500/10 text-amber-500 border-amber-500/20"
          }`}>
            <span className={`w-2 h-2 rounded-full mr-2 ${isOnline ? "bg-green-500 animate-pulse" : "bg-amber-500"}`} />
            {isOnline ? "Live Network Connection" : "Offline Mode"}
          </div>
        </div>
      </div>
      <div className="flex-1 flex flex-col lg:flex-row gap-6 overflow-visible lg:overflow-hidden">
        {/* Map Container */}
        <div className="w-full h-[400px] lg:h-auto lg:flex-1 relative rounded-3xl overflow-hidden border border-border-theme/40 shadow-xs bg-slate-900">
          <Map
            defaultCenter={{ lat: 20.5937, lng: 78.9629 }}
            defaultZoom={5}
            mapId="bf51a910020fa566"
            disableDefaultUI={true}
            zoomControl={true}
          >
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
                <LiveBusMarker
                  key={bus._id}
                  bus={bus}
                  onClick={setSelectedBus}
                />
              );
            })}
            {selectedBus && selectedBus.lastLocation && (
              <InfoWindow
                position={{
                  lat: selectedBus.lastLocation.lat,
                  lng: selectedBus.lastLocation.lng,
                }}
                onCloseClick={() => setSelectedBus(null)}
              >
                <div className="p-1">
                  <p className="font-extrabold text-slate-800 text-xs">
                    Bus {selectedBus.busNumber}
                  </p>
                  <p className="text-[10px] text-slate-500 font-semibold mt-0.5">
                    {(selectedBus.speed || 0).toFixed(1)} km/h
                  </p>
                </div>
              </InfoWindow>
            )}
          </Map>
        </div>
        {/* Info Sidebar */}
        <LiveSidebar
          buses={acceptedBuses}
          searchTerm={searchTerm}
          setSearchTerm={setSearchTerm}
          selectedBus={selectedBus}
          setSelectedBus={setSelectedBus}
        />
      </div>
    </div>
  );
};
const CoordinatorLiveTracking = () => {
  const { userToken, userInfo } = useSelector((state) => state.auth);
  return (
    <LiveTrackingProvider
      collegeId={userInfo?.collegeId}
      userToken={userToken}
      mode="college"
    >
      <CoordinatorLiveTrackingContent />
    </LiveTrackingProvider>
  );
};
export default CoordinatorLiveTracking;
