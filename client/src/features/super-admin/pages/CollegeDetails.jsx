import React, { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  ArrowLeftIcon,
  BuildingLibraryIcon,
  TrashIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  EnvelopeIcon,
  PhoneIcon,
  UserIcon,
  Cog6ToothIcon,
  CalendarIcon,
  GlobeAltIcon,
} from "@heroicons/react/24/outline";
import {
  getCollegeDetailsAction,
  wipeCollegeDataAction,
} from "../slices/superAdminSlice";
import toast from "react-hot-toast";

const CollegeDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { selectedCollege, loading } = useSelector((state) => state.superAdmin);

  useEffect(() => {
    if (id) {
      dispatch(getCollegeDetailsAction(id));
    }
  }, [id, dispatch]);

  const handleWipe = async () => {
    if (!selectedCollege) return;

    const confirmName = window.prompt(
      `DANGER: This will PERMANENTLY WIPE ALL DATA for ${selectedCollege.name}.\n\nPlease type the college name "${selectedCollege.name}" to confirm:`,
    );

    if (confirmName === selectedCollege.name) {
      const deleteRecord = window.confirm(
        "Do you also want to DELETE the college record itself? (Cancel = Wipe data only)",
      );

      try {
        await dispatch(
          wipeCollegeDataAction({
            collegeId: selectedCollege._id,
            deleteCollegeRecord: deleteRecord,
          }),
        ).unwrap();
        toast.success("College data wiped successfully.");
        if (deleteRecord) {
          navigate("/super-admin/colleges");
        } else {
          dispatch(getCollegeDetailsAction(id));
        }
      } catch (err) {
        toast.error("Wipe failed: " + (err.message || err));
      }
    } else if (confirmName !== null) {
      toast.error("Verification failed. Data wipe cancelled.");
    }
  };

  if (loading && !selectedCollege) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#1E90FF]"></div>
      </div>
    );
  }

  if (!selectedCollege) {
    return (
      <div className="text-center py-12">
        <ExclamationTriangleIcon className="w-16 h-16 text-yellow-500 mx-auto mb-4" />
        <h2 className="text-xl font-bold text-slate-800">College not found</h2>
        <button
          onClick={() => navigate("/super-admin/colleges")}
          className="mt-4 text-[#1E90FF] hover:underline"
        >
          Back to Colleges
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate("/super-admin/colleges")}
            className="p-2 hover:bg-slate-100 rounded-full transition-colors"
          >
            <ArrowLeftIcon className="w-6 h-6 text-slate-600" />
          </button>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-blue-50 text-[#1E90FF] rounded-xl shadow-sm">
              <BuildingLibraryIcon className="w-8 h-8" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-800">
                {selectedCollege.name}
              </h1>
              <p className="text-slate-500 text-sm">
                ID: <span className="font-mono">{selectedCollege._id}</span>
              </p>
            </div>
          </div>
        </div>

        <div className="flex gap-3">
          <span
            className={`px-4 py-1.5 rounded-full text-sm font-semibold shadow-sm ${
              selectedCollege.verified
                ? "bg-green-50 text-green-700 border border-green-200"
                : "bg-yellow-50 text-yellow-700 border border-yellow-200"
            }`}
          >
            {selectedCollege.verified ? "Verified" : "Pending Verification"}
          </span>
          {selectedCollege.suspended && (
            <span className="px-4 py-1.5 rounded-full text-sm font-semibold shadow-sm bg-red-50 text-red-700 border border-red-200">
              Suspended
            </span>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Details */}
        <div className="lg:col-span-2 space-y-6">
          {/* Overview Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100"
          >
            <h3 className="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
              <ShieldCheckIcon className="w-5 h-5 text-[#1E90FF]" /> General
              Information
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-1">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Allowed Domains
                </p>
                <div className="flex flex-wrap gap-2 pt-1">
                  {selectedCollege.allowedDomains?.length > 0 ? (
                    selectedCollege.allowedDomains.map((domain, i) => (
                      <span
                        key={i}
                        className="px-2.5 py-1 bg-slate-50 text-slate-600 text-xs rounded-md border border-slate-200 flex items-center gap-1"
                      >
                        <GlobeAltIcon className="w-3 h-3" /> {domain}
                      </span>
                    ))
                  ) : (
                    <span className="text-slate-400 italic">
                      No domains registered
                    </span>
                  )}
                </div>
              </div>
              <div className="space-y-1">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Admin Information
                </p>
                {selectedCollege.adminId ? (
                  <div className="pt-1">
                    <p className="text-slate-700 font-medium flex items-center gap-2">
                      <UserIcon className="w-4 h-4 text-slate-400" />{" "}
                      {selectedCollege.adminId.name}
                    </p>
                    <p className="text-slate-500 text-sm flex items-center gap-2">
                      <EnvelopeIcon className="w-4 h-4 text-slate-400" />{" "}
                      {selectedCollege.adminId.email}
                    </p>
                  </div>
                ) : (
                  <p className="text-slate-400 italic pt-1">
                    No admin assigned
                  </p>
                )}
              </div>
              <div className="space-y-1">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Bus Fleet Size
                </p>
                <p className="text-slate-700 pt-1 font-bold text-xl">
                  {selectedCollege.busNumbers?.length || 0}{" "}
                  <span className="text-sm font-normal text-slate-500 ml-1">
                    Buses
                  </span>
                </p>
              </div>
              <div className="space-y-1">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Created On
                </p>
                <p className="text-slate-700 pt-1 flex items-center gap-2">
                  <CalendarIcon className="w-4 h-4 text-slate-400" />{" "}
                  {new Date(selectedCollege.createdAt).toLocaleDateString(
                    undefined,
                    { dateStyle: "long" },
                  )}
                </p>
              </div>
            </div>
          </motion.div>

          {/* Shifts Section */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100"
          >
            <h3 className="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
              <CalendarIcon className="w-5 h-5 text-[#1E90FF]" /> Operational
              Shifts
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {selectedCollege.shifts?.map((shift, i) => (
                <div
                  key={i}
                  className="p-4 bg-slate-50 rounded-xl border border-slate-200"
                >
                  <p className="font-bold text-slate-700">{shift.name}</p>
                  <p className="text-sm text-slate-500">ID: {shift.shiftId}</p>
                  <div className="mt-2 flex justify-between text-xs font-semibold text-slate-600">
                    <span className="bg-blue-100 text-blue-700 px-2 py-0.5 rounded">
                      Pickup: {shift.pickupTime || "N/A"}
                    </span>
                    <span className="bg-orange-100 text-orange-700 px-2 py-0.5 rounded">
                      Drop: {shift.dropTime || "N/A"}
                    </span>
                  </div>
                </div>
              ))}
              {(!selectedCollege.shifts ||
                selectedCollege.shifts.length === 0) && (
                <p className="text-slate-400 col-span-2 text-center py-4 bg-slate-50 rounded-xl border border-dashed border-slate-200">
                  No shifts defined for this college.
                </p>
              )}
            </div>
          </motion.div>
        </div>

        {/* Sidebar Settings & Actions */}
        <div className="space-y-6">
          {/* Settings Preview Card */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100"
          >
            <h3 className="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
              <Cog6ToothIcon className="w-5 h-5 text-[#1E90FF]" /> Configuration
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center p-3 bg-slate-50 rounded-xl">
                <span className="text-sm font-medium text-slate-600 font-semibold tracking-tight uppercase text-xs">
                  Manual Premium
                </span>
                <span
                  className={`px-2 py-1 rounded-md text-[10px] uppercase font-bold ${selectedCollege.allowManualPremium ? "bg-green-500 text-white" : "bg-slate-300 text-white"}`}
                >
                  {selectedCollege.allowManualPremium ? "Enabled" : "Disabled"}
                </span>
              </div>

              <div className="flex justify-between items-center p-3 bg-slate-50 rounded-xl">
                <span className="text-sm font-medium text-slate-600 font-semibold tracking-tight uppercase text-xs">
                  Total Shifts
                </span>
                <span className="font-bold text-slate-700">
                  {selectedCollege.shiftCount || 0}
                </span>
              </div>

              <div className="pt-2">
                <p className="text-[10px] font-bold text-slate-400 uppercase mb-2">
                  Internal Metadata (Raw Settings)
                </p>
                <pre className="p-3 bg-slate-900 text-slate-200 rounded-xl text-[10px] overflow-x-auto max-h-[300px] scrollbar-thin scrollbar-thumb-slate-700">
                  {JSON.stringify(selectedCollege.settings || {}, null, 2)}
                </pre>
              </div>
            </div>
          </motion.div>

          {/* Danger Zone */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-red-50 p-6 rounded-2xl shadow-sm border border-red-100"
          >
            <h3 className="text-lg font-bold text-red-800 mb-4 flex items-center gap-2">
              <ExclamationTriangleIcon className="w-5 h-5" /> Danger Zone
            </h3>
            <p className="text-sm text-red-600 mb-6 leading-relaxed">
              Operations in this section are destructive and cannot be undone.
              Exercise extreme caution.
            </p>
            <button
              onClick={handleWipe}
              className="w-full py-3 bg-red-600 text-white rounded-xl font-bold hover:bg-red-700 transition-all shadow-md shadow-red-200 flex items-center justify-center gap-2 mb-3"
            >
              <TrashIcon className="w-5 h-5" /> Wipe College Data
            </button>
            <p className="text-[10px] text-red-400 text-center italic font-semibold">
              Requires multi-step verification.
            </p>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

export default CollegeDetails;
