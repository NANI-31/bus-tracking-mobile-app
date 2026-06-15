import React, { useEffect, useState } from "react";
import { AdvancedMarker } from "@vis.gl/react-google-maps";
import { useLiveTracking } from "@/components/common/LiveTrackingContext";

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

export default BusMarker;
