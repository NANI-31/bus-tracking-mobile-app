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
  unsuspendCollegeAction,
  suspendCollegeAction,
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
  const [expandedCardId, setExpandedCardId] = useState(null);

  useEffect(() => {
    dispatch(getColleges());
  }, [dispatch]);

  const filteredColleges = colleges.filter((college) => {
    const collegeStatus = college.suspended
      ? "suspended"
      : college.verified
      ? "verified"
      : "pending";
    const matchesFilter = filter === "all" || collegeStatus === filter;
    const matchesSearch =
      college.name.toLowerCase().includes(search.toLowerCase()) ||
      (college.email || "").toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const handleVerify = (collegeId) => {
    if (window.confirm("Are you sure you want to verify this college?")) {
      dispatch(verifyCollegeAction(collegeId))
        .unwrap()
        .then(() => toast.success("College verified successfully"))
        .catch((err) => toast.error("Failed to verify college: " + (err.message || err)));
    }
  };

  const handleSuspend = (collegeId) => {
    const reason = window.prompt("Enter the reason for suspension:");
    if (reason !== null && reason.trim() !== "") {
      dispatch(suspendCollegeAction({ collegeId, reason: reason.trim() }))
        .unwrap()
        .then(() => toast.success("College suspended successfully"))
        .catch((err) => toast.error("Failed to suspend college: " + (err.message || err)));
    }
  };

  const handleUnsuspend = (collegeId) => {
    if (window.confirm("Are you sure you want to unsuspend this college?")) {
      dispatch(unsuspendCollegeAction(collegeId))
        .unwrap()
        .then(() => toast.success("College unsuspended successfully"))
        .catch((err) => toast.error("Failed to unsuspend college: " + (err.message || err)));
    }
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
    <div className="space-y-6 sm:space-y-8 text-text-theme-primary">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-scale-h1 font-black tracking-tight text-text-theme-primary">
            College Management
          </h1>
          <p className="text-text-theme-secondary text-xs sm:text-sm mt-1">
            Manage registered institutions, verify applications, configure premium billing, or perform maintenance wipes.
          </p>
        </div>
      </div>

      {/* Search and Filters Card */}
      <div className="bg-background-paper border border-border-theme rounded-3xl p-4 sm:p-6 shadow-sm flex flex-col md:flex-row items-stretch md:items-center gap-4">
        {/* Search Input */}
        <div className="relative flex-1">
          <MagnifyingGlassIcon className="w-5 h-5 absolute left-4 top-3 text-text-theme-secondary/55" />
          <input
            type="text"
            placeholder="Search colleges by name or email..."
            className="w-full pl-11 pr-4 py-2.5 bg-background-default border border-border-theme rounded-2xl focus:outline-none focus:ring-2 focus:ring-[#1E90FF] focus:border-transparent text-text-theme-primary placeholder-text-theme-secondary/45 text-sm transition-all duration-200"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        {/* Filters and Actions */}
        <div className="flex flex-wrap items-center gap-3">
          <select
            className="flex-1 md:flex-none bg-background-default border border-border-theme text-text-theme-primary rounded-2xl px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-[#1E90FF] text-sm min-w-[140px] cursor-pointer transition-all duration-200"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="verified">Verified</option>
            <option value="suspended">Suspended</option>
          </select>

          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => setIsModalOpen(true)}
            className="flex items-center justify-center px-5 py-2.5 bg-[#1E90FF] text-white rounded-2xl hover:bg-[#1E90FF]/90 transition-all text-sm font-bold shadow-md shadow-blue-500/10 cursor-pointer shrink-0"
          >
            <PlusIcon className="w-5 h-5 mr-2 shrink-0" />
            <span>Add College</span>
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => handleWipe({ _id: "all", name: "ALL COLLEGES" })}
            className="flex items-center justify-center px-5 py-2.5 bg-rose-500/10 hover:bg-rose-600 text-rose-500 hover:text-white border border-rose-500/20 rounded-2xl transition-all text-sm font-bold shadow-sm cursor-pointer shrink-0"
          >
            <TrashIcon className="w-5 h-5 mr-2 shrink-0" />
            <span>Wipe All Data</span>
          </motion.button>
        </div>
      </div>

      {/* Grid Layout of Colleges */}
      {loading && (!colleges || colleges.length === 0) ? (
        <div className="flex items-center justify-center min-h-[300px]">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#1E90FF]"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <AnimatePresence>
            {filteredColleges.map((college, idx) => {
              const collegeStatus = college.suspended
                ? "suspended"
                : college.verified
                ? "verified"
                : "pending";
              const isExpanded = expandedCardId === college._id;
              return (
                <motion.div
                  key={college._id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ duration: 0.3, delay: idx * 0.05 }}
                  layout
                  className="bg-background-paper rounded-3xl border border-border-theme p-6 flex flex-col hover:shadow-xl hover:border-primary-main/30 dark:hover:border-primary-main/20 hover:shadow-primary-main/5 transition-all duration-350 relative overflow-hidden group"
                >
                  {/* Decorative background glow */}
                  <div className="absolute -right-8 -top-8 w-24 h-24 bg-[#1E90FF]/5 rounded-full blur-xl group-hover:bg-[#1E90FF]/10 transition-colors duration-350 pointer-events-none" />

                  {/* College Info Header */}
                  <div className="flex justify-between items-start mb-6 gap-4 relative z-10">
                    <div className="flex items-center space-x-3.5 min-w-0 flex-1">
                      <div className="shrink-0 p-3.5 bg-primary-main/10 text-[#1E90FF] rounded-2xl group-hover:scale-110 transition-transform duration-300">
                        <BuildingLibraryIcon className="w-7 h-7" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <h3
                          className="text-lg font-black text-text-theme-primary tracking-tight leading-snug truncate hover:text-[#1E90FF] cursor-pointer transition-colors"
                          onClick={() => navigate(`/super-admin/colleges/${college._id}`)}
                          title={college.name}
                        >
                          {college.name}
                        </h3>
                        <p
                          className="text-xs text-text-theme-secondary/80 truncate mt-0.5"
                          title={college.email}
                        >
                          {college.email}
                        </p>
                      </div>
                    </div>

                    {/* Status Badge */}
                    <div className="shrink-0 pt-1">
                      {collegeStatus === "verified" ? (
                        <span className="bg-emerald-500/10 dark:bg-emerald-500/5 text-emerald-600 dark:text-emerald-400 text-[10px] uppercase tracking-wider px-2.5 py-1 rounded-lg font-black border border-emerald-500/20 dark:border-emerald-500/10">
                          Verified
                        </span>
                      ) : collegeStatus === "suspended" ? (
                        <span className="bg-rose-500/10 dark:bg-rose-500/5 text-rose-600 dark:text-rose-400 text-[10px] uppercase tracking-wider px-2.5 py-1 rounded-lg font-black border border-rose-500/20 dark:border-rose-500/10">
                          Suspended
                        </span>
                      ) : (
                        <span className="bg-amber-500/10 dark:bg-amber-500/5 text-amber-600 dark:text-amber-400 text-[10px] uppercase tracking-wider px-2.5 py-1 rounded-lg font-black border border-amber-500/20 dark:border-amber-500/10 flex items-center gap-1">
                          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                          Pending
                        </span>
                      )}
                    </div>
                  </div>

                  {/* College Info Fields */}
                  <div className="space-y-3 mb-6 flex-1 relative z-10">
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-text-theme-secondary font-semibold uppercase tracking-wider text-[10px]">
                        Address
                      </span>
                      <span className="font-bold text-text-theme-primary text-right max-w-[70%] truncate" title={college.address || "N/A"}>
                        {college.address || "Not Configured"}
                      </span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-text-theme-secondary font-semibold uppercase tracking-wider text-[10px]">
                        Primary Administrator
                      </span>
                      <span className="font-bold text-text-theme-primary text-right truncate" title={college.adminName || "Pending Setup"}>
                        {college.adminName || "Pending Setup"}
                      </span>
                    </div>

                    <div className="flex justify-between items-center pt-3 border-t border-border-theme/40 mt-3">
                      <span className="text-xs font-bold text-text-theme-primary flex items-center">
                        <CurrencyDollarIcon className="w-4.5 h-4.5 mr-1.5 text-text-theme-secondary/80" />
                        Manual Premium Override
                      </span>
                      <button
                        onClick={() =>
                          handleToggleManualPremium(
                            college._id,
                            college.allowManualPremium,
                          )
                        }
                        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-all duration-300 focus:outline-none cursor-pointer ${
                          college.allowManualPremium
                            ? "bg-[#1E90FF] shadow-[0_0_10px_rgba(30,144,255,0.35)]"
                            : "bg-slate-200 dark:bg-slate-800"
                        }`}
                      >
                        <span
                          className={`${
                            college.allowManualPremium
                              ? "translate-x-6"
                              : "translate-x-1"
                          } inline-block h-4 w-4 transform rounded-full bg-white transition-all duration-300 shadow-sm`}
                        />
                      </button>
                    </div>

                    {/* Interactive Suspension Logs/Timeline */}
                    <div className="pt-3 border-t border-border-theme/40 mt-3">
                      <button
                        onClick={() => setExpandedCardId(isExpanded ? null : college._id)}
                        className="text-xs font-bold text-[#1E90FF] flex items-center hover:underline cursor-pointer focus:outline-none"
                      >
                        <BuildingLibraryIcon className="w-3.5 h-3.5 mr-1" />
                        {isExpanded ? "Hide Audit Timeline" : "View Audit Timeline"}
                      </button>

                      <AnimatePresence>
                        {isExpanded && (
                          <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: "auto", opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            transition={{ duration: 0.25 }}
                            className="overflow-hidden mt-3 pl-1"
                          >
                            <div className="relative border-l-2 border-slate-200 dark:border-slate-800 pl-4 space-y-3.5 py-1 text-xs">
                              {/* Registered event */}
                              <div className="relative">
                                <span className="absolute left-[-21px] top-1 w-2.5 h-2.5 rounded-full bg-blue-500 border-2 border-white dark:border-slate-900" />
                                <p className="font-bold text-text-theme-primary">Registered</p>
                                <p className="text-[10px] text-text-theme-secondary/80">
                                  {new Date(college.createdAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })}
                                </p>
                              </div>

                              {/* Verified event */}
                              {college.verified && (
                                <div className="relative">
                                  <span className="absolute left-[-21px] top-1 w-2.5 h-2.5 rounded-full bg-emerald-500 border-2 border-white dark:border-slate-900" />
                                  <p className="font-bold text-text-theme-primary">Verified</p>
                                  <p className="text-[10px] text-text-theme-secondary/80">
                                    {college.verifiedAt 
                                      ? new Date(college.verifiedAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
                                      : "Autoverified / Pre-configured"}
                                  </p>
                                </div>
                              )}

                              {/* Suspended event */}
                              {college.suspended && (
                                <div className="relative">
                                  <span className="absolute left-[-21px] top-1 w-2.5 h-2.5 rounded-full bg-rose-500 border-2 border-white dark:border-slate-900" />
                                  <p className="font-bold text-rose-500">Suspended</p>
                                  {college.suspensionReason && (
                                    <p className="text-text-theme-primary font-semibold text-[11px] mt-0.5">
                                      Reason: "{college.suspensionReason}"
                                    </p>
                                  )}
                                  <p className="text-[10px] text-text-theme-secondary/80">
                                    {college.suspendedAt 
                                      ? new Date(college.suspendedAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
                                      : "N/A"}
                                  </p>
                                </div>
                              )}
                            </div>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex items-center space-x-2 pt-4 border-t border-border-theme/40 relative z-10">
                    {collegeStatus === "pending" && (
                      <motion.button
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={() => handleVerify(college._id)}
                        className="flex-1 flex items-center justify-center py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl transition-colors text-xs font-bold shadow-sm shadow-emerald-500/10 cursor-pointer"
                      >
                        <CheckCircleIcon className="w-4 h-4 mr-1.5" />
                        Verify
                      </motion.button>
                    )}
                    
                    {collegeStatus !== "suspended" ? (
                      <motion.button
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={() => handleSuspend(college._id)}
                        className="flex-1 flex items-center justify-center py-2 border border-rose-500/35 hover:bg-rose-500 hover:text-white text-rose-500 dark:text-rose-400 rounded-xl transition-all text-xs font-bold cursor-pointer"
                      >
                        <NoSymbolIcon className="w-4 h-4 mr-1.5" />
                        Suspend
                      </motion.button>
                    ) : (
                      <motion.button
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={() => handleUnsuspend(college._id)}
                        className="flex-1 flex items-center justify-center py-2 border border-emerald-500/35 hover:bg-emerald-500 hover:text-white text-emerald-500 dark:text-emerald-400 rounded-xl transition-all text-xs font-bold cursor-pointer"
                      >
                        <CheckCircleIcon className="w-4 h-4 mr-1.5" />
                        Unsuspend
                      </motion.button>
                    )}

                    <motion.button
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => handleWipe(college)}
                      className="p-2 border border-rose-500/35 text-rose-500 dark:text-rose-400 hover:bg-rose-600 hover:text-white rounded-xl transition-all cursor-pointer"
                      title="Wipe Data"
                    >
                      <TrashIcon className="w-4.5 h-4.5" />
                    </motion.button>
                  </div>
                </motion.div>
              );
            })}
          </AnimatePresence>
        </div>
      )}

      {/* Empty State */}
      {filteredColleges.length === 0 && !loading && (
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center py-16 px-6 bg-background-paper border border-dashed border-border-theme rounded-3xl"
        >
          <div className="w-16 h-16 mx-auto mb-4 bg-primary-main/10 rounded-full flex items-center justify-center text-[#1E90FF]">
            <BuildingLibraryIcon className="w-8 h-8" />
          </div>
          <h3 className="text-lg font-bold text-text-theme-primary">No colleges found</h3>
          <p className="text-text-theme-secondary text-sm mt-1 max-w-sm mx-auto">
            Try adjusting your search query or filter status, or register a new college to get started.
          </p>
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => setIsModalOpen(true)}
            className="mt-6 px-6 py-2.5 bg-[#1E90FF] text-white rounded-2xl font-bold hover:bg-[#1E90FF]/90 transition-all text-sm shadow-md shadow-blue-500/10 cursor-pointer"
          >
            Add Your First College
          </motion.button>
        </motion.div>
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
