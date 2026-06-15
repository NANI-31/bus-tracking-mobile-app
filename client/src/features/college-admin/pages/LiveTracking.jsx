import React, { useEffect, useState, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Map, useMap, AdvancedMarker, InfoWindow } from "@vis.gl/react-google-maps";
import { getBuses } from "@/features/college-admin/slices/collegeAdminSlice";
import { LiveTrackingProvider, useLiveTracking } from "@/components/common/LiveTrackingContext";
import {
  MapPinIcon,
} from "@heroicons/react/24/outline";

import BusMarker from "../components/LiveTracking/BusMarker";
import LiveBusSidebar from "../components/LiveTracking/LiveBusSidebar";

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

const LiveTrackingContent = () => {
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

  // Auto-fit bounds on initial load of active buses
  useEffect(() => {
    if (map && buses.length > 0) {
      const activeBuses = buses.filter((b) => b.lastLocation);
      if (activeBuses.length > 0) {
        const bounds = new google.maps.LatLngBounds();
        activeBuses.forEach((b) => bounds.extend(b.lastLocation));
        map.fitBounds(bounds);
      }
    }
  }, [map, buses]);

  // Pan to selected bus
  useEffect(() => {
    if (map && selectedBus?.lastLocation) {
      map.panTo(selectedBus.lastLocation);
      if (map.getZoom() < 12) map.setZoom(15);
    }
  }, [map, selectedBus?._id]);

  // Group active buses into clusters based on zoom
  const clusters = useMemo(() => {
    const activeBuses = buses.filter((b) => b.lastLocation);
    const filteredBuses = activeBuses.filter((b) =>
      b.busNumber.toLowerCase().includes(searchTerm.toLowerCase()),
    );
    return getClusters(filteredBuses, zoom);
  }, [buses, searchTerm, zoom]);

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

      <div className="flex flex-col sm:flex-row gap-4 justify-between sm:items-center mb-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-gray-800 tracking-tight">
            Live Fleet Tracking
          </h1>
          <p className="text-gray-500 text-xs sm:text-sm">
            Real-time monitoring via Google Maps (Performance Isolated & Clustered)
          </p>
        </div>
        <div className="flex space-x-2 w-fit">
          <div className={`flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${
            isOnline 
              ? "bg-green-100 text-green-700 border-green-200 animate-pulse" 
              : "bg-amber-100 text-amber-700 border-amber-200"
          }`}>
            <div className={`w-2 h-2 rounded-full mr-2 ${isOnline ? "bg-green-500" : "bg-amber-500"}`}></div>
            {isOnline ? "Live System" : "Offline"}
          </div>
        </div>
      </div>

      <div className="flex-1 flex flex-col lg:flex-row gap-4 overflow-visible lg:overflow-hidden">
        {/* Map Container */}
        <div className="w-full h-[400px] lg:h-auto lg:flex-1 relative rounded-2xl overflow-hidden border border-gray-200 shadow-sm">
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
                  <p className="font-bold text-gray-800 text-sm">
                    Bus {selectedBus.busNumber}
                  </p>
                  <p className="text-[10px] text-gray-500">
                    {(selectedBus.speed || 0).toFixed(2)} km/h
                  </p>
                </div>
              </InfoWindow>
            )}
          </Map>
        </div>

        {/* Info Sidebar */}
        <LiveBusSidebar
          buses={buses}
          searchTerm={searchTerm}
          setSearchTerm={setSearchTerm}
          selectedBus={selectedBus}
          setSelectedBus={setSelectedBus}
          getBusStatus={getBusStatus}
        />
      </div>
    </div>
  );
};

const LiveTracking = () => {
  const { userToken, userInfo } = useSelector((state) => state.auth);

  return (
    <LiveTrackingProvider
      collegeId={userInfo?.collegeId}
      userToken={userToken}
      mode="college"
    >
      <LiveTrackingContent />
    </LiveTrackingProvider>
  );
};

export default LiveTracking;
