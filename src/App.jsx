import React, { useState, useRef, useEffect } from 'react';
import { CameraView } from './components/CameraView';
import { DashboardView } from './components/DashboardView';
import { useBluetooth } from './hooks/useBluetooth';
const App = () => {
  // --- STATES GIAO DIỆN ---
  const [lang, setLang] = useState('vi'); 
  const [isDarkMode, setIsDarkMode] = useState(false);
  
  // --- STATES DASHBOARD ---
  const { isConnected, connectBluetooth, disconnectBluetooth } = useBluetooth()
  const [showAdvanced, setShowAdvanced] = useState(false);
  
  // --- STATES CAMERA ---
  const [isCamActive, setIsCamActive] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [recordTime, setRecordTime] = useState(0);
  const [activeMode, setActiveMode] = useState('follow');
  const [flash, setFlash] = useState(false);
  const [grid, setGrid] = useState(true);
  const [resolution, setResolution] = useState('1080p');
  const [fps, setFps] = useState('60');
  const [zoom, setZoom] = useState('1x');
  const [facingMode, setFacingMode] = useState('environment');

  const videoRef = useRef(null);
  const [stream, setStream] = useState(null);

  // Bộ đếm giờ
  useEffect(() => {
    let interval;
    if (isRecording) interval = setInterval(() => setRecordTime(p => p + 1), 1000);
    else setRecordTime(0);
    return () => clearInterval(interval);
  }, [isRecording]);

  const formatTime = (time) => {
    const m = Math.floor(time / 60).toString().padStart(2, '0');
    const s = (time % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const startCameraStream = async (faceMode) => {
    if (stream) stream.getTracks().forEach(track => track.stop());
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: faceMode } });
      if (videoRef.current) videoRef.current.srcObject = mediaStream;
      setStream(mediaStream);
    } catch (err) {
      alert("Không thể mở camera. Vui lòng cấp quyền!");
    }
  };

  const toggleCamera = () => {
    if (!isCamActive) {
      setIsCamActive(true);
      startCameraStream(facingMode);
    } else {
      if (stream) stream.getTracks().forEach(track => track.stop());
      if (videoRef.current) videoRef.current.srcObject = null;
      setStream(null);
      setIsCamActive(false);
      setIsRecording(false);
    }
  };

  const flipCamera = () => {
    const newMode = facingMode === 'environment' ? 'user' : 'environment';
    setFacingMode(newMode);
    if (isCamActive) startCameraStream(newMode);
  };

  const toggleQuality = () => {
    if (resolution === '1080p') { setResolution('4K'); setFps('30'); } 
    else { setResolution('1080p'); setFps('60'); }
  };

  return (
    // Đổi màu nền gốc dựa theo Dark Mode
    <div className={`min-h-screen font-sans transition-colors duration-500 selection:bg-yellow-200 ${isDarkMode ? 'bg-slate-900' : 'bg-slate-100'}`}>
      
      <CameraView 
        lang={lang} isCamActive={isCamActive} isConnected={isConnected} isRecording={isRecording} 
        recordTime={recordTime} formatTime={formatTime} videoRef={videoRef} toggleCamera={toggleCamera} 
        flash={flash} setFlash={setFlash} grid={grid} setGrid={setGrid} 
        resolution={resolution} fps={fps} toggleQuality={toggleQuality} zoom={zoom} setZoom={setZoom} 
        activeMode={activeMode} setActiveMode={setActiveMode} setIsRecording={setIsRecording} flipCamera={flipCamera}
      />
      
      <DashboardView 
        lang={lang} setLang={setLang}
        isDarkMode={isDarkMode} setIsDarkMode={setIsDarkMode}
        isConnected={isConnected} 
        connectBluetooth={connectBluetooth} // Gọi hàm Kết nối
        disconnectBluetooth={disconnectBluetooth} // Gọi hàm Ngắt kết nối
        toggleCamera={toggleCamera} showAdvanced={showAdvanced} setShowAdvanced={setShowAdvanced}
      />
      
    </div>
  );
};

export default App;