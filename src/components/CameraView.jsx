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

  const [isAiEnabled, setIsAiEnabled] = useState(false);
  const [isModelLoading, setIsModelLoading] = useState(false);
  const detectorRef = useRef(null);
  const requestRef = useRef(null);

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

        if (predictions.length === 1) {
          const start = predictions[0].topLeft;
          const end = predictions[0].bottomRight;
          const diffX = (start[0] + (end[0] - start[0]) / 2) - (video.videoWidth / 2);
          if (Math.abs(diffX) > video.videoWidth * 0.1) {
            console.log(`[AI Gimbal] Lệnh xoay: ${diffX > 0 ? "Phải" : "Trái"}`);
          }
        } else if (predictions.length >= 2) {
          let minX = video.videoWidth, maxX = 0;
          predictions.forEach(pred => {
            if (pred.topLeft[0] < minX) minX = pred.topLeft[0];
            if (pred.bottomRight[0] > maxX) maxX = pred.bottomRight[0];
          });
          const groupWidth = maxX - minX;
          if (groupWidth > video.videoWidth * 0.7 && zoom !== '0.5x') setZoom('0.5x');
          else if (groupWidth < video.videoWidth * 0.3 && zoom !== '2x') setZoom('2x');
        }
      }
    } catch (e) {}

    if (isAiEnabled) requestRef.current = requestAnimationFrame(detectFaces);
  };

  const takePhoto = () => {
    if (!videoRef.current) return;
    
    setFlashEffect(true);
    setTimeout(() => setFlashEffect(false), 150);

    const canvas = document.createElement('canvas');
    canvas.width = videoRef.current.videoWidth;
    canvas.height = videoRef.current.videoHeight;
    const ctx = canvas.getContext('2d');
    
    if (videoRef.current.style.transform === 'scaleX(-1)') {
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
    }
    
    ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
    const dataUrl = canvas.toDataURL('image/jpeg', 0.9);
    setLastPhoto(dataUrl);

    const link = document.createElement('a');
    link.href = dataUrl;
    link.download = `Gimbal_TN_${Date.now()}.jpg`;
    link.click();
  };

  const handleShutterAction = () => {
    if (mediaMode === 'photo') {
      takePhoto();
    } else {
      setIsRecording(!isRecording);
    }
  };

  return (
    <div className={`fixed inset-0 z-50 bg-black transition-opacity duration-500 ${isCamActive ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}>
      
      <div className={`absolute inset-0 bg-white z-[60] pointer-events-none transition-opacity duration-75 ${flashEffect ? 'opacity-100' : 'opacity-0'}`} />

      <div className="absolute inset-0 flex items-center justify-center overflow-hidden">
        <video ref={videoRef} autoPlay playsInline muted className="absolute inset-0 w-full h-full object-cover" />
        <canvas ref={canvasRef} className="absolute inset-0 w-full h-full object-cover pointer-events-none" />
        {grid && (
          <div className="absolute inset-0 pointer-events-none grid grid-cols-3 grid-rows-3 opacity-30">
            <div className="border-r border-b border-white/50" /><div className="border-r border-b border-white/50" /><div className="border-b border-white/50" />
            <div className="border-r border-b border-white/50" /><div className="border-r border-b border-white/50" /><div className="border-b border-white/50" />
            <div className="border-r border-white/50" /><div className="border-r border-white/50" /><div />
          </div>
        )}
      </div>

      {/* THANH CÔNG CỤ TRÊN (Đứng) / TRÁI (Ngang) */}
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

      {/* TRẠNG THÁI / ĐẾM GIỜ QUAY */}
      <div className="absolute top-8 left-1/2 -translate-x-1/2 z-10">
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

      {/* CHỌN MỨC ZOOM - Đẩy lên bottom-48 để tránh lẹm vào thanh Safari */}
      <div className="absolute bottom-48 left-1/2 -translate-x-1/2 landscape:bottom-1/2 landscape:translate-y-1/2 landscape:left-auto landscape:right-36 flex landscape:flex-col gap-3 z-10">
        {['0.5x', '1x', '2x'].map((z) => (
          <button key={z} onClick={() => setZoom(z)} className={`w-10 h-10 rounded-full font-semibold text-sm backdrop-blur-md transition-all ${zoom === z ? 'bg-black/70 text-yellow-400' : 'bg-black/30 text-white hover:bg-black/50'}`}>
            {z}
          </button>
        ))}
      </div>

      {/* CỤM ĐIỀU KHIỂN CHÍNH DƯỚI (Đứng) / PHẢI (Ngang) */}
      <div className="absolute bottom-0 left-0 right-0 landscape:top-0 landscape:left-auto landscape:w-32 bg-black/40 backdrop-blur-xl pb-12 pt-6 landscape:py-0 landscape:h-full flex flex-col landscape:flex-row items-center justify-center gap-6 z-10">
        
        {/* THANH CHỌN CHẾ ĐỘ - Đẩy bổng lên trên (Đứng) hoặc lùi ra ngoài (Ngang) */}
        <div className="flex landscape:flex-col gap-6 text-sm font-bold uppercase tracking-widest text-white/50 absolute -top-8 left-1/2 -translate-x-1/2 landscape:top-1/2 landscape:-translate-y-1/2 landscape:left-auto landscape:-left-12 z-20 shadow-black/50 drop-shadow-md">
           <button onClick={() => setMediaMode('video')} className={`transition-colors ${mediaMode === 'video' ? 'text-yellow-400' : ''}`}>Video</button>
           <button onClick={() => setMediaMode('photo')} className={`transition-colors ${mediaMode === 'photo' ? 'text-white' : ''}`}>Photo</button>
        </div>

        {/* CỤM NÚT BẤM (Thư viện - Chụp - Lật) */}
        <div className="w-full px-10 landscape:px-0 flex landscape:flex-col justify-between items-center landscape:h-full landscape:py-10">
          
          <button className="w-12 h-12 rounded-lg overflow-hidden border border-white/20 bg-white/10 flex items-center justify-center relative active:scale-95 transition-transform">
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