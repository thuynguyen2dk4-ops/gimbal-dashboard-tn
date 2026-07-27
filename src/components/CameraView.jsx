import React, { useRef, useState, useEffect } from 'react';
import { Bluetooth, X, Zap, ZapOff, Grid, SwitchCamera, ScanFace, Image as ImageIcon, Trash2, Download } from 'lucide-react';
import '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-converter';
import '@tensorflow/tfjs-backend-webgl'; 
import * as blazeface from '@tensorflow-models/blazeface';
import { dict } from '../locales/dictionary';

// --- LÕI DATABASE TẠM THỜI (INDEXED-DB) ---
const initDB = () => {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('GimbalMediaDB', 1);
    request.onupgradeneeded = (e) => {
      e.target.result.createObjectStore('media', { keyPath: 'id' });
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
};

export const CameraView = ({ 
  lang, isCamActive, isConnected, toggleCamera, flash, setFlash, grid, setGrid, 
  zoom, setZoom, activeMode, setActiveMode, flipCamera 
}) => {
  const t = dict[lang];
  const canvasRef = useRef(null);
  const videoRef = useRef(null);
  
  const [mediaMode, setMediaMode] = useState('video'); 
  const [isRecording, setIsRecording] = useState(false);
  const [recordTime, setRecordTime] = useState(0);
  const [flashEffect, setFlashEffect] = useState(false);
  
  // Gallery States
  const [galleryItems, setGalleryItems] = useState([]);
  const [showGallery, setShowGallery] = useState(false);
  const [lastMedia, setLastMedia] = useState(null);

  // Recorder & AI Refs
  const mediaRecorderRef = useRef(null);
  const chunksRef = useRef([]);
  const timerRef = useRef(null);
  const [isAiEnabled, setIsAiEnabled] = useState(false);
  const detectorRef = useRef(null);
  const requestRef = useRef(null);

  // 1. KHỞI TẠO VÀ XÓA DỮ LIỆU CŨ (QUÁ 7 NGÀY)
  useEffect(() => {
    const loadMedia = async () => {
      try {
        const db = await initDB();
        const tx = db.transaction('media', 'readwrite');
        const store = tx.objectStore('media');
        const request = store.getAll();
        
        request.onsuccess = () => {
          const now = Date.now();
          const oneWeek = 7 * 24 * 60 * 60 * 1000;
          const validItems = [];
          
          request.result.forEach(item => {
            if (now - item.id > oneWeek) {
              store.delete(item.id); // Xóa file quá 1 tuần
            } else {
              validItems.push(item);
            }
          });
          
          const sorted = validItems.sort((a, b) => b.id - a.id);
          setGalleryItems(sorted);
          if (sorted.length > 0) {
            setLastMedia(URL.createObjectURL(sorted[0].blob));
          }
        };
      } catch (e) { console.error("Lỗi Database:", e); }
    };
    loadMedia();
  }, [showGallery]);

  const saveToDB = async (blob, type) => {
    const db = await initDB();
    const tx = db.transaction('media', 'readwrite');
    const newItem = { id: Date.now(), blob, type };
    tx.objectStore('media').add(newItem);
    
    setGalleryItems(prev => [newItem, ...prev]);
    setLastMedia(URL.createObjectURL(blob));
  };

  // 2. LOGIC QUAY VIDEO THỰC TẾ
  const handleRecordVideo = () => {
    if (!isRecording) {
      // Bắt đầu quay
      chunksRef.current = [];
      const stream = videoRef.current.srcObject;
      mediaRecorderRef.current = new MediaRecorder(stream, { mimeType: 'video/mp4' });
      
      mediaRecorderRef.current.ondataavailable = e => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };
      
      mediaRecorderRef.current.onstop = () => {
        const videoBlob = new Blob(chunksRef.current, { type: 'video/mp4' });
        saveToDB(videoBlob, 'video');
      };

      mediaRecorderRef.current.start();
      setIsRecording(true);
      setRecordTime(0);
      timerRef.current = setInterval(() => setRecordTime(p => p + 1), 1000);
    } else {
      // Dừng quay
      mediaRecorderRef.current.stop();
      setIsRecording(false);
      clearInterval(timerRef.current);
    }
  };

  // 3. LOGIC CHỤP ẢNH
  const takePhoto = () => {
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
    
    canvas.toBlob((blob) => {
      saveToDB(blob, 'photo');
    }, 'image/jpeg', 0.95);
  };

  const handleShutterAction = () => {
    if (mediaMode === 'photo') takePhoto();
    else handleRecordVideo();
  };

  // 4. AI AUTO-FRAMING (Dùng 1.5x làm mặc định để có thể Zoom Out)
  const toggleAiTracking = async () => {
    if (isAiEnabled) {
      setIsAiEnabled(false);
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
      const ctx = canvasRef.current.getContext('2d');
      ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
      return;
    }
    try {
      detectorRef.current = await blazeface.load();
      setIsAiEnabled(true);
      setZoom('1.5x'); // Bật AI là tự lùi về 1.5x để chừa không gian giãn khung
      detectFaces(); 
    } catch (error) {}
  };

  const detectFaces = async () => {
    if (!videoRef.current || !detectorRef.current || !canvasRef.current) return;
    const video = videoRef.current;
    
    if (video.videoWidth > 0 && canvasRef.current.width !== video.videoWidth) {
      canvasRef.current.width = video.videoWidth;
      canvasRef.current.height = video.videoHeight;
    }
    try {
      const predictions = await detectorRef.current.estimateFaces(video, false);
      const ctx = canvasRef.current.getContext('2d');
      ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);

      if (predictions.length > 0) {
        predictions.forEach(pred => {
          ctx.strokeStyle = '#FACC15'; 
          ctx.lineWidth = 2; 
          ctx.strokeRect(pred.topLeft[0], pred.topLeft[1], pred.bottomRight[0] - pred.topLeft[0], pred.bottomRight[1] - pred.topLeft[1]);
        });

        if (predictions.length >= 2) {
          // Có nhiều người -> Nhả về 1x (Rộng nhất của phần cứng)
          if (zoom !== '1x') setZoom('1x');
        } else if (predictions.length === 1) {
          // 1 người -> Bám sát ở 1.5x
          if (zoom !== '1.5x') setZoom('1.5x');
        }
      }
    } catch (e) {}

    if (isAiEnabled) requestRef.current = requestAnimationFrame(detectFaces);
  };

  const formatTime = (secs) => {
    const m = Math.floor(secs / 60).toString().padStart(2, '0');
    const s = (secs % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const getZoomScale = () => {
    if (zoom === '2x') return 2;
    if (zoom === '1.5x') return 1.5;
    return 1; // 1x là góc rộng nhất có thể của WebRTC
  };

  return (
    <div className={`fixed inset-0 z-50 bg-black touch-none transition-opacity duration-500 ${isCamActive ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}>
      
      {/* THƯ VIỆN ẢNH TẠM THỜI (TRONG 7 NGÀY) */}
      {showGallery && (
        <div className="absolute inset-0 z-[70] bg-black flex flex-col">
          <div className="p-6 flex justify-between items-center text-white bg-black/50 backdrop-blur-md">
            <button onClick={() => setShowGallery(false)} className="p-2 bg-white/10 rounded-full"><X className="w-6 h-6" /></button>
            <span className="font-bold">Bộ nhớ tạm (7 ngày)</span>
            <div className="w-10"></div>
          </div>
          <div className="flex-1 overflow-y-auto p-4 grid grid-cols-3 gap-2 align-top content-start">
            {galleryItems.map(item => {
              const url = URL.createObjectURL(item.blob);
              return (
                <div key={item.id} className="aspect-square relative rounded-xl overflow-hidden bg-gray-900 group">
                  {item.type === 'video' ? (
                    <video src={url} className="w-full h-full object-cover" />
                  ) : (
                    <img src={url} className="w-full h-full object-cover" />
                  )}
                  {/* Lớp phủ cho phép tải về máy thật */}
                  <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 active:opacity-100 transition-opacity">
                    <button onClick={() => {
                       const a = document.createElement('a');
                       a.href = url;
                       a.download = `Gimbal_TN_${item.id}.${item.type === 'video' ? 'mp4' : 'jpg'}`;
                       a.click();
                    }} className="bg-white text-black p-2 rounded-full shadow-lg">
                      <Download className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              );
            })}
            {galleryItems.length === 0 && <p className="col-span-3 text-center text-white/50 mt-10">Chưa có ảnh/video nào</p>}
          </div>
        </div>
      )}

      <div className={`absolute inset-0 bg-white z-[60] pointer-events-none transition-opacity duration-75 ${flashEffect ? 'opacity-100' : 'opacity-0'}`} />

      {/* LỚP CAMERA & ZOOM */}
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

      {/* HEADER TRÊN CÙNG (Đã nhấc lên sát mép trên) */}
      <div className="absolute top-6 left-0 right-0 px-6 flex justify-between items-start z-20 pointer-events-none">
        {/* Góc trái: Trạng thái Bluetooth */}
        <div className="pointer-events-auto">
          {!isRecording ? (
            <div className={`px-3 py-1.5 rounded-full flex items-center gap-2 text-xs font-bold uppercase tracking-wider backdrop-blur-md transition-colors ${isConnected ? 'bg-blue-500/80 text-white shadow-lg shadow-blue-500/20' : 'bg-black/60 text-white/90'}`}>
              <Bluetooth className="w-3.5 h-3.5" /> GIMBAL TN
            </div>
          ) : (
            <button onClick={toggleCamera} className="text-white p-2 rounded-full bg-black/40 backdrop-blur-md">
              <X className="w-6 h-6" />
            </button>
          )}
        </div>

        {/* Cửa giữa: Đếm giờ quay */}
        <div className="pointer-events-auto flex-1 flex justify-center">
          {isRecording && (
            <div className="bg-red-500/90 backdrop-blur px-5 py-1.5 rounded-full flex items-center gap-2 text-white shadow-lg">
              <div className="w-2.5 h-2.5 rounded-full bg-white animate-pulse" />
              <span className="font-mono font-bold text-lg">{formatTime(recordTime)}</span>
            </div>
          )}
        </div>

        {/* Góc phải: Đóng camera khi chưa quay */}
        <div className="pointer-events-auto">
          {!isRecording && (
            <button onClick={toggleCamera} className="text-white p-2 rounded-full bg-black/40 backdrop-blur-md">
              <X className="w-6 h-6" />
            </button>
          )}
        </div>
      </div>

      {/* THANH CÔNG CỤ TRÁI (Flash, Lưới, AI) */}
      <div className="absolute top-24 left-6 flex flex-col gap-5 z-10">
        <button onClick={() => setFlash(!flash)} className="text-white p-2.5 rounded-full bg-black/30 backdrop-blur-md hover:bg-white/20 transition-colors">
          {flash ? <Zap className="w-5 h-5 text-yellow-400 fill-yellow-400" /> : <ZapOff className="w-5 h-5" />}
        </button>
        <button onClick={() => setGrid(!grid)} className={`p-2.5 rounded-full bg-black/30 backdrop-blur-md transition-colors ${grid ? 'text-yellow-400' : 'text-white'}`}>
          <Grid className="w-5 h-5" />
        </button>
        <button onClick={toggleAiTracking} className={`p-2.5 rounded-full bg-black/30 backdrop-blur-md transition-colors ${isAiEnabled ? 'text-yellow-400 shadow-[0_0_15px_rgba(250,204,21,0.5)]' : 'text-white'}`}>
          <ScanFace className={`w-5 h-5 ${isModelLoading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {/* CHỌN MỨC ZOOM */}
      <div className="absolute bottom-48 left-1/2 -translate-x-1/2 flex gap-3 z-10">
        {['1x', '1.5x', '2x'].map((z) => (
          <button key={z} onClick={() => setZoom(z)} className={`w-11 h-11 rounded-full font-bold text-sm backdrop-blur-md transition-all ${zoom === z ? 'bg-yellow-400 text-black shadow-lg scale-110' : 'bg-black/40 text-white border border-white/20'}`}>
            {z}
          </button>
        ))}
      </div>

      {/* CỤM ĐIỀU KHIỂN CHÍNH DƯỚI ĐÁY */}
      <div className="absolute bottom-0 left-0 right-0 bg-black/50 backdrop-blur-2xl pb-10 pt-6 flex flex-col items-center gap-6 z-10">
        
        {/* THANH CHỌN CHẾ ĐỘ VIDEO/PHOTO */}
        <div className="flex gap-8 text-sm font-bold uppercase tracking-widest absolute -top-10 z-20">
           <button onClick={() => setMediaMode('video')} className={`transition-colors drop-shadow-md ${mediaMode === 'video' ? 'text-yellow-400' : 'text-white/50'}`}>Video</button>
           <button onClick={() => setMediaMode('photo')} className={`transition-colors drop-shadow-md ${mediaMode === 'photo' ? 'text-white' : 'text-white/50'}`}>Photo</button>
        </div>

        <div className="w-full px-10 flex justify-between items-center">
          
          {/* NÚT MỞ THƯ VIỆN (Lấy hình mới nhất) */}
          <button 
            onClick={() => setShowGallery(true)}
            className="w-14 h-14 rounded-xl overflow-hidden border border-white/30 bg-white/10 flex items-center justify-center relative active:scale-90 transition-transform shadow-lg"
          >
            {lastMedia ? <img src={lastMedia} className="w-full h-full object-cover" /> : <ImageIcon className="w-6 h-6 text-white/50" />}
          </button>

          {/* SHUTTER CHÍNH */}
          <button 
            onClick={handleShutterAction} 
            className="w-20 h-20 rounded-full flex items-center justify-center border-4 border-white p-1"
          >
             <div className={`transition-all duration-300 w-full h-full ${
               mediaMode === 'photo' 
                ? 'bg-white rounded-full active:scale-90' 
                : (isRecording ? 'bg-red-500 rounded-lg scale-50' : 'bg-red-500 rounded-full active:scale-90')
             }`} />
          </button>

          {/* LẬT CAMERA */}
          <button onClick={flipCamera} disabled={isRecording} className="w-14 h-14 rounded-full bg-white/10 border border-white/30 flex items-center justify-center text-white backdrop-blur-md active:scale-90 transition-transform disabled:opacity-30 shadow-lg">
            <SwitchCamera className="w-7 h-7" />
          </button>
        </div>
      </div>
    </div>
  );
};