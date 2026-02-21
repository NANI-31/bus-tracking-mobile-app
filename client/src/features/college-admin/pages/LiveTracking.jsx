import React, { useEffect, useState, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  Map,
  useMap,
  AdvancedMarker,
  InfoWindow,
  ControlPosition,
  MapControl,
} from "@vis.gl/react-google-maps";
import {
  getBuses,
  updateBusLocation,
} from "@/features/college-admin/slices/collegeAdminSlice";
import { initiateSocketConnection, joinRoom } from "@/services/socket";
import {
  TruckIcon,
  MapPinIcon,
  ClockIcon,
  BoltIcon,
  XMarkIcon,
  MagnifyingGlassIcon,
} from "@heroicons/react/24/outline";

import BusMarker from "../components/LiveTracking/BusMarker";
import LiveBusSidebar from "../components/LiveTracking/LiveBusSidebar";

const getBusStatus = (bus) => {
  if (!bus.lastLocation || !bus.lastLocation.timestamp) {
    return { label: "Not Running", color: "bg-gray-100 text-gray-600" };
  }

  const lastUpdate = new Date(bus.lastLocation.timestamp).getTime();
  const now = Date.now();
  const diffInMinutes = (now - lastUpdate) / 1000 / 60;

  // If no update in last 5 minutes, consider it not running
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

const LiveTracking = () => {
  const dispatch = useDispatch();
  const { buses, routes } = useSelector((state) => state.collegeAdmin);
  const { userToken, userInfo } = useSelector((state) => state.auth);
  const [selectedBus, setSelectedBus] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");
  const map = useMap();

  useEffect(() => {
    dispatch(getBuses());

    if (userToken && userInfo?.collegeId) {
      const socket = initiateSocketConnection(userToken);
      joinRoom("join_college", userInfo.collegeId);

      socket.on("location_updated", (data) => {
        dispatch(updateBusLocation(data));
      });

      return () => {
        socket.off("location_updated");
      };
    }
  }, [dispatch, userToken, userInfo?.collegeId]);

  // Auto-fit bounds when buses load
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

  return (
    <div className="h-[calc(100vh-140px)] flex flex-col space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 tracking-tight">
            Live Fleet Tracking
          </h1>
          <p className="text-gray-500 text-sm">
            Real-time monitoring via Google Maps
          </p>
        </div>
        <div className="flex space-x-2">
          <div className="flex items-center px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-semibold animate-pulse">
            <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
            Live System
          </div>
        </div>
      </div>

      <div className="flex-1 flex gap-4 overflow-hidden">
        {/* Map Container */}
        <div className="flex-1 relative rounded-2xl overflow-hidden border border-gray-200 shadow-sm">
          <Map
            defaultCenter={{ lat: 20.5937, lng: 78.9629 }}
            defaultZoom={5}
            mapId="bf51a910020fa566" // Example Map ID for Advanced Markers
            disableDefaultUI={true}
            zoomControl={true}
          >
            {/* Bus Markers */}
            {buses
              ?.filter((b) => b.lastLocation)
              .filter((b) =>
                b.busNumber.toLowerCase().includes(searchTerm.toLowerCase()),
              )
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

export default LiveTracking;
