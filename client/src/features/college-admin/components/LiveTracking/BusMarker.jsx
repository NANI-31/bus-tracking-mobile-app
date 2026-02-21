import React from "react";
import { AdvancedMarker } from "@vis.gl/react-google-maps";

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

export default BusMarker;
