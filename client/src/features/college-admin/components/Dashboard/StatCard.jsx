import React from "react";
import { motion } from "framer-motion";

const StatCard = ({ title, value, icon: Icon, color, delay }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ type: "spring", stiffness: 100, damping: 15, delay }}
    whileHover={{ 
      y: -6, 
      scale: 1.025, 
      transition: { type: "spring", stiffness: 400, damping: 17 } 
    }}
    className="bg-white rounded-[24px] border border-slate-100 p-4 sm:p-6 flex items-center space-x-3.5 sm:space-x-5 shadow-sm hover:shadow-xl hover:shadow-primary-main/10 transition-shadow cursor-pointer group"
  >
    <div
      className={`p-3 sm:p-4 rounded-xl sm:rounded-2xl shadow-inner transition-transform duration-300 group-hover:scale-110 shrink-0 ${color}`}
    >
      <Icon className="w-7 h-7 text-white filter drop-shadow-md" />
    </div>
    <div className="min-w-0 flex-1">
      <p className="text-slate-400 text-[9px] sm:text-xs font-black uppercase tracking-widest mb-1 truncate">
        {title}
      </p>
      <h3 className="text-lg sm:text-2xl md:text-3xl font-black text-slate-800 tracking-tight truncate">
        {value}
      </h3>
    </div>
  </motion.div>
);

export default StatCard;
