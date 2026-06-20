import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  TicketIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  CheckCircleIcon,
  ArrowPathIcon,
  XMarkIcon,
  CreditCardIcon,
  SparklesIcon,
} from "@heroicons/react/24/outline";
import {
  getPlansAction,
  createPlanAction,
  updatePlanAction,
  deletePlanAction,
} from "@/features/super-admin/slices/superAdminSlice";
import toast from "react-hot-toast";

const SubscriptionPlans = () => {
  const dispatch = useDispatch();
  const { plans, loading, error } = useSelector((state) => state.superAdmin);
  const [showModal, setShowModal] = useState(false);
  const [editingPlan, setEditingPlan] = useState(null);

  // Form State
  const [name, setName] = useState("");
  const [alias, setAlias] = useState("");
  const [price, setPrice] = useState("");
  const [originalPrice, setOriginalPrice] = useState("");
  const [durationDays, setDurationDays] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [isBestValue, setIsBestValue] = useState(false);
  const [features, setFeatures] = useState([]);
  const [newFeatureText, setNewFeatureText] = useState("");

  useEffect(() => {
    dispatch(getPlansAction());
  }, [dispatch]);

  const openAddModal = () => {
    setEditingPlan(null);
    setName("");
    setAlias("");
    setPrice("");
    setOriginalPrice("");
    setDurationDays("");
    setIsActive(true);
    setIsBestValue(false);
    setFeatures([]);
    setNewFeatureText("");
    setShowModal(true);
  };

  const openEditModal = (plan) => {
    setEditingPlan(plan);
    setName(plan.name || "");
    setAlias(plan.alias || "");
    setPrice(plan.price || "");
    setOriginalPrice(plan.originalPrice || "");
    setDurationDays(plan.durationDays || "");
    setIsActive(plan.isActive !== undefined ? plan.isActive : true);
    setIsBestValue(plan.isBestValue !== undefined ? plan.isBestValue : false);
    setFeatures(plan.features ? [...plan.features] : []);
    setNewFeatureText("");
    setShowModal(true);
  };

  const handleAddFeature = (e) => {
    e.preventDefault();
    const text = newFeatureText.trim();
    if (text) {
      setFeatures([...features, text]);
      setNewFeatureText("");
    }
  };

  const handleRemoveFeature = (index) => {
    setFeatures(features.filter((_, idx) => idx !== index));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!name.trim() || !alias.trim() || !price || !durationDays) {
      toast.error("Please fill in all required fields.");
      return;
    }

    const payload = {
      name: name.trim(),
      alias: alias.trim().toLowerCase(),
      price: Number(price),
      durationDays: Number(durationDays),
      features,
      isActive,
      isBestValue,
      originalPrice: originalPrice ? Number(originalPrice) : undefined,
    };

    try {
      if (editingPlan) {
        await dispatch(
          updatePlanAction({ planId: editingPlan._id, planData: payload }),
        ).unwrap();
        toast.success("Plan updated successfully");
      } else {
        await dispatch(createPlanAction(payload)).unwrap();
        toast.success("Plan created successfully");
      }
      setShowModal(false);
    } catch (err) {
      toast.error(err.message || "Failed to save plan");
    }
  };

  const handleDelete = async (planId) => {
    if (window.confirm("Are you sure you want to permanently delete this plan?")) {
      try {
        await dispatch(deletePlanAction(planId)).unwrap();
        toast.success("Plan deleted successfully");
      } catch (err) {
        toast.error(err.message || "Failed to delete plan");
      }
    }
  };

  const handleToggleActive = async (plan) => {
    try {
      await dispatch(
        updatePlanAction({
          planId: plan._id,
          planData: { ...plan, isActive: !plan.isActive },
        }),
      ).unwrap();
      toast.success(`Plan "${plan.name}" status updated`);
    } catch (err) {
      toast.error(err.message || "Failed to toggle status");
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Card */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between sm:items-center bg-white dark:bg-slate-900 p-6 rounded-xl shadow-sm border border-slate-200 dark:border-slate-800 transition-colors">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-slate-800 dark:text-white flex items-center">
            <TicketIcon className="w-6 h-6 sm:w-8 sm:h-8 mr-2 text-indigo-500" />
            Subscription Plans Management
          </h1>
          <p className="text-slate-500 dark:text-slate-400 text-xs sm:text-sm mt-1">
            Create, edit, or toggle access to student subscription packages
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => dispatch(getPlansAction())}
            className="p-2 border border-slate-300 dark:border-slate-700 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 transition-colors"
          >
            <ArrowPathIcon className={`w-5 h-5 ${loading ? "animate-spin" : ""}`} />
          </button>
          <button
            onClick={openAddModal}
            className="flex items-center justify-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-semibold shadow-md shadow-indigo-500/20 active:scale-95 transition-all text-sm"
          >
            <PlusIcon className="w-5 h-5 mr-1" />
            Add Plan
          </button>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-red-500/10 border border-red-500/20 text-red-600 dark:text-red-400 rounded-xl text-sm">
          Error loading plans: {error}
        </div>
      )}

      {/* Plans List Grid */}
      {loading && plans.length === 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1, 2, 3].map((n) => (
            <div
              key={n}
              className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 h-[340px] animate-pulse space-y-4"
            >
              <div className="h-6 w-2/3 bg-slate-200 dark:bg-slate-800 rounded"></div>
              <div className="h-4 w-1/3 bg-slate-200 dark:bg-slate-800 rounded"></div>
              <div className="h-10 w-1/2 bg-slate-200 dark:bg-slate-800 rounded mt-8"></div>
              <div className="space-y-2 mt-8">
                <div className="h-3 bg-slate-200 dark:bg-slate-800 rounded w-full"></div>
                <div className="h-3 bg-slate-200 dark:bg-slate-800 rounded w-5/6"></div>
                <div className="h-3 bg-slate-200 dark:bg-slate-800 rounded w-4/5"></div>
              </div>
            </div>
          ))}
        </div>
      ) : plans.length === 0 ? (
        <div className="bg-white dark:bg-slate-900 p-12 text-center border border-slate-200 dark:border-slate-800 rounded-xl max-w-lg mx-auto">
          <CreditCardIcon className="w-16 h-16 mx-auto text-slate-300 dark:text-slate-700 mb-4" />
          <h3 className="text-lg font-bold text-slate-700 dark:text-white mb-2">No Plans Configured</h3>
          <p className="text-slate-500 dark:text-slate-400 text-sm mb-6">
            Get started by creating your first subscription package that students can purchase.
          </p>
          <button
            onClick={openAddModal}
            className="px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-semibold text-sm shadow-sm transition-all"
          >
            Create Your First Plan
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {plans.map((plan) => (
            <motion.div
              layout
              key={plan._id}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all flex flex-col justify-between"
            >
              {/* Premium Gradient Strip */}
              <div
                className={`h-1.5 w-full ${plan.isBestValue ? "bg-gradient-to-r from-amber-500 to-orange-500" : "bg-gradient-to-r from-indigo-500 to-purple-500"}`}
              ></div>

              <div className="p-6 flex-1">
                {/* Title & Badge */}
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <h3 className="text-lg font-bold text-slate-800 dark:text-white truncate">
                      {plan.name}
                    </h3>
                    <span className="inline-block text-[10px] font-mono bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 px-2 py-0.5 rounded mt-1">
                      alias: {plan.alias}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    {plan.isBestValue && (
                      <span className="flex items-center text-[9px] font-extrabold bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20 px-2 py-0.5 rounded-full uppercase tracking-wider">
                        <SparklesIcon className="w-3 h-3 mr-0.5" />
                        Best Value
                      </span>
                    )}
                    <label className="relative inline-flex items-center cursor-pointer select-none">
                      <input
                        type="checkbox"
                        checked={plan.isActive}
                        onChange={() => handleToggleActive(plan)}
                        className="sr-only peer"
                      />
                      <div className="w-9 h-5 bg-slate-200 dark:bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:height-4 after:width-4 after:h-4 after:w-4 after:transition-all peer-checked:bg-emerald-500"></div>
                    </label>
                  </div>
                </div>

                <hr className="my-4 border-slate-100 dark:border-slate-800" />

                {/* Price section */}
                <div className="flex items-baseline justify-between mb-4">
                  <div>
                    <div className="text-xs text-slate-400 uppercase tracking-widest font-black">Price</div>
                    <div className="flex items-baseline gap-2 mt-1">
                      <span className="text-3xl font-black text-emerald-500 tracking-tight">
                        ₹{plan.price}
                      </span>
                      {plan.originalPrice && (
                        <span className="text-sm text-slate-400 line-through">
                          ₹{plan.originalPrice}
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-xs text-slate-400 uppercase tracking-widest font-black">Duration</div>
                    <span className="text-base font-bold text-slate-800 dark:text-white mt-1 block">
                      {plan.durationDays} Days
                    </span>
                  </div>
                </div>

                <hr className="my-4 border-slate-100 dark:border-slate-800" />

                {/* Features list */}
                <div>
                  <div className="text-xs text-slate-400 uppercase tracking-widest font-black mb-3">
                    Features Include
                  </div>
                  <ul className="space-y-2">
                    {plan.features?.map((feature, idx) => (
                      <li key={idx} className="flex items-start text-sm text-slate-600 dark:text-slate-300">
                        <CheckCircleIcon className="w-5 h-5 text-emerald-500 mr-2 shrink-0" />
                        <span className="truncate">{feature}</span>
                      </li>
                    ))}
                    {(!plan.features || plan.features.length === 0) && (
                      <li className="text-xs text-slate-400 italic">No features listed</li>
                    )}
                  </ul>
                </div>
              </div>

              {/* Actions Footer */}
              <div className="bg-slate-50 dark:bg-slate-900/50 p-4 border-t border-slate-100 dark:border-slate-800/80 flex items-center justify-end gap-2">
                <button
                  onClick={() => handleDelete(plan._id)}
                  className="flex items-center px-3 py-1.5 border border-red-200 dark:border-red-900 text-red-600 hover:bg-red-50 dark:hover:bg-red-950/20 rounded-lg text-xs font-semibold transition-colors"
                >
                  <TrashIcon className="w-4 h-4 mr-1" />
                  Delete
                </button>
                <button
                  onClick={() => openEditModal(plan)}
                  className="flex items-center px-3 py-1.5 bg-indigo-50 dark:bg-indigo-950/30 hover:bg-indigo-100 dark:hover:bg-indigo-900/40 text-indigo-600 dark:text-indigo-400 rounded-lg text-xs font-semibold transition-colors"
                >
                  <PencilIcon className="w-4 h-4 mr-1" />
                  Edit Plan
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {/* Modal Dialog */}
      <AnimatePresence>
        {showModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowModal(false)}
              className="absolute inset-0 bg-slate-900/60 backdrop-blur-xs"
            ></motion.div>

            {/* Dialog Container */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="relative bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl w-full max-w-lg overflow-hidden flex flex-col max-h-[85vh] text-slate-800 dark:text-white"
            >
              {/* Header */}
              <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
                <h3 className="text-lg font-bold">
                  {editingPlan ? "Edit Subscription Plan" : "Create Subscription Plan"}
                </h3>
                <button
                  onClick={() => setShowModal(false)}
                  className="p-1.5 hover:bg-slate-100 dark:hover:bg-slate-850 rounded-lg text-slate-400 hover:text-slate-600 transition-colors"
                >
                  <XMarkIcon className="w-5 h-5" />
                </button>
              </div>

              {/* Form Content */}
              <form onSubmit={handleSubmit} className="p-6 overflow-y-auto space-y-4 flex-1">
                {/* Plan Name */}
                <div className="space-y-1">
                  <label className="text-xs font-bold uppercase tracking-wider text-slate-400">
                    Plan Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g., Premium Monthly"
                    className="w-full px-4 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                  />
                </div>

                {/* Plan Alias */}
                <div className="space-y-1">
                  <label className="text-xs font-bold uppercase tracking-wider text-slate-400">
                    Plan Alias (Unique ID) *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g., premium_30"
                    className="w-full px-4 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500 font-mono"
                    value={alias}
                    onChange={(e) => setAlias(e.target.value)}
                  />
                </div>

                {/* Price & Original Price */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-xs font-bold uppercase tracking-wider text-slate-400">
                      Price (₹) *
                    </label>
                    <input
                      type="number"
                      required
                      min="0"
                      placeholder="e.g., 200"
                      className="w-full px-4 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500"
                      value={price}
                      onChange={(e) => setPrice(e.target.value)}
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="text-xs font-bold uppercase tracking-wider text-slate-400">
                      Original Price (₹)
                    </label>
                    <input
                      type="number"
                      min="0"
                      placeholder="e.g., 250 (optional)"
                      className="w-full px-4 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500"
                      value={originalPrice}
                      onChange={(e) => setOriginalPrice(e.target.value)}
                    />
                  </div>
                </div>

                {/* Duration in Days */}
                <div className="space-y-1">
                  <label className="text-xs font-bold uppercase tracking-wider text-slate-400">
                    Duration (Days) *
                  </label>
                  <input
                    type="number"
                    required
                    min="1"
                    placeholder="e.g., 30"
                    className="w-full px-4 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500"
                    value={durationDays}
                    onChange={(e) => setDurationDays(e.target.value)}
                  />
                </div>

                {/* Switch Checks */}
                <div className="grid grid-cols-2 gap-4 pt-2">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={isActive}
                      onChange={(e) => setIsActive(e.target.checked)}
                      className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                    />
                    <span className="text-sm font-semibold text-slate-600 dark:text-slate-300">Is Plan Active</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={isBestValue}
                      onChange={(e) => setIsBestValue(e.target.checked)}
                      className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                    />
                    <span className="text-sm font-semibold text-slate-600 dark:text-slate-300">Best Value Highlight</span>
                  </label>
                </div>

                <hr className="border-slate-100 dark:border-slate-800" />

                {/* Features Section */}
                <div className="space-y-3">
                  <label className="text-xs font-bold uppercase tracking-wider text-slate-400 block">
                    Plan Features List
                  </label>

                  {/* Add Feature input */}
                  <div className="flex gap-2">
                    <input
                      type="text"
                      placeholder="Add a new feature..."
                      className="flex-1 px-4 py-1.5 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500 text-sm"
                      value={newFeatureText}
                      onChange={(e) => setNewFeatureText(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          handleAddFeature(e);
                        }
                      }}
                    />
                    <button
                      type="button"
                      onClick={handleAddFeature}
                      className="px-3 py-1.5 bg-indigo-50 dark:bg-indigo-950 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-900 rounded-lg text-sm font-semibold hover:bg-indigo-100 dark:hover:bg-indigo-900/50"
                    >
                      Add
                    </button>
                  </div>

                  {/* Current Features List */}
                  <ul className="space-y-2 max-h-[140px] overflow-y-auto pr-1">
                    {features.map((feat, idx) => (
                      <li
                        key={idx}
                        className="flex items-center justify-between p-2 bg-slate-50 dark:bg-slate-800/40 border border-slate-100 dark:border-slate-800 rounded-lg text-xs"
                      >
                        <span className="truncate pr-4">{feat}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveFeature(idx)}
                          className="text-red-500 hover:text-red-700 transition-colors p-1"
                        >
                          <XMarkIcon className="w-4 h-4" />
                        </button>
                      </li>
                    ))}
                    {features.length === 0 && (
                      <li className="text-xs text-slate-400 italic text-center py-2">
                        No features added yet. Include some items.
                      </li>
                    )}
                  </ul>
                </div>
              </form>

              {/* Footer Actions */}
              <div className="px-6 py-4 border-t border-slate-100 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/50 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg text-sm font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleSubmit}
                  className="px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-semibold shadow-md shadow-indigo-500/10"
                >
                  {editingPlan ? "Save Changes" : "Create Plan"}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default SubscriptionPlans;
