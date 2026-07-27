import React from 'react';
import { Sliders } from 'lucide-react';

export const PidControl = ({ axisName, iconColor, isDarkMode }) => {
  const cardStyle = isDarkMode 
    ? 'bg-slate-800/80 border-slate-700/50 text-slate-100' 
    : 'bg-white border-slate-100 text-slate-800 shadow-xl shadow-slate-200/40';

  const inputStyle = isDarkMode ? 'bg-slate-700' : 'bg-slate-200';
  const textMuted = isDarkMode ? 'text-slate-400' : 'text-slate-500';

  return (
    <div className={`p-6 rounded-3xl border transition-all duration-300 backdrop-blur-sm ${cardStyle}`}>
      <div className="flex items-center gap-3 mb-6">
        <div className={`p-3 rounded-2xl bg-slate-500/10 ${iconColor}`}>
          <Sliders className="w-5 h-5" />
        </div>
        <h3 className="text-xl font-bold">{axisName}</h3>
      </div>
      
      <div className="space-y-5">
        {['P', 'I', 'D'].map((param) => (
          <div key={param} className="flex items-center gap-4">
            <span className={`font-bold text-lg w-6 ${textMuted}`}>{param}</span>
            <input 
              type="range" 
              className={`flex-1 h-3 rounded-full appearance-none cursor-pointer accent-indigo-500 ${inputStyle}`}
            />
            <span className={`w-14 text-right font-semibold bg-slate-500/10 py-1 rounded-lg ${textMuted}`}>
              0.00
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};