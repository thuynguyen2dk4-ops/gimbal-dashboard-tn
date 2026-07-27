import React from 'react';
import { Bluetooth, Camera, Settings, Battery, ChevronDown, ChevronUp, Power, Sun, Moon, Languages } from 'lucide-react';
import { PidSlider } from './PidSlider';
import { dict } from '../locales/dictionary';

export const DashboardView = ({ 
  lang, setLang, 
  isDarkMode, setIsDarkMode, 
  isConnected, connectBluetooth, disconnectBluetooth, 
  toggleCamera, showAdvanced, setShowAdvanced 
}) => {
  const t = dict[lang];

  // Hệ màu chuẩn iOS / iPadOS
  const theme = {
    wrapper: isDarkMode ? 'bg-[#000000]' : 'bg-[#F2F2F7]',
    card: isDarkMode ? 'bg-[#1C1C1E]/90 backdrop-blur-2xl' : 'bg-white/90 backdrop-blur-2xl shadow-sm',
    textMain: isDarkMode ? 'text-white' : 'text-black',
    textSub: isDarkMode ? 'text-gray-400' : 'text-gray-500',
    btnPrimary: 'bg-blue-500 hover:bg-blue-600 text-white active:scale-95 transition-transform',
    btnSecondary: isDarkMode ? 'bg-[#2C2C2E] hover:bg-[#3A3A3C] text-white' : 'bg-[#E5E5EA] hover:bg-[#D1D1D6] text-black',
    accent: 'text-blue-500'
  };

  return (
    <div className={`min-h-screen ${theme.wrapper} p-4 md:p-8 transition-colors duration-300 flex justify-center items-start`}>
      <div className="w-full max-w-5xl flex flex-col gap-6">
        
        {/* HEADER BAR (Minimalist) */}
        <div className="flex justify-between items-center px-2 pt-2">
          <h1 className={`text-3xl font-bold tracking-tight ${theme.textMain}`}>
            Gimbal <span className="text-blue-500">TN</span>
          </h1>
          
          <div className="flex gap-2">
            <button onClick={() => setLang(lang === 'vi' ? 'en' : 'vi')} className={`w-10 h-10 rounded-full flex justify-center items-center font-bold text-xs ${theme.btnSecondary} active:scale-90 transition-transform`}>
              {lang.toUpperCase()}
            </button>
            <button onClick={() => setIsDarkMode(!isDarkMode)} className={`w-10 h-10 rounded-full flex justify-center items-center ${theme.btnSecondary} active:scale-90 transition-transform`}>
              {isDarkMode ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* CỘT GRID (Chia 2 khi xoay ngang) */}
        <div className="grid grid-cols-1 landscape:grid-cols-2 gap-4 md:gap-6">
          
          {/* CỘT TRÁI */}
          <div className="flex flex-col gap-4 md:gap-6">
            
            {/* Nút Kết nối BLE (Kiểu Widget iOS) */}
            <div className={`${theme.card} rounded-[32px] p-6 flex justify-between items-center`}>
              <div className="flex items-center gap-4">
                <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isConnected ? 'bg-blue-500/10' : 'bg-gray-500/10'}`}>
                  <Bluetooth className={`w-6 h-6 ${isConnected ? 'text-blue-500' : theme.textSub}`} />
                </div>
                <div>
                  <p className={`font-semibold ${theme.textMain}`}>{isConnected ? t.app.connected : t.app.disconnected}</p>
                  <p className={`text-sm ${theme.textSub}`}>{isConnected ? t.app.ready : 'Web Bluetooth API'}</p>
                </div>
              </div>
              <button 
                onClick={isConnected ? disconnectBluetooth : connectBluetooth} 
                className={`px-5 py-2.5 rounded-full font-semibold text-sm ${isConnected ? 'bg-gray-500/20 text-red-500 hover:bg-red-500/20' : theme.btnPrimary}`}
              >
                {isConnected ? 'Ngắt kết nối' : t.app.connect}
              </button>
            </div>

            {/* Trạng thái phần cứng (2 ô vuông) */}
            <div className="grid grid-cols-2 gap-4 md:gap-6">
              <div className={`${theme.card} rounded-[32px] p-6 flex flex-col justify-between aspect-square`}>
                 <Power className={`w-8 h-8 ${isConnected ? 'text-green-500' : theme.textSub}`} />
                 <div>
                   <p className={`text-xs font-semibold uppercase tracking-wider ${theme.textSub} mb-1`}>{t.dashboard.motorStatus}</p>
                   <p className={`font-bold text-xl ${theme.textMain}`}>{isConnected ? 'Active' : 'Standby'}</p>
                 </div>
              </div>
              <div className={`${theme.card} rounded-[32px] p-6 flex flex-col justify-between aspect-square`}>
                 <Battery className={`w-8 h-8 ${isConnected ? 'text-green-500' : theme.textSub}`} />
                 <div>
                   <p className={`text-xs font-semibold uppercase tracking-wider ${theme.textSub} mb-1`}>{t.dashboard.battery}</p>
                   <p className={`font-bold text-xl ${theme.textMain}`}>{isConnected ? '98%' : '--'}</p>
                 </div>
              </div>
            </div>

            {/* NÚT MỞ CAMERA KHỔNG LỒ */}
            <button 
              onClick={toggleCamera} 
              className={`w-full ${theme.btnPrimary} rounded-[32px] p-8 flex flex-col items-center justify-center gap-3 relative overflow-hidden`}
            >
               <Camera className="w-12 h-12" />
               <span className="font-bold text-xl tracking-tight">{t.dashboard.openCamera}</span>
            </button>

          </div>

          {/* CỘT PHẢI: PID TUNING */}
          <div className={`${theme.card} rounded-[32px] overflow-hidden flex flex-col h-full`}>
            <button 
              onClick={() => setShowAdvanced(!showAdvanced)} 
              className="w-full p-6 flex justify-between items-center active:bg-black/5 dark:active:bg-white/5 transition-colors"
            >
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 rounded-full bg-orange-500/10 flex items-center justify-center">
                  <Settings className="w-5 h-5 text-orange-500" />
                </div>
                <span className={`font-semibold text-lg ${theme.textMain}`}>{t.dashboard.advancedTuning}</span>
              </div>
              {showAdvanced ? <ChevronUp className={theme.textSub} /> : <ChevronDown className={theme.textSub} />}
            </button>
            
            {/* Panel PID - Trên điện thoại dọc thì ẩn/hiện, xoay ngang thì luôn hiện */}
            <div className={`${showAdvanced ? 'block' : 'hidden landscape:block'} px-6 pb-8 flex flex-col gap-8`}>
              
              {/* PAN AXIS */}
              <div>
                <p className={`text-xs font-bold uppercase tracking-widest ${theme.textSub} mb-4`}>{t.dashboard.axisPan}</p>
                <div className={`bg-black/5 dark:bg-white/5 rounded-2xl p-4 space-y-5`}>
                  <PidSlider label="P" isDarkMode={isDarkMode} />
                  <PidSlider label="I" isDarkMode={isDarkMode} />
                  <PidSlider label="D" isDarkMode={isDarkMode} />
                </div>
              </div>

              {/* TILT AXIS */}
              <div>
                <p className={`text-xs font-bold uppercase tracking-widest ${theme.textSub} mb-4`}>{t.dashboard.axisTilt}</p>
                <div className={`bg-black/5 dark:bg-white/5 rounded-2xl p-4 space-y-5`}>
                  <PidSlider label="P" isDarkMode={isDarkMode} />
                  <PidSlider label="I" isDarkMode={isDarkMode} />
                  <PidSlider label="D" isDarkMode={isDarkMode} />
                </div>
              </div>

            </div>
          </div>

        </div>
      </div>
    </div>
  );
};