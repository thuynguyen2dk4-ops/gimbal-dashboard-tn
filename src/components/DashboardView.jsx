import React from 'react';
import { Bluetooth, Camera, Settings, Battery, ChevronDown, ChevronUp, Power, Sun, Moon, Languages } from 'lucide-react';
import { PidSlider } from './PidSlider';
import { dict } from '../locales/dictionary';

export const DashboardView = ({ 
  lang, setLang, isDarkMode, setIsDarkMode, isConnected, connectBluetooth, disconnectBluetooth, toggleCamera, showAdvanced, setShowAdvanced
}) => {
  const t = dict[lang];

  // Bộ CSS động chuyển màu theo Theme
  const theme = {
    card: isDarkMode ? 'bg-slate-800 border-slate-700 shadow-black/20' : 'bg-white border-blue-50 shadow-blue-100/50',
    textMain: isDarkMode ? 'text-white' : 'text-blue-900',
    textSub: isDarkMode ? 'text-blue-300' : 'text-blue-400',
    panel: isDarkMode ? 'bg-slate-700/50 border-slate-600' : 'bg-blue-50/50 border-blue-100',
    btnGhost: isDarkMode ? 'bg-slate-700 text-slate-300 hover:bg-slate-600' : 'bg-blue-50 text-blue-600 hover:bg-blue-100'
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto flex flex-col gap-6">
      
      {/* Header Bar có Toggles */}
      <div className={`${theme.card} rounded-3xl shadow-sm border p-4 px-5 flex flex-wrap justify-between items-center gap-4 transition-colors`}>
        <div className="flex items-center gap-3">
          <div className="bg-blue-500 text-white p-2.5 rounded-2xl shadow-md shadow-blue-500/30">
            <Camera className="w-7 h-7" />
          </div>
          <h1 className={`text-2xl font-black tracking-tight ${theme.textMain}`}>
            {t.app.title}<span className="text-yellow-500">{t.app.subtitle}</span>
          </h1>
        </div>
        
        <div className="flex items-center gap-3 w-full md:w-auto">
          {/* Cụm Toggles Ngôn ngữ & Dark Mode */}
          <div className="flex gap-1.5">
            <button 
              onClick={() => setIsDarkMode(!isDarkMode)} 
              className={`p-2.5 rounded-xl font-bold transition-all ${isDarkMode ? 'bg-yellow-400/20 text-yellow-400' : 'bg-slate-100 text-slate-500 hover:bg-slate-200'}`}
            >
              {isDarkMode ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
            </button>
            <button 
              onClick={() => setLang(lang === 'vi' ? 'en' : 'vi')} 
              className={`flex items-center gap-1.5 px-3 py-2.5 rounded-xl font-bold text-sm transition-all ${theme.btnGhost}`}
            >
              <Languages className="w-4 h-4" /> {lang.toUpperCase()}
            </button>
          </div>

          <button onClick={isConnected ? disconnectBluetooth : connectBluetooth} className={`flex-1 md:flex-none flex justify-center items-center gap-2 px-5 py-2.5 rounded-xl font-bold transition-all ${isConnected ? 'bg-yellow-400 text-yellow-900 shadow-md shadow-yellow-400/30' : 'bg-blue-500 text-white shadow-md shadow-blue-500/30 hover:bg-blue-600'}`}>
            <Bluetooth className={isConnected ? "animate-pulse w-5 h-5" : "w-5 h-5"} />
            {isConnected ? t.app.connected : t.app.connect}
          </button>
        </div>
      </div>

      {/* Nút Mở Camera Khổng lồ */}
      <button onClick={toggleCamera} className="w-full bg-yellow-400 hover:bg-yellow-500 text-yellow-900 font-black text-2xl py-10 rounded-3xl shadow-xl shadow-yellow-400/20 flex flex-col items-center justify-center gap-3 transition-transform active:scale-95 border-2 border-yellow-300 relative overflow-hidden">
         <Camera className="w-14 h-14" />
         {t.dashboard.openCamera}
         <div className="absolute top-0 right-0 bg-red-500 text-white text-xs font-bold px-4 py-1.5 rounded-bl-xl shadow-sm">{t.dashboard.support4k}</div>
      </button>

      {/* Trạng thái */}
      <div className="grid grid-cols-2 gap-4">
        <div className={`${theme.card} p-6 rounded-3xl shadow-sm border flex flex-col gap-2 justify-center items-center text-center transition-colors`}>
           <Power className={`w-10 h-10 mb-2 ${theme.textSub}`} />
           <p className={`text-sm font-bold ${theme.textSub}`}>{t.dashboard.motorStatus}</p>
           <p className={`font-extrabold text-xl ${theme.textMain}`}>{t.dashboard.statusReady}</p>
        </div>
        <div className={`${theme.card} p-6 rounded-3xl shadow-sm border flex flex-col gap-2 justify-center items-center text-center transition-colors`}>
           <Battery className="w-10 h-10 text-yellow-500 mb-2" />
           <p className={`text-sm font-bold ${theme.textSub}`}>{t.dashboard.battery}</p>
           <p className={`font-extrabold text-xl ${theme.textMain}`}>100%</p>
        </div>
      </div>

      {/* Cài đặt PID nâng cao */}
      <div className={`${theme.card} rounded-3xl shadow-sm border overflow-hidden mb-10 transition-colors`}>
        <button onClick={() => setShowAdvanced(!showAdvanced)} className="w-full p-6 flex justify-between items-center hover:bg-black/5 transition-colors">
          <span className={`font-bold flex items-center gap-3 text-lg ${theme.textMain}`}>
            <Settings className="w-6 h-6 text-blue-500" /> {t.dashboard.advancedTuning}
          </span>
          {showAdvanced ? <ChevronUp className="text-blue-500 w-6 h-6" /> : <ChevronDown className="text-blue-500 w-6 h-6" />}
        </button>
        {showAdvanced && (
          <div className={`p-6 border-t flex flex-col gap-6 ${isDarkMode ? 'border-slate-700' : 'border-blue-50'}`}>
            <div className={`${theme.panel} p-5 rounded-2xl border transition-colors`}>
              <p className={`text-sm font-black mb-4 uppercase tracking-wider ${theme.textMain}`}>{t.dashboard.axisPan}</p>
              <div className="space-y-4"><PidSlider label="P" isDarkMode={isDarkMode} /><PidSlider label="I" isDarkMode={isDarkMode} /><PidSlider label="D" isDarkMode={isDarkMode} /></div>
            </div>
            <div className={`${theme.panel} p-5 rounded-2xl border transition-colors`}>
              <p className={`text-sm font-black mb-4 uppercase tracking-wider ${theme.textMain}`}>{t.dashboard.axisTilt}</p>
              <div className="space-y-4"><PidSlider label="P" isDarkMode={isDarkMode} /><PidSlider label="I" isDarkMode={isDarkMode} /><PidSlider label="D" isDarkMode={isDarkMode} /></div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};