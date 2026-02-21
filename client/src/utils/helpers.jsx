import React from "react";
import {
  UserGroupIcon,
  TruckIcon,
  AcademicCapIcon,
  MapIcon,
  CalendarIcon,
  Cog6ToothIcon,
  InformationCircleIcon,
} from "@heroicons/react/24/outline";

export const stringToColor = (string) => {
  if (!string) return "#cbd5e1";
  let hash = 0;
  for (let i = 0; i < string.length; i++) {
    hash = string.charCodeAt(i) + ((hash << 5) - hash);
  }
  let color = "#";
  for (let i = 0; i < 3; i++) {
    const value = (hash >> (i * 8)) & 0xff;
    color += `00${value.toString(16)}`.slice(-2);
  }
  return color;
};

export const getInitials = (email) => {
  if (!email) return "?";
  return email.split("@")[0].substring(0, 2).toUpperCase();
};

export const getResourceIcon = (resource) => {
  const iconClass = "w-4 h-4";
  switch (resource?.toLowerCase()) {
    case "user":
      return <UserGroupIcon className={iconClass} />;
    case "bus":
      return <TruckIcon className={iconClass} />;
    case "college":
      return <AcademicCapIcon className={iconClass} />;
    case "route":
      return <MapIcon className={iconClass} />;
    case "schedule":
      return <CalendarIcon className={iconClass} />;
    case "config":
      return <Cog6ToothIcon className={iconClass} />;
    default:
      return <InformationCircleIcon className={iconClass} />;
  }
};
