import React from 'react';

export const PidSlider = ({ label, isDarkMode }) => (
  <div className="flex items-center gap-4">
    <span className={`font-extrabold w-4 ${isDarkMode ? 'text-blue-300' : 'text-blue-500'}`}>{label}</span>
    <input 
      type="range" 
      className={`flex-1 h-3 rounded-full appearance-none cursor-pointer accent-blue-500 ${isDarkMode ? 'bg-slate-600' : 'bg-blue-100'}`}
    />
  </div>
);