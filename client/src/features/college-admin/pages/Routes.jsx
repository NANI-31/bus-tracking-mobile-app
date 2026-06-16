import React, { useEffect, useState, useRef } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  MapIcon,
  PlusIcon,
  TrashIcon,
  MapPinIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  EllipsisHorizontalIcon,
  MagnifyingGlassIcon,
  XMarkIcon,
  ChartBarIcon,
} from "@heroicons/react/24/outline";
import {
  getRoutes,
  createRoute,
  modifyRoute,
  removeRoute,
} from "../slices/collegeAdminSlice";
import ConfirmationModal from "@/components/common/ConfirmationModal";
import RouteFormModal from "../components/Routes/RouteFormModal";
import RouteCard from "../components/Routes/RouteCard";
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from "react-leaflet";
import L from "leaflet";
import { AreaChart, Area, XAxis, YAxis, Tooltip as ChartTooltip, ResponsiveContainer } from "recharts";

// Leaflet custom icons styled with Tailwind CSS to avoid asset loading bugs
const markerAnimationStyles = `
  @keyframes marker-scale-in {
    0% {
      opacity: 0;
      transform: scale(0) translateY(-18px);
    }
    60% {
      transform: scale(1.15) translateY(2px);
    }
    100% {
      opacity: 1;
      transform: scale(1) translateY(0);
    }
  }

  .marker-anim-start {
    animation: marker-scale-in 0.45s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
  }
`;

const startIcon = typeof window !== "undefined" ? L.divIcon({
  html: `<div class="marker-anim-start relative flex items-center justify-center w-8 h-8 rounded-full bg-emerald-500 text-white font-black border-2 border-white shadow-md hover:scale-115 active:scale-95 transition-all">S</div>`,
  className: "",
  iconSize: [32, 32],
  iconAnchor: [16, 16],
}) : null;

const endIcon = typeof window !== "undefined" ? L.divIcon({
  html: `<div class="marker-anim-start relative flex items-center justify-center w-8 h-8 rounded-full bg-rose-500 text-white font-black border-2 border-white shadow-md hover:scale-115 active:scale-95 transition-all">E</div>`,
  className: "",
  iconSize: [32, 32],
  iconAnchor: [16, 16],
}) : null;

const intermediateIcon = (index, color = "#1E90FF") => typeof window !== "undefined" ? L.divIcon({
  html: `<div class="marker-anim-start relative flex items-center justify-center w-6 h-6 rounded-full text-white font-black border-2 border-white shadow-sm text-[10px] hover:scale-115 active:scale-95 transition-all" style="background-color: ${color}">${index}</div>`,
  className: "",
  iconSize: [24, 24],
  iconAnchor: [12, 12],
}) : null;

// Dynamic hovered/highlighted marker icon with pulsing wave
const hoveredIcon = (index, label, color = "#1E90FF") => typeof window !== "undefined" ? L.divIcon({
  html: `
    <div class="marker-anim-start relative flex items-center justify-center">
      <div class="absolute w-12 h-12 rounded-full animate-ping" style="background-color: ${color}; opacity: 0.3;"></div>
      <div class="relative flex items-center justify-center w-10 h-10 rounded-full text-white font-black border-2 border-white shadow-xl scale-125 transition-transform duration-300 z-50" style="background-color: ${color}">
        ${label || index}
      </div>
    </div>
  `,
  className: "",
  iconSize: [40, 40],
  iconAnchor: [20, 20],
}) : null;

// Helper to calculate Haversine distance in kilometers
const calculateHaversineDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

// Canvas overlay to animate small pulsing bus particles traversing polylines
const RoutePathAnimator = ({ positions, color = "#1E90FF" }) => {
  const map = useMap();

  useEffect(() => {
    if (!positions || positions.length < 2) return;

    // Create canvas
    const canvas = document.createElement("canvas");
    canvas.style.position = "absolute";
    canvas.style.top = "0";
    canvas.style.left = "0";
    canvas.style.pointerEvents = "none";
    canvas.style.zIndex = "400";

    const container = map.getContainer();
    container.appendChild(canvas);

    const ctx = canvas.getContext("2d");
    let animationFrameId;
    let progress = 0;

    const resizeCanvas = () => {
      const rect = container.getBoundingClientRect();
      canvas.width = rect.width;
      canvas.height = rect.height;
      canvas.style.width = `${rect.width}px`;
      canvas.style.height = `${rect.height}px`;
    };
    resizeCanvas();

    const getPointAlongPath = (pts, ratio) => {
      if (pts.length < 2) return null;
      const segments = [];
      let totalDist = 0;
      for (let i = 0; i < pts.length - 1; i++) {
        const dx = pts[i+1].x - pts[i].x;
        const dy = pts[i+1].y - pts[i].y;
        const dist = Math.sqrt(dx*dx + dy*dy);
        segments.push(dist);
        totalDist += dist;
      }
      if (totalDist === 0) return pts[0];
      const targetDist = ratio * totalDist;
      let accumulatedDist = 0;
      for (let i = 0; i < segments.length; i++) {
        const segDist = segments[i];
        if (accumulatedDist + segDist >= targetDist) {
          const segmentRatio = (targetDist - accumulatedDist) / segDist;
          return {
            x: pts[i].x + (pts[i+1].x - pts[i].x) * segmentRatio,
            y: pts[i].y + (pts[i+1].y - pts[i].y) * segmentRatio
          };
        }
        accumulatedDist += segDist;
      }
      return pts[pts.length - 1];
    };

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const pixels = positions.map(pos => map.latLngToContainerPoint(pos));

      if (pixels.length >= 2) {
        const numParticles = 4;
        for (let p = 0; p < numParticles; p++) {
          const pProgress = (progress + p / numParticles) % 1.0;
          const pt = getPointAlongPath(pixels, pProgress);
          if (pt) {
            const time = Date.now() * 0.005;
            const pulseRadius = 5 + Math.sin(time + p * 1.5) * 2;
            
            ctx.beginPath();
            ctx.arc(pt.x, pt.y, pulseRadius + 6, 0, Math.PI * 2);
            ctx.fillStyle = `${color}15`;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(pt.x, pt.y, pulseRadius + 2, 0, Math.PI * 2);
            ctx.fillStyle = `${color}45`;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(pt.x, pt.y, 3.5, 0, Math.PI * 2);
            ctx.fillStyle = "#ffffff";
            ctx.shadowColor = color;
            ctx.shadowBlur = 6;
            ctx.fill();
            ctx.shadowBlur = 0;
          }
        }
      }

      progress = (progress + 0.0025) % 1.0;
      animationFrameId = requestAnimationFrame(animate);
    };

    animate();

    const handleUpdate = () => {
      resizeCanvas();
    };

    map.on("move zoom viewreset resize", handleUpdate);

    return () => {
      cancelAnimationFrame(animationFrameId);
      map.off("move zoom viewreset resize", handleUpdate);
      if (container.contains(canvas)) {
        container.removeChild(canvas);
      }
    };
  }, [map, positions, color]);

  return null;
};

// Map recentering hook
const MapRecenter = ({ stops }) => {
  const map = useMap();
  useEffect(() => {
    if (stops && stops.length > 0) {
      const points = stops
        .filter(stop => stop.location && typeof stop.location.lat === "number" && typeof stop.location.lng === "number")
        .map((stop) => [stop.location.lat, stop.location.lng]);
      if (points.length > 0) {
        map.fitBounds(points, { padding: [50, 50] });
      }
    }
  }, [stops, map]);
  return null;
};

// Canvas background animation representing a transit mesh
const TransitNetworkBackground = () => {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    let animationFrameId;

    let width = (canvas.width = canvas.offsetWidth);
    let height = (canvas.height = canvas.offsetHeight);

    const particles = [];
    const count = 30;

    for (let i = 0; i < count; i++) {
      particles.push({
        x: Math.random() * width,
        y: Math.random() * height,
        vx: (Math.random() - 0.5) * 0.7,
        vy: (Math.random() - 0.5) * 0.7,
        radius: Math.random() * 2 + 1.5,
      });
    }

    const draw = () => {
      if (!canvas || !ctx) return;
      ctx.clearRect(0, 0, width, height);

      // Draw connection lines
      ctx.strokeStyle = "rgba(30, 144, 255, 0.08)";
      ctx.lineWidth = 1;
      for (let i = 0; i < count; i++) {
        for (let j = i + 1; j < count; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 110) {
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.stroke();
          }
        }
      }

      // Draw nodes
      ctx.fillStyle = "rgba(30, 144, 255, 0.25)";
      particles.forEach((p) => {
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fill();

        p.x += p.vx;
        p.y += p.vy;

        if (p.x < 0 || p.x > width) p.vx *= -1;
        if (p.y < 0 || p.y > height) p.vy *= -1;
      });

      animationFrameId = requestAnimationFrame(draw);
    };

    draw();

    const handleResize = () => {
      if (!canvas) return;
      width = canvas.width = canvas.offsetWidth;
      height = canvas.height = canvas.offsetHeight;
    };

    window.addEventListener("resize", handleResize);

    return () => {
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener("resize", handleResize);
    };
  }, []);

  return <canvas ref={canvasRef} className="absolute inset-0 w-full h-full pointer-events-none" />;
};

const Routes = () => {
  const dispatch = useDispatch();
  const { routes, loading } = useSelector((state) => state.collegeAdmin);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingRoute, setEditingRoute] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [hoveredStopKey, setHoveredStopKey] = useState(null);
  const [isSidebarOpenOnMobile, setIsSidebarOpenOnMobile] = useState(false);
  const [deleteModal, setDeleteModal] = useState({
    isOpen: false,
    routeId: null,
  });

  useEffect(() => {
    dispatch(getRoutes());
  }, [dispatch]);

  // Automatically select the first route on load
  useEffect(() => {
    if (routes && routes.length > 0 && !selectedRoute) {
      setSelectedRoute(routes[0]);
    }
  }, [routes, selectedRoute]);

  const filteredRoutes = routes?.filter((route) => {
    const q = searchQuery.toLowerCase();
    const matchesName = route.routeName?.toLowerCase().includes(q);
    const matchesStops = route.stopPoints?.some((stop) =>
      stop.name?.toLowerCase().includes(q),
    );
    return matchesName || matchesStops;
  });

  const handleEditRoute = (route) => {
    setEditingRoute(route);
    setIsModalOpen(true);
  };

  const handleAddRoute = (routeData) => {
    const formattedData = {
      routeName: routeData.name,
      routeType: "pickup",
      color: routeData.color || "#1E90FF",
      stopPoints: routeData.stops.map((stop) => ({
        name: stop.name,
        location: {
          lat: parseFloat(stop.lat) || 0,
          lng: parseFloat(stop.lng) || 0,
        },
      })),
      startPoint: {
        name: routeData.stops[0].name,
        location: {
          lat: parseFloat(routeData.stops[0].lat) || 0,
          lng: parseFloat(routeData.stops[0].lng) || 0,
        },
      },
      endPoint: {
        name: routeData.stops[routeData.stops.length - 1].name,
        location: {
          lat: parseFloat(routeData.stops[routeData.stops.length - 1].lat) || 0,
          lng: parseFloat(routeData.stops[routeData.stops.length - 1].lng) || 0,
        },
      },
    };

    if (editingRoute) {
      dispatch(modifyRoute({ routeId: editingRoute._id, routeData: formattedData })).then((res) => {
        if (selectedRoute && selectedRoute._id === editingRoute._id) {
          setSelectedRoute({ ...selectedRoute, ...formattedData });
        }
      });
    } else {
      dispatch(createRoute(formattedData));
    }
  };

  const handleDeleteRoute = (routeId) => {
    setDeleteModal({ isOpen: true, routeId });
  };

  const confirmDeleteRoute = () => {
    if (deleteModal.routeId) {
      dispatch(removeRoute(deleteModal.routeId)).then(() => {
        if (selectedRoute && selectedRoute._id === deleteModal.routeId) {
          setSelectedRoute(null);
        }
      });
    }
  };

  // Stats Computations
  const totalRoutes = routes?.length || 0;
  const totalStops = routes?.reduce((acc, r) => acc + (r.stopPoints?.length || 0), 0) || 0;
  const avgStops = totalRoutes > 0 ? (totalStops / totalRoutes).toFixed(1) : 0;

  // Filter valid coordinate stops for Leaflet
  const validStops = selectedRoute?.stopPoints?.filter(
    (stop) => stop.location && typeof stop.location.lat === "number" && typeof stop.location.lng === "number"
  ) || [];

  const polylinePositions = validStops.map((s) => [s.location.lat, s.location.lng]);
  const activeColor = selectedRoute?.color || "#1E90FF";

  // Calculate cumulative estimations
  let totalDistance = 0;
  let totalDuration = 0;
  for (let i = 1; i < polylinePositions.length; i++) {
    const prev = polylinePositions[i - 1];
    const curr = polylinePositions[i];
    const dist = calculateHaversineDistance(prev[0], prev[1], curr[0], curr[1]);
    totalDistance += dist;
    totalDuration += Math.ceil((dist / 30) * 60); // 30 km/h average driving speed
  }

  // Dynamic stop elevations per stop
  const chartData = validStops.map((stop, index) => {
    const latFactor = Math.abs(Math.sin(stop.location.lat * 15)) * 120;
    const lngFactor = Math.abs(Math.cos(stop.location.lng * 15)) * 90;
    const mockElevation = Math.round(45 + latFactor + lngFactor + (index * 7) % 20);
    return {
      name: stop.name.substring(0, 10),
      fullName: stop.name,
      elevation: mockElevation,
      stopKey: stop._id || stop.name,
      lat: stop.location.lat,
      lng: stop.location.lng,
    };
  });

  // Calculate slopes and gradients between sequential stops
  const chartDataWithGradients = chartData.map((data, index) => {
    if (index === 0) {
      return {
        ...data,
        slopePercentage: 0,
        slopeAngle: 0,
        elevationChange: 0,
      };
    }
    const prev = chartData[index - 1];
    const distanceKm = calculateHaversineDistance(prev.lat, prev.lng, data.lat, data.lng);
    const distanceMeters = distanceKm * 1000;
    const elevationChange = data.elevation - prev.elevation;

    let slopePercentage = 0;
    let slopeAngle = 0;
    if (distanceMeters > 0) {
      slopePercentage = (elevationChange / distanceMeters) * 100;
      slopeAngle = Math.atan(elevationChange / distanceMeters) * (180 / Math.PI);
    }

    return {
      ...data,
      slopePercentage: parseFloat(slopePercentage.toFixed(1)),
      slopeAngle: parseFloat(slopeAngle.toFixed(1)),
      elevationChange,
    };
  });

  const elevations = chartData.map((d) => d.elevation);
  const minElevation = elevations.length > 0 ? Math.min(...elevations) : 0;
  const maxElevation = elevations.length > 0 ? Math.max(...elevations) : 0;

  return (
    <div className="space-y-6 min-h-screen bg-background-default -m-6 p-6">
      <style>{markerAnimationStyles}</style>
      
      {/* Title Header Block */}
      <motion.div 
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 100, damping: 15 }}
        className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 bg-background-paper p-6 rounded-3xl border border-border-theme/40 shadow-sm transition-colors duration-300"
      >
        <div>
          <h1 className="text-xl sm:text-2xl font-black text-text-theme-primary tracking-tight">
            Control Center: Routes
          </h1>
          <p className="text-text-theme-secondary text-sm font-semibold">
            Configure transit lines, pathways, and intermediate station points
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-center gap-3 w-full lg:w-auto">
          {/* Search Bar */}
          <div className="relative w-full sm:w-80 group">
            <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <MagnifyingGlassIcon className="w-5 h-5 text-text-theme-secondary group-focus-within:text-primary-main transition-colors" />
            </div>
            <input
              type="text"
              placeholder="Search transit line or stop..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="block w-full pl-11 pr-10 py-2.5 bg-background-default border border-border-theme rounded-2xl text-sm font-bold text-text-theme-primary placeholder:text-text-theme-secondary placeholder:font-semibold focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 outline-none transition-all duration-200"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-text-theme-secondary hover:text-text-theme-primary transition-colors"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            )}
          </div>

          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center justify-center space-x-2 px-6 py-2.5 bg-primary-main hover:bg-primary-dark text-white rounded-2xl font-bold shadow-lg shadow-primary-main/20 active:scale-[0.98] transition-all cursor-pointer w-full sm:w-auto shrink-0"
          >
            <PlusIcon className="w-5 h-5" />
            <span>Add Route</span>
          </button>
        </div>
      </motion.div>

      {/* Analytics Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        {[
          {
            title: "Total Transit Lines",
            value: totalRoutes,
            icon: MapIcon,
            color: "from-primary-main/15 to-primary-light/5 text-primary-main border-primary-main/15",
            hoverColor: "hover:shadow-primary-main/5 hover:border-primary-main/30",
            delay: 0,
          },
          {
            title: "Configured Stations",
            value: totalStops,
            icon: MapPinIcon,
            color: "from-emerald-500/15 to-emerald-400/5 text-emerald-500 border-emerald-500/15",
            hoverColor: "hover:shadow-emerald-500/5 hover:border-emerald-500/30",
            delay: 0.08,
          },
          {
            title: "Average Stops / Route",
            value: avgStops,
            icon: ChartBarIcon,
            color: "from-violet-500/15 to-violet-400/5 text-violet-500 border-violet-500/15",
            hoverColor: "hover:shadow-violet-500/5 hover:border-violet-500/30",
            delay: 0.16,
          },
        ].map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ type: "spring", stiffness: 100, damping: 15, delay: stat.delay }}
              whileHover={{ 
                y: -6, 
                scale: 1.025, 
                transition: { type: "spring", stiffness: 450, damping: 16 } 
              }}
              className={`bg-background-paper border border-border-theme/40 rounded-3xl p-5 shadow-sm hover:shadow-xl transition-all duration-350 flex items-center gap-4 cursor-pointer group ${stat.hoverColor}`}
            >
              <div className={`p-3.5 rounded-2xl bg-linear-to-tr border transition-transform duration-350 group-hover:scale-110 ${stat.color}`}>
                <Icon className="w-6 h-6 shrink-0" />
              </div>
              <div>
                <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-0.5">{stat.title}</p>
                <p className="text-2xl font-black text-text-theme-primary leading-none">{stat.value}</p>
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Mobile Sidebar Backdrop */}
      {isSidebarOpenOnMobile && (
        <div 
          onClick={() => setIsSidebarOpenOnMobile(false)}
          className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs z-1000 lg:hidden"
        />
      )}

      {/* Main Dual-Pane Section */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 items-start relative">
        
        {/* Left Pane: Route Cards Scrollable list (Slidable sidebar on mobile, side-by-side on desktop) */}
        <div className={`
          fixed inset-y-0 left-0 z-1001 w-[85vw] max-w-sm bg-background-paper dark:bg-slate-900 p-6 shadow-2xl border-r border-border-theme/40 transition-transform duration-300 transform overflow-y-auto
          lg:relative lg:translate-x-0 lg:col-span-3 lg:w-auto lg:max-w-none lg:p-0 lg:shadow-none lg:border-none lg:bg-transparent lg:z-auto lg:space-y-6 lg:transform-none lg:h-auto lg:overflow-visible
          ${isSidebarOpenOnMobile ? "translate-x-0" : "-translate-x-full"}
        `}>
          {/* Mobile Sidebar Close Header */}
          <div className="flex justify-between items-center mb-6 lg:hidden">
            <div>
              <h2 className="text-lg font-black text-text-theme-primary">Transit Routes</h2>
              <p className="text-text-theme-secondary text-[11px] font-semibold">Select a route line to view details</p>
            </div>
            <button
              onClick={() => setIsSidebarOpenOnMobile(false)}
              className="p-2 rounded-xl bg-background-default border border-border-theme text-text-theme-secondary hover:text-text-theme-primary transition-colors cursor-pointer"
            >
              <XMarkIcon className="w-5 h-5" />
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <AnimatePresence mode="popLayout">
              {loading && (!routes || routes.length === 0) ? (
                Array.from({ length: 4 }).map((_, idx) => (
                  <div
                    key={`skeleton-${idx}`}
                    className="bg-background-paper border border-border-theme/40 rounded-3xl p-6 shadow-xs flex flex-col space-y-6 relative overflow-hidden"
                  >
                    <div className="flex items-center space-x-4">
                      {/* Avatar skeleton */}
                      <div className="w-[52px] h-[52px] rounded-[16px] shimmer shrink-0" />
                      {/* Title skeleton */}
                      <div className="flex-1 space-y-2">
                        <div className="h-5 rounded-lg w-3/4 shimmer" />
                        <div className="h-3.5 rounded-lg w-1/3 shimmer" />
                      </div>
                    </div>

                    {/* Stops skeleton */}
                    <div className="space-y-4">
                      <div className="flex items-center space-x-3">
                        <div className="w-2.5 h-2.5 rounded-full shimmer" />
                        <div className="h-4 rounded-lg w-1/2 shimmer" />
                      </div>
                      <div className="flex items-center space-x-3">
                        <div className="w-2.5 h-2.5 rounded-full shimmer" />
                        <div className="h-4 rounded-lg w-2/3 shimmer" />
                      </div>
                    </div>

                    {/* Bottom stats skeleton */}
                    <div className="border-t border-border-theme/40 pt-4 flex justify-between items-center">
                      <div className="h-4 rounded-lg w-1/4 shimmer" />
                      <div className="h-4 rounded-lg w-1/5 shimmer" />
                    </div>
                  </div>
                ))
              ) : (
                Array.isArray(filteredRoutes) &&
                filteredRoutes.map((route) => (
                  <RouteCard
                    key={route._id}
                    route={route}
                    onDelete={handleDeleteRoute}
                    onEdit={handleEditRoute}
                    onSelect={(selected) => {
                      setSelectedRoute(selected);
                      setIsSidebarOpenOnMobile(false);
                    }}
                    isSelected={selectedRoute && selectedRoute._id === route._id}
                    onHoverStop={setHoveredStopKey}
                  />
                ))
              )}
            </AnimatePresence>
          </div>

          {/* Empty State */}
          {(!filteredRoutes || filteredRoutes.length === 0) && !loading && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-background-paper rounded-3xl border border-dashed border-border-theme py-16 text-center shadow-inner"
            >
              <div className="bg-background-default w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 border border-border-theme shadow-sm">
                <MapIcon className="w-8 h-8 text-text-theme-secondary" />
              </div>
              <h3 className="text-lg font-black text-text-theme-primary mb-1">
                {searchQuery ? "No matches found" : "No routes yet"}
              </h3>
              <p className="text-text-theme-secondary text-sm font-semibold max-w-sm mx-auto">
                {searchQuery
                  ? `We couldn't find any routes or stations matching "${searchQuery}"`
                  : "Get started by adding your first route line."}
              </p>
              {searchQuery && (
                <button
                  onClick={() => {
                    setSearchQuery("");
                    setIsSidebarOpenOnMobile(false);
                  }}
                  className="mt-4 text-primary-main font-bold text-sm hover:underline cursor-pointer"
                >
                  Clear Search
                </button>
              )}
            </motion.div>
          )}
        </div>

        {/* Right Pane: Sticky Visual Route Preview Map */}
        <div className="w-full lg:col-span-2 lg:sticky lg:top-0">
          <div 
            className="bg-background-paper border rounded-3xl overflow-hidden flex flex-col h-[620px] lg:h-[calc(100vh-80px)] relative transition-all duration-500 ease-in-out"
            style={{
              borderColor: selectedRoute ? `${activeColor}60` : "var(--border-color)",
              boxShadow: selectedRoute 
                ? `0 20px 40px -15px ${activeColor}30, 0 0 15px 0 ${activeColor}10` 
                : "0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.05)"
            }}
          >
            {selectedRoute && validStops.length > 0 ? (
              <>
                {/* Map Floating Details Panel */}
                <div className="absolute top-4 left-4 right-4 z-10 p-4 bg-background-paper/85 dark:bg-slate-900/85 backdrop-blur-md border border-white/20 dark:border-slate-800/80 rounded-2xl shadow-lg">
                  <div className="flex justify-between items-start">
                    <div>
                      <span className="text-[9px] font-black uppercase tracking-widest" style={{ color: activeColor }}>Live Pathway Preview</span>
                      <h4 className="font-black text-text-theme-primary text-base leading-snug">{selectedRoute.routeName}</h4>
                    </div>
                    <span 
                      className="px-2.5 py-1 text-[10px] font-bold rounded-lg shrink-0 border"
                      style={{ 
                        backgroundColor: `${activeColor}15`, 
                        borderColor: `${activeColor}30`, 
                        color: activeColor 
                      }}
                    >
                      {validStops.length} Stops • {totalDistance.toFixed(1)} km ({totalDuration}m)
                    </span>
                  </div>
                  
                  <div className="mt-3 grid grid-cols-2 gap-4 border-t border-border-theme/40 pt-2.5 text-xs text-text-theme-secondary font-semibold">
                    <div className="truncate">
                      <span className="text-[8px] uppercase tracking-wider block text-text-theme-secondary opacity-70">Start point</span>
                      <span className="text-text-theme-primary font-bold truncate block">{validStops[0]?.name}</span>
                    </div>
                    <div className="truncate">
                      <span className="text-[8px] uppercase tracking-wider block text-text-theme-secondary opacity-70">Terminus</span>
                      <span className="text-text-theme-primary font-bold truncate block">{validStops[validStops.length - 1]?.name}</span>
                    </div>
                  </div>
                </div>

                {/* Leaflet Map */}
                <div className="flex-1 w-full relative min-h-[420px] z-0">
                  <MapContainer
                    center={[validStops[0].location.lat, validStops[0].location.lng]}
                    zoom={13}
                    style={{ height: "100%", width: "100%" }}
                    zoomControl={false}
                  >
                    <TileLayer
                      attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                      url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    />
                    
                    {/* Render sequence path line */}
                    <Polyline
                      positions={polylinePositions}
                      color={activeColor}
                      weight={4}
                      opacity={0.8}
                      dashArray="5, 10"
                    />

                    {/* Midpoint Tooltip Overlays for distance/duration estimations */}
                    {polylinePositions.map((pos, idx) => {
                      if (idx === 0) return null;
                      const prev = polylinePositions[idx - 1];
                      const dist = calculateHaversineDistance(prev[0], prev[1], pos[0], pos[1]);
                      const duration = Math.ceil((dist / 30) * 60); // 30 km/h average speed
                      const midLat = (prev[0] + pos[0]) / 2;
                      const midLng = (prev[1] + pos[1]) / 2;
                      
                      return (
                        <Marker
                          key={`mid-${idx}`}
                          position={[midLat, midLng]}
                          icon={L.divIcon({
                            html: `
                              <div class="px-2 py-1 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg shadow-md text-[9px] font-black text-slate-850 dark:text-slate-100 whitespace-nowrap opacity-90 hover:opacity-100 hover:scale-105 active:scale-95 transition-all cursor-default select-none">
                                ${dist.toFixed(1)} km • ${duration}m
                              </div>
                            `,
                            className: "",
                            iconSize: [80, 20],
                            iconAnchor: [40, 10],
                          })}
                        />
                      );
                    })}

                    {/* Canvas particle animations */}
                    <RoutePathAnimator positions={polylinePositions} color={activeColor} />

                    {/* Start Stop Marker */}
                    <Marker
                      position={[validStops[0].location.lat, validStops[0].location.lng]}
                      icon={(hoveredStopKey === validStops[0]?._id || hoveredStopKey === validStops[0]?.name) ? hoveredIcon(0, "S", activeColor) : startIcon}
                    >
                      <Popup>
                        <div className="p-1">
                          <p className="font-bold text-gray-800 text-xs">Start Station</p>
                          <p className="text-[10px] text-gray-500 font-semibold">{validStops[0].name}</p>
                        </div>
                      </Popup>
                    </Marker>

                    {/* Intermediate Stop Markers */}
                    {validStops.slice(1, -1).map((stop, index) => (
                      <Marker
                        key={stop._id || index}
                        position={[stop.location.lat, stop.location.lng]}
                        icon={(hoveredStopKey === stop._id || hoveredStopKey === stop.name) ? hoveredIcon(index + 1, null, activeColor) : intermediateIcon(index + 1, activeColor)}
                      >
                        <Popup>
                          <div className="p-1">
                            <p className="font-bold text-gray-800 text-xs">Stop #{index + 1}</p>
                            <p className="text-[10px] text-gray-500 font-semibold">{stop.name}</p>
                          </div>
                        </Popup>
                      </Marker>
                    ))}

                    {/* Terminus Stop Marker */}
                    {validStops.length > 1 && (
                      <Marker
                        position={[
                          validStops[validStops.length - 1].location.lat,
                          validStops[validStops.length - 1].location.lng
                        ]}
                        icon={(hoveredStopKey === validStops[validStops.length - 1]?._id || hoveredStopKey === validStops[validStops.length - 1]?.name) ? hoveredIcon(0, "E", activeColor) : endIcon}
                      >
                        <Popup>
                          <div className="p-1">
                            <p className="font-bold text-gray-800 text-xs">Destination Terminus</p>
                            <p className="text-[10px] text-gray-500 font-semibold">{validStops[validStops.length - 1].name}</p>
                          </div>
                        </Popup>
                      </Marker>
                    )}

                    <MapRecenter stops={validStops} />
                  </MapContainer>

                  {/* Floating Mobile Toggle Button */}
                  <button
                    onClick={() => setIsSidebarOpenOnMobile(true)}
                    className="lg:hidden absolute bottom-4 left-4 z-999 flex items-center space-x-2 px-4 py-2.5 bg-primary-main hover:bg-primary-dark text-white rounded-full font-bold shadow-xl active:scale-95 transition-all cursor-pointer border border-white/10"
                  >
                    <MapIcon className="w-5 h-5" />
                    <span>View Routes</span>
                  </button>
                </div>

                {/* Elevation Profile Area Chart */}
                <div className="p-4 border-t border-border-theme/40 bg-background-paper dark:bg-slate-900 transition-colors duration-300">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary flex items-center gap-1.5">
                      <ChartBarIcon className="w-4.5 h-4.5" />
                      Elevation Profile (Spatial Depth)
                    </span>
                    <span className="text-[10px] font-bold text-text-theme-secondary bg-background-default border border-border-theme px-2 py-0.5 rounded-md">
                      Min: {minElevation}m | Max: {maxElevation}m
                    </span>
                  </div>
                  <div className="h-28 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart 
                        data={chartDataWithGradients} 
                        margin={{ top: 5, right: 5, left: -25, bottom: 0 }}
                        onMouseMove={(state) => {
                          if (state && state.activePayload && state.activePayload.length > 0) {
                            const activePoint = state.activePayload[0].payload;
                            setHoveredStopKey(activePoint.stopKey);
                          }
                        }}
                        onMouseLeave={() => {
                          setHoveredStopKey(null);
                        }}
                      >
                        <defs>
                          <linearGradient id="elevationGrad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor={activeColor} stopOpacity={0.4}/>
                            <stop offset="95%" stopColor={activeColor} stopOpacity={0.0}/>
                          </linearGradient>
                        </defs>
                        <XAxis dataKey="name" tick={{ fontSize: 9, fill: "var(--text-secondary)" }} axisLine={false} tickLine={false} />
                        <YAxis tick={{ fontSize: 9, fill: "var(--text-secondary)" }} axisLine={false} tickLine={false} />
                        <ChartTooltip 
                          content={({ active, payload }) => {
                            if (active && payload && payload.length) {
                              const data = payload[0].payload;
                              const isClimb = data.elevationChange > 0;
                              const isDescent = data.elevationChange < 0;
                              
                              return (
                                <div className="bg-background-paper/95 dark:bg-slate-900/95 border border-border-theme p-3 rounded-2xl shadow-xl text-xs font-bold text-text-theme-primary flex items-center gap-3.5 max-w-[240px]">
                                  {/* Visual Slope Wedge Mini-Chart */}
                                  {data.elevationChange !== 0 ? (
                                    <svg className="w-10 h-8 shrink-0" viewBox="0 0 50 30">
                                      <line x1="5" y1="25" x2="45" y2="25" stroke="currentColor" strokeWidth="1.2" strokeDasharray="2 2" opacity="0.3" />
                                      <path 
                                        d={`M 5 25 L 45 ${25 - Math.max(-12, Math.min(12, data.elevationChange * 0.4))} L 45 25 Z`} 
                                        fill={isClimb ? "rgba(16, 185, 129, 0.15)" : "rgba(244, 63, 94, 0.15)"} 
                                        stroke={isClimb ? "#10B981" : "#F43F5E"} 
                                        strokeWidth="2" 
                                      />
                                    </svg>
                                  ) : (
                                    <div className="w-10 h-8 flex items-center justify-center bg-primary-main/10 text-primary-main border border-primary-main/20 rounded-lg shrink-0">
                                      <span className="text-[10px] font-black uppercase">Start</span>
                                    </div>
                                  )}
                                  
                                  <div className="flex-1 min-w-0">
                                    <p className="font-extrabold text-[11px] truncate text-text-theme-primary leading-tight mb-1">{data.fullName}</p>
                                    <div className="flex flex-col gap-0.5 text-[10px] text-text-theme-secondary">
                                      <span className="font-black text-text-theme-primary flex items-center gap-1">
                                        <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: activeColor }} />
                                        Alt: {data.elevation}m
                                      </span>
                                      {data.elevationChange !== 0 ? (
                                        <span className={`flex items-center gap-1 font-extrabold ${isClimb ? "text-emerald-500" : "text-rose-500"}`}>
                                          {isClimb ? "▲ Climb" : "▼ Descent"} {Math.abs(data.elevationChange)}m ({data.slopeAngle}° slope)
                                        </span>
                                      ) : (
                                        <span className="text-slate-400 dark:text-slate-650 font-semibold">Start Station</span>
                                      )}
                                    </div>
                                  </div>
                                </div>
                              );
                            }
                            return null;
                          }} 
                        />
                        <Area type="monotone" dataKey="elevation" stroke={activeColor} strokeWidth={2} fillOpacity={1} fill="url(#elevationGrad)" />
                      </AreaChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              </>
            ) : (
              // Idle/Empty Map Canvas Animation
              <div className="flex-1 flex flex-col items-center justify-center p-8 text-center relative overflow-hidden bg-background-paper select-none transition-colors duration-300">
                <TransitNetworkBackground />
                <div className="relative z-10 max-w-xs space-y-4">
                  <div className="w-16 h-16 rounded-3xl bg-linear-to-tr from-primary-main/15 to-secondary-main/15 text-primary-main border border-primary-main/20 flex items-center justify-center mx-auto shadow-inner animate-pulse">
                    <MapIcon className="w-8 h-8" />
                  </div>
                  <div>
                    <h4 className="font-black text-text-theme-primary text-base">Select Transit Line</h4>
                    <p className="text-text-theme-secondary text-xs font-semibold leading-relaxed mt-1">
                      Choose a transit card on the left pane to visualize its full spatial route coordinates, marker pins, and path connections.
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
        
      </div>

      <RouteFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setEditingRoute(null);
        }}
        onSubmit={handleAddRoute}
        route={editingRoute}
      />

      <ConfirmationModal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, routeId: null })}
        onConfirm={confirmDeleteRoute}
        title="Delete Route"
        message="Are you sure you want to delete this route? All associated bus schedules for this route will also be affected."
        confirmText="Delete"
      />
    </div>
  );
};

export default Routes;
