import React from "react";
import { motion } from "framer-motion";

const StatCard = ({ title, value, icon: Icon, color, delay }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.5, delay }}
    className="bg-white rounded-[24px] border border-slate-100 p-6 flex items-center space-x-5 shadow-sm hover:shadow-xl hover:shadow-blue-500/5 transition-all group"
  >
    <div
      className={`p-4 rounded-2xl shadow-inner transition-transform group-hover:scale-110 ${color}`}
    >
      <Icon className="w-8 h-8 text-white filter drop-shadow-md" />
    </div>
    <div>
      <p className="text-slate-400 text-xs font-black uppercase tracking-widest mb-1">
        {title}
      </p>
      <h3 className="text-3xl font-black text-slate-800 tracking-tight">
        {value}
      </h3>
    </div>
  </motion.div>
);

export default StatCard;
