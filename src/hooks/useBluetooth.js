import { useState } from 'react';

export const useBluetooth = () => {
  const [isConnected, setIsConnected] = useState(false);
  const [device, setDevice] = useState(null);

  // Đây là mã UUID chuẩn của mạch ESP32 (Nordic UART Service)
  // Sau này khi nạp code cho mạch cứng ESP32, chúng ta sẽ khai báo đúng mã này
  const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";

  const connectBluetooth = async () => {
    try {
      // 1. Kiểm tra trình duyệt có hỗ trợ không
      if (!navigator.bluetooth) {
        alert("Trình duyệt không hỗ trợ Web Bluetooth! Hãy sử dụng Chrome hoặc Edge trên máy tính/Android.");
        return;
      }

      // 2. Quét tìm thiết bị có tên bắt đầu bằng "Gimbal"
      console.log("Đang quét thiết bị...");
      const bleDevice = await navigator.bluetooth.requestDevice({
        filters: [{ namePrefix: "Gimbal TN" }], // Chỉ hiển thị thiết bị tên Gimbal...
        optionalServices: [SERVICE_UUID]
      });

      // 3. Gắn sự kiện để biết khi nào bị đứt kết nối (ví dụ: hết pin)
      bleDevice.addEventListener('gattserverdisconnected', disconnectBluetooth);
      setDevice(bleDevice);

      // 4. Kết nối vào Server của ESP32
      console.log("Đang ghép nối...");
      const server = await bleDevice.gatt.connect();
      
      console.log("Kết nối thành công!");
      setIsConnected(true);

      // (Các bước Lấy Service và Đọc/Ghi dữ liệu PID sẽ được viết thêm vào đây sau khi có mạch ESP32)

    } catch (error) {
      console.error("Lỗi Bluetooth:", error);
      // Lỗi này thường do người dùng ấn "Hủy" khi bảng popup hiện lên
    }
  };

  const disconnectBluetooth = () => {
    if (device && device.gatt.connected) {
      device.gatt.disconnect();
    }
    setIsConnected(false);
    setDevice(null);
    console.log("Đã ngắt kết nối BLE!");
  };

  return { isConnected, connectBluetooth, disconnectBluetooth };
};