import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  CheckCircleIcon,
  XCircleIcon,
  MagnifyingGlassIcon,
  BuildingLibraryIcon,
  NoSymbolIcon,
  CurrencyDollarIcon,
  TrashIcon,
  PlusIcon,
} from "@heroicons/react/24/outline";
import {
  getColleges,
  verifyCollegeAction,
  toggleManualPremiumAction,
  wipeCollegeDataAction,
  createCollegeAction,
} from "../slices/superAdminSlice";
import { toast } from "react-hot-toast";
import CollegeFormModal from "../components/CollegeFormModal";

const Colleges = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { colleges, loading } = useSelector((state) => state.superAdmin);
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);

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

  const handleToggleManualPremium = (collegeId, currentStatus) => {
    dispatch(
      toggleManualPremiumAction({
        collegeId,
        allowManualPremium: !currentStatus,
      }),
    );
  };

  const handleWipe = async (college) => {
    const confirmName = window.prompt(
      `DANGER: This will PERMANENTLY WIPE ALL DATA (Buses, Users, Trips, SOS, Notifications) for ${college.name}.\n\nPlease type the college name "${college.name}" to confirm:`,
    );

    if (confirmName === college.name) {
      const deleteRecord = window.confirm(
        "Do you also want to DELETE the college record itself? (Cancel = Wipe data only)",
      );

      try {
        await dispatch(
          wipeCollegeDataAction({
            collegeId: college._id,
            deleteCollegeRecord: deleteRecord,
          }),
        ).unwrap();
        alert("Wipe successful.");
      } catch (err) {
        alert("Wipe failed: " + (err.message || err));
      }
    } else if (confirmName !== null) {
      alert("Verification failed. Data wipe cancelled.");
    }
  };

  const handleCreateCollege = async (collegeData) => {
    setCreateLoading(true);
    try {
      await dispatch(createCollegeAction(collegeData)).unwrap();
      toast.success("College created successfully");
      setIsModalOpen(false);
    } catch (error) {
      toast.error(error.message || "Failed to create college");
    } finally {
      setCreateLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
        <h1 className="text-2xl font-bold text-slate-800 shrink-0">
          College Management
        </h1>
        <div className="flex flex-wrap items-center gap-3 w-full lg:w-auto">
          <div className="relative flex-1 min-w-[200px] max-w-full md:max-w-xs">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search colleges..."
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1E90FF] bg-white text-sm"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <select
            className="flex-1 md:flex-none border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-[#1E90FF] bg-white text-sm min-w-[120px]"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="verified">Verified</option>
            <option value="suspended">Suspended</option>
          </select>
          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center justify-center px-4 py-2 bg-[#1E90FF] text-white rounded-lg hover:bg-[#1E90FF]/90 transition-all text-sm font-bold shadow-sm shrink-0"
          >
            <PlusIcon className="w-5 h-5 md:mr-2" />
            <span className="hidden md:inline">Add College</span>
          </button>
          <button
            onClick={() => handleWipe({ _id: "all", name: "ALL COLLEGES" })}
            className="flex items-center justify-center px-4 py-2 bg-red-50 text-red-600 border border-red-200 rounded-lg hover:bg-red-600 hover:text-white transition-all text-sm font-bold shadow-sm shrink-0"
          >
            <TrashIcon className="w-5 h-5 md:mr-2" />
            <span className="hidden md:inline">Wipe All Data</span>
          </button>
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
              <div className="flex justify-between items-start mb-4 gap-4">
                <div className="flex items-center space-x-3 min-w-0 flex-1">
                  <div className="shrink-0 p-3 bg-indigo-50 rounded-lg">
                    <BuildingLibraryIcon className="w-8 h-8 text-[#1E90FF]" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <h3
                      className="text-lg font-bold text-slate-800 line-clamp-2 cursor-pointer hover:text-[#1E90FF] transition-colors"
                      onClick={() =>
                        navigate(`/super-admin/colleges/${college._id}`)
                      }
                      title={college.name}
                    >
                      {college.name}
                    </h3>
                    <p
                      className="text-sm text-slate-500 truncate"
                      title={college.email}
                    >
                      {college.email}
                    </p>
                  </div>
                </div>
                <div className="shrink-0 pt-1">
                  {college.status === "verified" ? (
                    <span className="bg-emerald-100 text-emerald-800 text-[10px] uppercase tracking-wider px-2 py-1 rounded-md font-bold border border-emerald-200">
                      Verified
                    </span>
                  ) : college.status === "suspended" ? (
                    <span className="bg-red-100 text-red-800 text-[10px] uppercase tracking-wider px-2 py-1 rounded-md font-bold border border-red-200">
                      Suspended
                    </span>
                  ) : (
                    <span className="bg-amber-100 text-amber-800 text-[10px] uppercase tracking-wider px-2 py-1 rounded-md font-bold border border-amber-200">
                      Pending
                    </span>
                  )}
                </div>
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
                <div className="flex justify-between items-center pt-2">
                  <span className="text-sm text-slate-500 flex items-center">
                    <CurrencyDollarIcon className="w-4 h-4 mr-1" />
                    Manual Premium
                  </span>
                  <button
                    onClick={() =>
                      handleToggleManualPremium(
                        college._id,
                        college.allowManualPremium,
                      )
                    }
                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-[#1E90FF] focus:ring-offset-2 ${
                      college.allowManualPremium
                        ? "bg-[#1E90FF]"
                        : "bg-slate-200"
                    }`}
                  >
                    <span
                      className={`${
                        college.allowManualPremium
                          ? "translate-x-6"
                          : "translate-x-1"
                      } inline-block h-4 w-4 transform rounded-full bg-white transition-transform`}
                    />
                  </button>
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
                <button
                  onClick={() => handleWipe(college)}
                  className="px-3 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-600 hover:text-white transition-all text-sm font-medium"
                  title="Wipe Data"
                >
                  <TrashIcon className="w-4 h-4" />
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
          <button
            onClick={() => setIsModalOpen(true)}
            className="mt-4 px-6 py-2 bg-[#1E90FF] text-white rounded-lg font-bold hover:bg-[#1E90FF]/90 transition-colors"
          >
            Add Your First College
          </button>
        </div>
      )}

      <CollegeFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleCreateCollege}
        loading={createLoading}
      />
    </div>
  );
};

export default Colleges;
