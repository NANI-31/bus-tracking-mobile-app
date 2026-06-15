import React from "react";
import { Link, useLocation } from "react-router-dom";
import { ChevronRightIcon } from "@heroicons/react/20/solid";
import { HomeIcon } from "@heroicons/react/24/outline";

const Breadcrumbs = () => {
  const location = useLocation();
  const pathnames = location.pathname.split("/").filter((x) => x);

  const routeLabels = {
    "college-admin": "College Admin",
    "super-admin": "Super Admin",
    "users": "Users",
    "fleet": "Fleet",
    "tracking": "Live Map",
    "routes": "Routes",
    "payments": "Payments",
    "refunds": "Refunds",
    "logs": "Logs",
    "colleges": "Colleges",
    "analytics": "Analytics",
    "details": "Details",
  };

  if (pathnames.length === 0) return null;

  return (
    <nav aria-label="Breadcrumb" className="mb-4 sm:mb-6 flex items-center flex-wrap gap-y-1.5 space-x-1.5 sm:space-x-2 text-xs font-semibold text-slate-400">
      <Link
        to={pathnames[0] === "super-admin" ? "/super-admin" : "/college-admin"}
        className="flex items-center hover:text-slate-600 focus-ring rounded-lg px-1 py-0.5 transition-colors"
      >
        <HomeIcon className="w-4 h-4 mr-1 text-slate-400" />
        <span>Home</span>
      </Link>

      {pathnames.length > 2 && (
        <div className="flex items-center space-x-1.5 sm:space-x-2 md:hidden">
          <ChevronRightIcon className="w-4 h-4 text-slate-350" />
          <span className="text-slate-400 select-none font-bold">...</span>
        </div>
      )}

      {pathnames.map((value, index) => {
        const last = index === pathnames.length - 1;
        const isIntermediate = index > 0 && index < pathnames.length - 1;
        const to = `/${pathnames.slice(0, index + 1).join("/")}`;
        const label = routeLabels[value] || value.charAt(0).toUpperCase() + value.slice(1);

        return (
          <div key={to} className={`items-center space-x-1.5 sm:space-x-2 ${isIntermediate ? "hidden md:flex" : "flex"}`}>
            <ChevronRightIcon className="w-4 h-4 text-slate-300" />
            {last ? (
              <span className="text-slate-700 dark:text-slate-200 font-extrabold truncate max-w-[120px] sm:max-w-none">{label}</span>
            ) : (
              <Link to={to} className="hover:text-slate-600 dark:hover:text-slate-300 focus-ring rounded-lg px-1 py-0.5 transition-colors">
                {label}
              </Link>
            )}
          </div>
        );
      })}
    </nav>
  );
};

export default Breadcrumbs;
