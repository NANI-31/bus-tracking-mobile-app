import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  CheckCircleIcon,
  XCircleIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  CloudArrowUpIcon,
  ShieldCheckIcon,
  CurrencyDollarIcon,
} from "@heroicons/react/24/outline";
import {
  getUsers,
  editUser,
  removeUser,
  getCollege,
  activateUserPremium,
  bulkUploadPremium,
} from "../slices/collegeAdminSlice";
import ConfirmationModal from "../../../components/common/ConfirmationModal";

const Users = () => {
  const dispatch = useDispatch();
  const { users, currentCollege, loading } = useSelector(
    (state) => state.collegeAdmin,
  );
  const { userInfo } = useSelector((state) => state.auth);
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [bulkModal, setBulkModal] = useState(false);
  const [uploadFile, setUploadFile] = useState(null);
  const [planType, setPlanType] = useState("monthly");
  const [deleteModal, setDeleteModal] = useState({
    isOpen: false,
    userId: null,
  });
  const [actionModal, setActionModal] = useState({
    isOpen: false,
    userId: null,
  });

  useEffect(() => {
    dispatch(getUsers());
    if (userInfo?.collegeId) {
      dispatch(getCollege(userInfo.collegeId));
    }
  }, [dispatch, userInfo?.collegeId]);

  const filteredUsers = (Array.isArray(users) ? users : []).filter((user) => {
    const matchesFilter = filter === "all" || user.role === filter;
    const matchesSearch =
      user.fullName.toLowerCase().includes(search.toLowerCase()) ||
      user.email.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const handleApprove = (userId) => {
    dispatch(editUser({ userId, data: { approved: true } }));
  };

  const handleReject = (userId) => {
    dispatch(editUser({ userId, data: { approved: false } }));
  };

  const handleDelete = (userId) => {
    setDeleteModal({ isOpen: true, userId });
  };

  const confirmDelete = () => {
    if (deleteModal.userId) {
      dispatch(removeUser(deleteModal.userId));
      setDeleteModal({ isOpen: false, userId: null });
    }
  };

  const handleActivatePremium = (userId, type) => {
    dispatch(activateUserPremium({ userId, planType: type })).then(() => {
      dispatch(getUsers()); // Refresh list
    });
  };

  const handleBulkUpload = (e) => {
    e.preventDefault();
    if (!uploadFile) return;

    const formData = new FormData();
    formData.append("file", uploadFile);
    formData.append("planType", planType);

    dispatch(bulkUploadPremium(formData)).then(() => {
      setBulkModal(false);
      setUploadFile(null);
      dispatch(getUsers());
    });
  };

  const handleOpenActions = (user) => {
    setActionModal({ isOpen: true, userId: user._id });
  };

  const selectedUser = users.find((u) => u._id === actionModal.userId);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">User Management</h1>
        <div className="flex space-x-4 items-center">
          {currentCollege?.allowManualPremium && (
            <button
              onClick={() => setBulkModal(true)}
              className="flex items-center space-x-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors"
            >
              <CloudArrowUpIcon className="w-5 h-5" />
              <span>Bulk Premium</span>
            </button>
          )}
          <div className="relative">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-gray-400" />
            <input
              type="text"
              placeholder="Search users..."
              className="pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <select
            className="border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Roles</option>
            <option value="student">Student</option>
            <option value="driver">Driver</option>
            <option value="coordinator">Coordinator</option>
          </select>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Premium
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            <AnimatePresence>
              {filteredUsers.map((user) => (
                <motion.tr
                  key={user._id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  layout
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold">
                        {user.fullName.charAt(0)}
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">
                          {user.fullName}
                        </div>
                        <div className="text-sm text-gray-500">
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800 uppercase">
                      {user.role}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {user.approved ? (
                      <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                        Approved
                      </span>
                    ) : (
                      <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">
                        Pending
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {user.isPremium ? (
                      <div className="flex flex-col">
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-indigo-100 text-indigo-800">
                          Premium
                        </span>
                        <span className="text-[10px] text-gray-400 mt-1">
                          Until{" "}
                          {new Date(user.premiumUntil).toLocaleDateString()}
                        </span>
                      </div>
                    ) : (
                      <span className="text-gray-400 text-xs italic">
                        Standard
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button
                      onClick={() => handleOpenActions(user)}
                      className="text-indigo-600 hover:text-indigo-900 bg-indigo-50 px-3 py-1.5 rounded-lg transition-colors font-bold"
                    >
                      Open
                    </button>
                  </td>
                </motion.tr>
              ))}
            </AnimatePresence>
            {filteredUsers.length === 0 && (
              <tr>
                <td colSpan="5" className="px-6 py-4 text-center text-gray-500">
                  No users found matching your criteria.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <ConfirmationModal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, userId: null })}
        onConfirm={confirmDelete}
        title="Delete User"
        message="Are you sure you want to permanentely delete this user? This action cannot be undone."
        confirmText="Delete"
      />

      {bulkModal && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md"
          >
            <div className="flex justify-between items-start mb-4">
              <h2 className="text-xl font-bold text-gray-800 flex items-center">
                <CloudArrowUpIcon className="w-6 h-6 mr-2 text-indigo-600" />
                Bulk Premium Activation
              </h2>
              <button
                onClick={() => setBulkModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XCircleIcon className="w-6 h-6" />
              </button>
            </div>
            <p className="text-sm text-gray-500 mb-6">
              Upload an Excel file (.xlsx) containing a column for "Roll Number"
              or "Email" to activate premium in bulk.
            </p>

            <form onSubmit={handleBulkUpload} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Plan Duration
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => setPlanType("monthly")}
                    className={`px-4 py-2 rounded-lg text-sm border transition-colors ${
                      planType === "monthly"
                        ? "bg-indigo-600 text-white border-indigo-600"
                        : "bg-white text-gray-600 border-gray-200"
                    }`}
                  >
                    Monthly (30 Days)
                  </button>
                  <button
                    type="button"
                    onClick={() => setPlanType("semesterly")}
                    className={`px-4 py-2 rounded-lg text-sm border transition-colors ${
                      planType === "semesterly"
                        ? "bg-indigo-600 text-white border-indigo-600"
                        : "bg-white text-gray-600 border-gray-200"
                    }`}
                  >
                    Semesterly (120 Days)
                  </button>
                </div>
              </div>

              <div className="border-2 border-dashed border-gray-200 rounded-xl p-8 text-center bg-gray-50">
                <input
                  type="file"
                  accept=".xlsx, .xls"
                  onChange={(e) => setUploadFile(e.target.files[0])}
                  className="hidden"
                  id="excel-upload"
                />
                <label
                  htmlFor="excel-upload"
                  className="cursor-pointer flex flex-col items-center"
                >
                  <CloudArrowUpIcon className="w-12 h-12 text-gray-400 mb-2" />
                  <span className="text-sm text-gray-600">
                    {uploadFile
                      ? uploadFile.name
                      : "Click to select Excel file"}
                  </span>
                </label>
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  type="button"
                  onClick={() => setBulkModal(false)}
                  className="flex-1 px-4 py-2 border rounded-lg text-gray-600 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!uploadFile}
                  className={`flex-1 px-4 py-2 rounded-lg text-white font-medium ${
                    !uploadFile
                      ? "bg-gray-300 cursor-not-allowed"
                      : "bg-indigo-600 hover:bg-indigo-700"
                  }`}
                >
                  Start Upload
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}

      {/* User Action Modal */}
      <AnimatePresence>
        {actionModal.isOpen && selectedUser && (
          <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden"
            >
              <div className="p-6 border-b flex justify-between items-center bg-gray-50">
                <h2 className="text-xl font-bold text-gray-800">Manage User</h2>
                <button
                  onClick={() =>
                    setActionModal({ isOpen: false, userId: null })
                  }
                  className="text-gray-400 hover:text-gray-600"
                >
                  <XCircleIcon className="w-6 h-6" />
                </button>
              </div>

              <div className="p-6 space-y-6">
                {/* User Info Info */}
                <div className="flex items-center space-x-4">
                  <div className="h-16 w-16 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600 text-2xl font-bold">
                    {selectedUser.fullName.charAt(0)}
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-gray-900">
                      {selectedUser.fullName}
                    </h3>
                    <p className="text-sm text-gray-500">
                      {selectedUser.email}
                    </p>
                    <span className="px-2 py-0.5 inline-flex text-xs font-semibold rounded-full bg-gray-100 text-gray-800 uppercase mt-1">
                      {selectedUser.role}
                    </span>
                  </div>
                </div>

                <div className="space-y-4">
                  {/* Approval Status */}
                  <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                    <div>
                      <h4 className="font-bold text-gray-800">Access Status</h4>
                      <p className="text-xs text-gray-500">
                        {selectedUser.approved
                          ? "This user is currently approved."
                          : "This user is pending approval."}
                      </p>
                    </div>
                    {selectedUser.approved ? (
                      <button
                        onClick={() => handleReject(selectedUser._id)}
                        className="flex items-center space-x-2 text-yellow-600 bg-yellow-50 px-3 py-1.5 rounded-lg hover:bg-yellow-100 transition-colors"
                      >
                        <XCircleIcon className="w-4 h-4" />
                        <span className="text-sm font-bold">Revoke</span>
                      </button>
                    ) : (
                      <button
                        onClick={() => handleApprove(selectedUser._id)}
                        className="flex items-center space-x-2 text-green-600 bg-green-50 px-3 py-1.5 rounded-lg hover:bg-green-100 transition-colors"
                      >
                        <CheckCircleIcon className="w-4 h-4" />
                        <span className="text-sm font-bold">Approve</span>
                      </button>
                    )}
                  </div>

                  {/* Manual Premium - For Students only */}
                  {currentCollege?.allowManualPremium &&
                    selectedUser.role === "student" && (
                      <div className="p-4 border border-indigo-100 bg-indigo-50/30 rounded-xl">
                        <h4 className="font-bold text-indigo-900 mb-3 flex items-center">
                          <CurrencyDollarIcon className="w-5 h-5 mr-1" />
                          Manual Premium Grant
                        </h4>
                        <div className="grid grid-cols-2 gap-3">
                          <button
                            onClick={() =>
                              handleActivatePremium(selectedUser._id, "monthly")
                            }
                            className="flex flex-col items-center justify-center p-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                          >
                            <span className="font-bold text-sm">Monthly</span>
                            <span className="text-[10px] opacity-80">
                              30 Days
                            </span>
                          </button>
                          <button
                            onClick={() =>
                              handleActivatePremium(
                                selectedUser._id,
                                "semesterly",
                              )
                            }
                            className="flex flex-col items-center justify-center p-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                          >
                            <span className="font-bold text-sm">
                              Semesterly
                            </span>
                            <span className="text-[10px] opacity-80">
                              120 Days
                            </span>
                          </button>
                        </div>
                      </div>
                    )}

                  {/* Delete Option */}
                  <div className="pt-4 border-t">
                    <button
                      onClick={() => {
                        handleDelete(selectedUser._id);
                        setActionModal({ isOpen: false, userId: null });
                      }}
                      className="w-full flex items-center justify-center space-x-2 text-red-600 bg-red-50 py-3 rounded-xl hover:bg-red-100 transition-colors font-bold"
                    >
                      <TrashIcon className="w-5 h-5" />
                      <span>Delete Account</span>
                    </button>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default Users;
