import React from "react";
import { motion } from "framer-motion";
import { InboxIcon } from "@heroicons/react/24/outline";

const EmptyState = ({ 
  message = "No records found matching your filters.", 
  description = "Try expanding your search query or removing filters.", 
  icon: Icon = InboxIcon 
}) => {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ type: "spring", stiffness: 200, damping: 20 }}
      className="flex flex-col items-center justify-center py-16 px-6 text-center bg-white/40 border border-dashed border-slate-200/80 rounded-2xl backdrop-blur-xs shadow-xs"
    >
      <motion.div
        animate={{ 
          y: [0, -6, 0],
          scale: [1, 1.04, 1]
        }}
        transition={{ 
          repeat: Infinity, 
          duration: 4, 
          ease: "easeInOut" 
        }}
        className="p-4 bg-blue-50 text-[#1E90FF] rounded-2xl shadow-inner mb-4"
      >
        <Icon className="w-10 h-10" />
      </motion.div>
      <h3 className="text-slate-800 font-bold text-base tracking-tight mb-1">
        {message}
      </h3>
      <p className="text-slate-500 text-xs max-w-md">
        {description}
      </p>
    </motion.div>
  );
};

export default EmptyState;
