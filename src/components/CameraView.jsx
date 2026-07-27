import React, { useRef, useState, useEffect } from 'react';
import { Bluetooth, X, Zap, ZapOff, Grid, SwitchCamera, ScanFace, Image as ImageIcon } from 'lucide-react';
import '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-converter';
import '@tensorflow/tfjs-backend-webgl'; 
import * as blazeface from '@tensorflow-models/blazeface';
import { dict } from '../locales/dictionary';

export const CameraView = ({ 
  lang, isCamActive, isConnected, isRecording, recordTime, formatTime, 
  videoRef, toggleCamera, flash, setFlash, grid, setGrid, 
  zoom, setZoom, activeMode, setActiveMode, setIsRecording, flipCamera 
}) => {
  const t = dict[lang];
  const canvasRef = useRef(null);
  
  const [mediaMode, setMediaMode] = useState('video'); 
  const [lastPhoto, setLastPhoto] = useState(null);
  const [flashEffect, setFlashEffect] = useState(false);
  const [showGallery, setShowGallery] = useState(false); // State mở thư viện

  const [isAiEnabled, setIsAiEnabled] = useState(false);
  const [isModelLoading, setIsModelLoading] = useState(false);
  const detectorRef = useRef(null);
  const requestRef = useRef(null);

  // LOGIC ĐIỀU KHIỂN ĐÈN FLASH
  useEffect(() => {
    if (videoRef.current && videoRef.current.srcObject) {
      const track = videoRef.current.srcObject.getVideoTracks()[0];
      if (track && track.getCapabilities && track.getCapabilities().torch !== undefined) {
        track.applyConstraints({ advanced: [{ torch: flash }] }).catch(e => console.log("Không thể bật Flash:", e));
      }
    }
  }, [flash, videoRef]);

  // HÀM TÍNH TOÁN ZOOM KỸ THUẬT SỐ
  const getZoomScale = () => {
    if (zoom === '2x') return 2;
    if (zoom === '0.5x') return 0.75; // Web không gọi được cam góc rộng, dùng scale nhỏ lại tạo cảm giác xa hơn chút
    return 1;
  };

  const toggleAiTracking = async () => {
    if (isAiEnabled) {
      setIsAiEnabled(false);
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
      const ctx = canvasRef.current.getContext('2d');
      ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
      return;
    }
    setIsModelLoading(true);
    try {
      detectorRef.current = await blazeface.load();
      setIsAiEnabled(true);
      detectFaces(); 
    } catch (error) {
      alert("Không thể khởi động AI Tracking!");
    }
    setIsModelLoading(false);
  };

  const detectFaces = async () => {
    if (!videoRef.current || !detectorRef.current || !canvasRef.current) return;
    const video = videoRef.current;
    
    if (video.videoWidth > 0 && (canvasRef.current.width !== video.videoWidth)) {
      canvasRef.current.width = video.videoWidth;
      canvasRef.current.height = video.videoHeight;
    }
    try {
      const predictions = await detectorRef.current.estimateFaces(video, false);
      const ctx = canvasRef.current.getContext('2d');
      ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);

      if (predictions.length > 0) {
        predictions.forEach(pred => {
          const start = pred.topLeft;
          const end = pred.bottomRight;
          ctx.strokeStyle = '#FACC15'; 
          ctx.lineWidth = 2; 
          ctx.strokeRect(start[0], start[1], end[0] - start[0], end[1] - start[1]);
        });
      }
    } catch (e) {}

    if (isAiEnabled) requestRef.current = requestAnimationFrame(detectFaces);
  };

  const takePhoto = async () => {
    if (!videoRef.current) return;
    
    setFlashEffect(true);
    setTimeout(() => setFlashEffect(false), 150);

    const canvas = document.createElement('canvas');
    canvas.width = videoRef.current.videoWidth;
    canvas.height = videoRef.current.videoHeight;
    const ctx = canvas.getContext('2d');
    
    if (videoRef.current.style.transform.includes('scaleX(-1)')) {
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
    const dataUrl = canvas.toDataURL('image/jpeg', 0.9);
    setLastPhoto(dataUrl);

    // GỌI NATIVE SHARE SHEET CỦA iOS ĐỂ LƯU ẢNH
    if (navigator.share) {
      try {
        const blob = await (await fetch(dataUrl)).blob();
        const file = new File([blob], `Gimbal_TN_${Date.now()}.jpg`, { type: 'image/jpeg' });
        await navigator.share({
          files: [file],
          title: 'Gimbal TN Photo'
        });
      } catch (err) {
        console.log("Người dùng hủy lưu ảnh", err);
      }
    } else {
      // Fallback cho máy tính hoặc trình duyệt cũ
      const link = document.createElement('a');
      link.href = dataUrl;
      link.download = `Gimbal_TN_${Date.now()}.jpg`;
      link.click();
    }
  };

  const handleShutterAction = () => {
    if (mediaMode === 'photo') {
      takePhoto();
    } else {
      setIsRecording(!isRecording);
    }
  };

  return (
    // THÊM touch-none VÀO ĐÂY ĐỂ CHẶN ZOOM TRANG WEB
    <div className={`fixed inset-0 z-50 bg-black touch-none transition-opacity duration-500 ${isCamActive ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}>
      
      {/* OVERLAY XEM TRƯỚC ẢNH VỪA CHỤP */}
      {showGallery && lastPhoto && (
        <div className="absolute inset-0 z-[70] bg-black/95 flex flex-col">
          <div className="p-6 flex justify-between items-center text-white">
            <button onClick={() => setShowGallery(false)} className="p-2"><X className="w-8 h-8" /></button>
            <span className="font-bold">Gimbal Gallery</span>
            <div className="w-8"></div>
          </div>
          <div className="flex-1 flex items-center justify-center p-4">
            <img src={lastPhoto} alt="Preview" className="max-w-full max-h-full rounded-2xl object-contain" />
          </div>
        </div>
      )}

      <div className={`absolute inset-0 bg-white z-[60] pointer-events-none transition-opacity duration-75 ${flashEffect ? 'opacity-100' : 'opacity-0'}`} />

      {/* ÁP DỤNG ZOOM KỸ THUẬT SỐ VÀO CONTAINER NÀY */}
      <div className="absolute inset-0 flex items-center justify-center overflow-hidden">
        <div style={{ transform: `scale(${getZoomScale()})`, transition: 'transform 0.3s ease-out' }} className="relative w-full h-full">
          <video ref={videoRef} autoPlay playsInline muted className="absolute inset-0 w-full h-full object-cover" />
          <canvas ref={canvasRef} className="absolute inset-0 w-full h-full object-cover pointer-events-none" />
        </div>
        {grid && (
          <div className="absolute inset-0 pointer-events-none grid grid-cols-3 grid-rows-3 opacity-30">
            <div className="border-r border-b border-white/50" /><div className="border-r border-b border-white/50" /><div className="border-b border-white/50" />
            <div className="border-r border-b border-white/50" /><div className="border-r border-b border-white/50" /><div className="border-b border-white/50" />
            <div className="border-r border-white/50" /><div className="border-r border-white/50" /><div />
          </div>
        )}
      </div>

      <div className="absolute top-0 left-0 right-0 landscape:right-auto landscape:bottom-0 landscape:w-24 bg-gradient-to-b landscape:bg-gradient-to-r from-black/60 to-transparent p-6 flex landscape:flex-col justify-between items-center z-10">
        {!isRecording && (
          <button onClick={toggleCamera} className="text-white p-2 rounded-full hover:bg-white/20 transition-colors">
            <X className="w-7 h-7" />
          </button>
        )}
        <div className="flex landscape:flex-col gap-6 mt-2 landscape:mt-0">
          <button onClick={() => setFlash(!flash)} className="text-white p-2 rounded-full hover:bg-white/20 transition-colors">
            {flash ? <Zap className="w-6 h-6 text-yellow-400 fill-yellow-400" /> : <ZapOff className="w-6 h-6" />}
          </button>
          <button onClick={() => setGrid(!grid)} className={`p-2 rounded-full hover:bg-white/20 transition-colors ${grid ? 'text-yellow-400' : 'text-white'}`}>
            <Grid className="w-6 h-6" />
          </button>
          <button onClick={toggleAiTracking} className={`p-2 rounded-full transition-colors ${isAiEnabled ? 'text-yellow-400' : 'text-white hover:bg-white/20'}`}>
            <ScanFace className={`w-6 h-6 ${isModelLoading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* ĐẨY TRẠNG THÁI XUỐNG THẤP HƠN ĐỂ KHÔNG CHẠM NÚT FLASH (top-14) */}
      <div className="absolute top-14 left-1/2 -translate-x-1/2 z-10">
        {isRecording ? (
          <div className="bg-red-500/90 backdrop-blur px-4 py-1.5 rounded-md flex items-center gap-2 text-white shadow-lg">
            <div className="w-2 h-2 rounded-full bg-white animate-pulse" />
            <span className="font-mono font-bold">{formatTime(recordTime)}</span>
          </div>
        ) : (
          <div className={`px-3 py-1 rounded-full flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider backdrop-blur-md transition-colors ${isConnected ? 'bg-blue-500/80 text-white' : 'bg-black/40 text-white/70'}`}>
            <Bluetooth className="w-3.5 h-3.5" /> {isConnected ? 'Đã kết nối' : 'Gimbal TN'}
          </div>
        )}
      </div>

      <div className="absolute bottom-48 left-1/2 -translate-x-1/2 landscape:bottom-1/2 landscape:translate-y-1/2 landscape:left-auto landscape:right-36 flex landscape:flex-col gap-3 z-10">
        {['0.5x', '1x', '2x'].map((z) => (
          <button key={z} onClick={() => setZoom(z)} className={`w-10 h-10 rounded-full font-semibold text-sm backdrop-blur-md transition-all ${zoom === z ? 'bg-black/70 text-yellow-400' : 'bg-black/30 text-white hover:bg-black/50'}`}>
            {z}
          </button>
        ))}
      </div>

      <div className="absolute bottom-0 left-0 right-0 landscape:top-0 landscape:left-auto landscape:w-32 bg-black/40 backdrop-blur-xl pb-12 pt-6 landscape:py-0 landscape:h-full flex flex-col landscape:flex-row items-center justify-center gap-6 z-10">
        
        <div className="flex landscape:flex-col gap-6 text-sm font-bold uppercase tracking-widest text-white/50 absolute -top-8 left-1/2 -translate-x-1/2 landscape:top-1/2 landscape:-translate-y-1/2 landscape:left-auto landscape:-left-12 z-20 shadow-black/50 drop-shadow-md">
           <button onClick={() => setMediaMode('video')} className={`transition-colors ${mediaMode === 'video' ? 'text-yellow-400' : ''}`}>Video</button>
           <button onClick={() => setMediaMode('photo')} className={`transition-colors ${mediaMode === 'photo' ? 'text-white' : ''}`}>Photo</button>
        </div>

        <div className="w-full px-10 landscape:px-0 flex landscape:flex-col justify-between items-center landscape:h-full landscape:py-10">
          
          {/* NÚT THƯ VIỆN ĐÃ ĐƯỢC GẮN LỆNH MỞ GALLERY */}
          <button 
            onClick={() => lastPhoto && setShowGallery(true)}
            className="w-12 h-12 rounded-lg overflow-hidden border border-white/20 bg-white/10 flex items-center justify-center relative active:scale-95 transition-transform"
          >
            {lastPhoto ? <img src={lastPhoto} alt="Gallery" className="w-full h-full object-cover" /> : <ImageIcon className="w-5 h-5 text-white/50" />}
          </button>

          <button 
            onClick={handleShutterAction} 
            className={`w-20 h-20 rounded-full flex items-center justify-center transition-all border-4 p-1 ${mediaMode === 'photo' ? 'border-white' : 'border-white'}`}
          >
             <div className={`transition-all duration-300 w-full h-full ${
               mediaMode === 'photo' 
                ? 'bg-white rounded-full active:scale-90' 
                : (isRecording ? 'bg-red-500 rounded-lg scale-50' : 'bg-red-500 rounded-full active:scale-90')
             }`} />
          </button>

          <button onClick={flipCamera} disabled={isRecording} className="w-12 h-12 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-white hover:bg-white/20 backdrop-blur-md active:scale-95 transition-transform disabled:opacity-30">
            <SwitchCamera className="w-6 h-6" />
          </button>
        </div>
      </div>
    </div>
  );
};