import React, { useRef, useState, useEffect } from 'react';
import { Bluetooth, Battery, X, Zap, ZapOff, Grid, SwitchCamera, ImageIcon, Focus, ScanFace } from 'lucide-react';
// Import hệ sinh thái TensorFlow và BlazeFace
import '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-converter';
import '@tensorflow/tfjs-backend-webgl'; // Ép dùng GPU để xử lý
import * as blazeface from '@tensorflow-models/blazeface';
import { dict } from '../locales/dictionary';

export const CameraView = ({ 
  lang, isCamActive, isConnected, isRecording, recordTime, formatTime, 
  videoRef, toggleCamera, flash, setFlash, grid, setGrid, 
  resolution, fps, toggleQuality, zoom, setZoom, 
  activeMode, setActiveMode, setIsRecording, flipCamera 
}) => {
  const t = dict[lang];
  const canvasRef = useRef(null);
  
  const [isAiEnabled, setIsAiEnabled] = useState(false);
  const [isModelLoading, setIsModelLoading] = useState(false);
  const detectorRef = useRef(null);
  const requestRef = useRef(null);

  // Khởi động AI BlazeFace
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
      // Tải mô hình BlazeFace siêu nhẹ
      detectorRef.current = await blazeface.load();
      setIsAiEnabled(true);
      detectFaces(); 
    } catch (error) {
      console.error("Lỗi tải AI Model:", error);
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
      // Quét khuôn mặt
      const predictions = await detectorRef.current.estimateFaces(video, false);
      const ctx = canvasRef.current.getContext('2d');
      ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);

      if (predictions.length > 0) {
        predictions.forEach(pred => {
          const start = pred.topLeft;
          const end = pred.bottomRight;
          const size = [end[0] - start[0], end[1] - start[1]];
          
          ctx.strokeStyle = '#FACC15'; 
          ctx.lineWidth = 4;
          ctx.strokeRect(start[0], start[1], size[0], size[1]);
        });

        // Smart Tracking (Bám 1 người)
        if (predictions.length === 1) {
          const start = predictions[0].topLeft;
          const end = predictions[0].bottomRight;
          const faceCenterX = start[0] + (end[0] - start[0]) / 2;
          const videoCenterX = video.videoWidth / 2;
          const diffX = faceCenterX - videoCenterX;

          const deadzone = video.videoWidth * 0.1; 
          if (Math.abs(diffX) > deadzone) {
            const direction = diffX > 0 ? "Phải" : "Trái";
            console.log(`[AI Gimbal TN] Lệnh xoay trục Pan sang ${direction}: ${Math.round(diffX)}px`);
          }
        } 
        // Auto-Framing (Nhiều người)
        else if (predictions.length >= 2) {
          let minX = video.videoWidth, maxX = 0;
          predictions.forEach(pred => {
            if (pred.topLeft[0] < minX) minX = pred.topLeft[0];
            if (pred.bottomRight[0] > maxX) maxX = pred.bottomRight[0];
          });

          const groupWidth = maxX - minX;
          if (groupWidth > video.videoWidth * 0.7 && zoom !== '0.5x') {
            setZoom('0.5x');
          } else if (groupWidth < video.videoWidth * 0.3 && zoom !== '2x') {
            setZoom('2x');
          }
        }
      }
    } catch (e) {
      // Bỏ qua lỗi khung hình bị rỗng
    }

    if (isAiEnabled) {
      requestRef.current = requestAnimationFrame(detectFaces);
    }
  };

  return (
    <div className={`fixed inset-0 z-50 bg-black transition-opacity duration-500 flex flex-col ${
      isCamActive ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
    }`}>
      <div className="relative flex-1 bg-black overflow-hidden flex items-center justify-center">
        <video ref={videoRef} autoPlay playsInline muted className="absolute inset-0 w-full h-full object-cover" />
        <canvas ref={canvasRef} className="absolute inset-0 w-full h-full object-cover pointer-events-none" />
        
        {grid && (
          <div className="absolute inset-0 pointer-events-none grid grid-cols-3 grid-rows-3 opacity-30">
            <div className="border-r border-b border-white"></div>
            <div className="border-r border-b border-white"></div>
            <div className="border-b border-white"></div>
            <div className="border-r border-b border-white"></div>
            <div className="border-r border-b border-white"></div>
            <div className="border-b border-white"></div>
            <div className="border-r border-white"></div>
            <div className="border-r border-white"></div>
            <div></div>
          </div>
        )}
      </div>
      
      <div className="absolute top-0 left-0 right-0 bg-gradient-to-b from-black/80 to-transparent pt-6 pb-12 px-6 flex justify-between items-start">
        <div className="flex gap-4 items-center">
          {!isRecording && (
            <button onClick={toggleCamera} className="text-white p-2 rounded-full hover:bg-white/20 transition-colors">
              <X className="w-7 h-7" />
            </button>
          )}
          <button onClick={() => setFlash(!flash)} className="text-white p-2 rounded-full hover:bg-white/20 transition-colors">
            {flash ? <Zap className="w-6 h-6 text-yellow-400 fill-yellow-400" /> : <ZapOff className="w-6 h-6" />}
          </button>
        </div>

        <div className="flex flex-col items-center gap-2">
            {isRecording ? (
              <div className="bg-red-500/20 backdrop-blur-md border border-red-500 px-5 py-1.5 rounded-full flex items-center gap-2 text-white shadow-lg">
                <div className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse"></div>
                <span className="font-mono font-bold text-lg">{formatTime(recordTime)}</span>
              </div>
            ) : (
              <div className="bg-black/50 backdrop-blur-md px-4 py-1.5 rounded-full border border-white/10 flex items-center gap-2 text-white text-xs font-bold">
                <Bluetooth className={`w-3.5 h-3.5 ${isConnected ? 'text-blue-400' : 'text-slate-400'}`} />
                {isConnected ? t.app.ready : t.app.disconnected}
              </div>
            )}
        </div>

        <div className="flex gap-4 items-center">
          <button 
            onClick={toggleAiTracking} 
            disabled={isModelLoading}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full font-bold text-sm transition-colors border ${
              isAiEnabled 
                ? 'bg-yellow-400 text-black border-yellow-400 shadow-[0_0_15px_rgba(250,204,21,0.5)]' 
                : 'bg-black/40 text-white border-white/20 hover:bg-white/20'
            }`}
          >
            <ScanFace className={`w-5 h-5 ${isModelLoading ? 'animate-spin' : ''}`} />
            {isModelLoading ? 'ĐANG TẢI...' : 'AI TRACKING'}
          </button>

          <button onClick={() => setGrid(!grid)} className={`p-2 rounded-full hover:bg-white/20 transition-colors ${grid ? 'text-yellow-400' : 'text-white'}`}>
            <Grid className="w-6 h-6" />
          </button>
        </div>
      </div>
      
      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/80 to-transparent pt-20 pb-8 flex flex-col items-center gap-6">
        <div className="flex gap-4 bg-black/50 backdrop-blur-md p-1.5 rounded-full border border-white/10">
          {['0.5x', '1x', '2x'].map((z) => (
            <button key={z} onClick={() => setZoom(z)} className={`w-10 h-10 rounded-full font-bold text-sm transition-all ${zoom === z ? 'bg-yellow-400 text-black' : 'text-white hover:bg-white/20'}`}>
              {z}
            </button>
          ))}
        </div>

        <div className="flex gap-6 text-sm font-bold uppercase tracking-widest text-white/50">
          {['follow', 'lock', 'fpv'].map((mode) => (
            <button key={mode} onClick={() => setActiveMode(mode)} disabled={isRecording}
              className={`transition-all ${activeMode === mode ? 'text-yellow-400 scale-110 drop-shadow-[0_0_8px_rgba(250,204,21,0.8)]' : 'hover:text-white'} ${isRecording ? 'opacity-30' : ''}`}
            >
              {t.modes[mode]}
            </button>
          ))}
        </div>

        <div className="flex justify-between items-center w-full px-12 pb-4">
          <button className="w-12 h-12 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-white hover:bg-white/20 backdrop-blur">
            <ImageIcon className="w-5 h-5" />
          </button>

          <button onClick={() => setIsRecording(!isRecording)} className={`w-20 h-20 rounded-full flex items-center justify-center transition-all border-4 ${isRecording ? 'border-red-500 bg-red-500/20' : 'border-white bg-white/20 hover:bg-white/30'}`}>
             <div className={`transition-all duration-300 ${isRecording ? 'w-8 h-8 bg-red-500 rounded-lg' : 'w-14 h-14 bg-red-500 rounded-full shadow-inner'}`} />
          </button>

          <button onClick={flipCamera} disabled={isRecording} className="w-12 h-12 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-white hover:bg-white/20 backdrop-blur disabled:opacity-30">
            <SwitchCamera className="w-6 h-6" />
          </button>
        </div>
      </div>
    </div>
  );
};