import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  CheckCircleIcon,
  XCircleIcon,
  MagnifyingGlassIcon,
  BuildingLibraryIcon,
  NoSymbolIcon,
} from "@heroicons/react/24/outline";
import { getColleges, verifyCollegeAction } from "../slices/superAdminSlice";

const Colleges = () => {
  const dispatch = useDispatch();
  const { colleges, loading } = useSelector((state) => state.superAdmin);
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");

  useEffect(() => {
    dispatch(getColleges());
  }, [dispatch]);

  const filteredColleges = colleges.filter((college) => {
    const matchesFilter = filter === "all" || college.status === filter;
    const matchesSearch =
      college.name.toLowerCase().includes(search.toLowerCase()) ||
      college.email.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const handleVerify = (collegeId) => {
    if (window.confirm("Are you sure you want to verify this college?")) {
      dispatch(verifyCollegeAction(collegeId));
    }
  };

  // Placeholder for suspend logic as backend implementation might vary
  const handleSuspend = (collegeId) => {
    alert("Suspend functionality to be connected to backend.");
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-slate-800">
          College Management
        </h1>
        <div className="flex space-x-4">
          <div className="relative">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search colleges..."
              className="pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <select
            className="border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="verified">Verified</option>
            <option value="suspended">Suspended</option>
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence>
          {filteredColleges.map((college) => (
            <motion.div
              key={college._id}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              layout
              className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 flex flex-col"
            >
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center space-x-3">
                  <div className="p-3 bg-indigo-50 rounded-lg">
                    <BuildingLibraryIcon className="w-8 h-8 text-indigo-600" />
                  </div>
                  <div>
                    <h3
                      className="text-lg font-bold text-slate-800 line-clamp-1"
                      title={college.name}
                    >
                      {college.name}
                    </h3>
                    <p className="text-sm text-slate-500">{college.email}</p>
                  </div>
                </div>
                {college.status === "verified" ? (
                  <span className="bg-emerald-100 text-emerald-800 text-xs px-2 py-1 rounded-full font-medium">
                    Verified
                  </span>
                ) : college.status === "suspended" ? (
                  <span className="bg-red-100 text-red-800 text-xs px-2 py-1 rounded-full font-medium">
                    Suspended
                  </span>
                ) : (
                  <span className="bg-yellow-100 text-yellow-800 text-xs px-2 py-1 rounded-full font-medium">
                    Pending
                  </span>
                )}
              </div>

              <div className="space-y-2 mb-6 flex-1">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Address</span>
                  <span className="font-medium text-right line-clamp-1">
                    {college.address || "N/A"}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Admin</span>
                  <span className="font-medium text-right">
                    {college.adminName || "Pending"}
                  </span>
                </div>
              </div>

              <div className="flex space-x-3 pt-4 border-t border-slate-100">
                {college.status === "pending" && (
                  <button
                    onClick={() => handleVerify(college._id)}
                    className="flex-1 flex items-center justify-center py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors text-sm font-medium"
                  >
                    <CheckCircleIcon className="w-4 h-4 mr-2" /> Verify
                  </button>
                )}
                <button
                  onClick={() => handleSuspend(college._id)}
                  className="flex-1 flex items-center justify-center py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50 transition-colors text-sm font-medium"
                >
                  <NoSymbolIcon className="w-4 h-4 mr-2" /> Suspend
                </button>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {filteredColleges.length === 0 && !loading && (
        <div className="text-center py-12 text-slate-500">
          <BuildingLibraryIcon className="w-16 h-16 mx-auto mb-4 text-slate-300" />
          <p className="text-lg">No colleges found matching criteria.</p>
        </div>
      )}
    </div>
  );
};

export default Colleges;
