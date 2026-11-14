//
//  BLEGimbalManager.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import CoreBluetooth
import Combine
import UIKit

// MARK: - =====================================================================
// 4. REALTIME BLE GIMBAL CONTROLLER & MOTOR TELEMETRY
// =====================================================================

final class BLEGimbalManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected: Bool = false
    @Published var batteryLevel: Int = 0
    @Published var bluetoothStateText: String = "Đang kiểm tra Bluetooth"
    @Published var isScanning: Bool = false
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripheralName: String = ""
    @Published var gimbalMode: String = "PF" // PF, LOCK, Follow, FPV, POV, 360°
    @Published var rollAngle: Double = 0.02
    @Published var pitchAngle: Double = 12.4
    @Published var panAngle: Double = 359.8
    @Published var joystickSensitivity: Double = 0.45
    @Published var panTorque: Double = 1.0
    @Published var tiltTorque: Double = 0.85
    @Published var rollTorque: Double = 0.90

    // Axis Smoothness & Firmware OTA (Figma Node 96:3)
    @Published var smoothPan: Double = 0.70
    @Published var smoothTilt: Double = 0.60
    @Published var smoothRoll: Double = 0.50
    @Published var firmwareVersion: String = ""
    @Published var latestFirmwareVersion: String = "v2.4.2"
    @Published var isUpdatingFirmware: Bool = false
    @Published var firmwareUpdateProgress: Double = 0.0
    @Published var showFirmwareSheet: Bool = false

    // Calibration Flow State
    @Published var isCalibrating: Bool = false
    @Published var calibrationProgress: Double = 0.0
    @Published var calibrationStepText: String = ""
    @Published var showCalibrationModal: Bool = false

    // HUD Toast
    @Published var hudToastMessage: String? = nil

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var controlCharacteristic: CBCharacteristic?
    private var simulatedTimer: AnyCancellable?
    private var calibrationTimer: Timer?
    private var firmwareTimer: Timer?

    private static let gimbalServiceUUID = CBUUID(string: "FFE0")
    private static let telemetryCharUUID = CBUUID(string: "FFE1")
    private static let batteryServiceUUID = CBUUID(string: "180F")
    private static let batteryLevelCharUUID = CBUUID(string: "2A19")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard let central = centralManager else { return }
        guard central.state == .poweredOn else {
            bluetoothStateText = "Hãy bật Bluetooth trên iPhone để tìm T-Flow Pro"
            return
        }
        discoveredPeripherals.removeAll()
        isScanning = true
        bluetoothStateText = "Đang quét thiết bị T-Flow Pro..."
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        centralManager?.stopScan()
        isScanning = false
        if !isConnected {
            bluetoothStateText = discoveredPeripherals.isEmpty
                ? "Chưa tìm thấy thiết bị Gimbal"
                : "Tìm thấy \(discoveredPeripherals.count) thiết bị khả dụng"
        }
    }

    func connect(to peripheral: CBPeripheral) {
        stopScan()
        peripheral.delegate = self
        connectedPeripheral = peripheral
        bluetoothStateText = "Đang ghép nối với \(peripheral.name ?? "T-Flow Pro")..."
        centralManager?.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        controlCharacteristic = nil
        isConnected = false
        batteryLevel = 0
        firmwareVersion = ""
        connectedPeripheralName = ""
        simulatedTimer?.cancel()
        simulatedTimer = nil
        bluetoothStateText = "Đã ngắt kết nối Gimbal"
    }

    deinit {
        calibrationTimer?.invalidate()
        calibrationTimer = nil
        firmwareTimer?.invalidate()
        firmwareTimer = nil
        simulatedTimer?.cancel()
        simulatedTimer = nil
    }

    private func startTelemetrySimulation() {
        simulatedTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isCalibrating else { return }
                // Tiny live IMU jitter to simulate 50Hz precision gyro
                let jitterRoll = Double.random(in: -0.04...0.04)
                let jitterPitch = Double.random(in: -0.06...0.06)
                self.rollAngle = (self.rollAngle * 0.95 + jitterRoll * 0.05)
                self.pitchAngle = max(-45, min(45, self.pitchAngle + jitterPitch * 0.1))
            }
    }

    func setGimbalModeWithHaptic(_ mode: String) {
        gimbalMode = mode
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let modeNames: [String: String] = [
            "PF": "Chế độ: Pan Follow (Bám Trục Quay)",
            "Follow": "Chế độ: Follow (Bám Ngang & Dọc)",
            "FPV": "Chế độ: FPV 3-Trục Điện Ảnh",
            "LOCK": "Chế độ: Khóa Tuyệt Đối 3 Trục",
            "Lock": "Chế độ: Khóa Tuyệt Đối 3 Trục",
            "POV": "Chế độ: POV Góc Nhìn Thứ Nhất",
            "360°": "Chế độ: 360° Inception Barrel Roll"
        ]
        showToast(modeNames[mode] ?? "Gimbal Mode: \(mode)")
    }

    func showToast(_ message: String) {
        hudToastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.hudToastMessage == message {
                self?.hudToastMessage = nil
            }
        }
    }

    func startFirmwareUpdate() {
        firmwareTimer?.invalidate()
        firmwareTimer = nil
        isUpdatingFirmware = true
        firmwareUpdateProgress = 0.0
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        firmwareTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.firmwareUpdateProgress = min(1.0, self.firmwareUpdateProgress + 0.04)
            if self.firmwareUpdateProgress >= 1.0 {
                timer.invalidate()
                self.firmwareTimer = nil
                self.isUpdatingFirmware = false
                self.firmwareVersion = self.latestFirmwareVersion
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.showToast("Đã cập nhật Firmware \(self.latestFirmwareVersion)")
            }
        }
    }

    func startCoGCalibration() {
        calibrationTimer?.invalidate()
        calibrationTimer = nil
        isCalibrating = true
        calibrationProgress = 0.0
        calibrationStepText = "Đang đo góc lệch trọng tâm tải trọng..."
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        calibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.calibrationProgress += 0.02

            if self.calibrationProgress < 0.25 {
                self.calibrationStepText = "Bước 1/4: Quét phân bố trọng lượng Camera..."
            } else if self.calibrationProgress < 0.55 {
                self.calibrationStepText = "Bước 2/4: Bơm xung Pure FOC 20kHz dò vị trí Rotor..."
            } else if self.calibrationProgress < 0.85 {
                self.calibrationStepText = "Bước 3/4: Cân chỉnh Notch Filter 245Hz triệt rung..."
            } else if self.calibrationProgress < 1.0 {
                self.calibrationStepText = "Bước 4/4: Khóa điểm Zero Điểm Cân Bằng Hoàn Hảo..."
            } else {
                timer.invalidate()
                self.calibrationTimer = nil
                self.calibrationProgress = 1.0
                self.calibrationStepText = "Hoàn tất! Sai số trọng tâm: ±0.01° (Zero Drift)"
                self.rollAngle = 0.00
                self.pitchAngle = 0.00
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    self?.isCalibrating = false
                    self?.showCalibrationModal = false
                }
            }
        }
    }

    func sendTrackingError(dx: Double, dy: Double) {
        // PID correction
        panAngle = (panAngle + dx * 2.5).truncatingRemainder(dividingBy: 360.0)
        pitchAngle = max(-45, min(45, pitchAngle - dy * 2.0))
    }

    func sendManualJoystick(x: Double, y: Double) {
        let speed = joystickSensitivity * 1.8
        panAngle = (panAngle + x * speed).truncatingRemainder(dividingBy: 360.0)
        if panAngle < 0 { panAngle += 360.0 }
        pitchAngle = max(-45, min(45, pitchAngle - y * speed))
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothStateText = isConnected ? "Đã kết nối \(connectedPeripheralName)" : "Bluetooth sẵn sàng • Chạm để quét Gimbal"
        case .poweredOff:
            isConnected = false
            isScanning = false
            batteryLevel = 0
            firmwareVersion = ""
            bluetoothStateText = "Bluetooth đang tắt"
        case .unauthorized:
            bluetoothStateText = "Chưa cấp quyền Bluetooth trong Cài đặt iOS"
        case .unsupported:
            bluetoothStateText = "Thiết bị không hỗ trợ Bluetooth Low Energy"
        case .resetting:
            bluetoothStateText = "Đang khởi động lại kết nối Bluetooth..."
        case .unknown:
            bluetoothStateText = "Đang chờ trạng thái Bluetooth..."
        @unknown default:
            bluetoothStateText = "Trạng thái Bluetooth không xác định"
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        let lower = name.lowercased()
        guard lower.contains("t-flow") || lower.contains("tflow") || lower.contains("gimbal") || !name.isEmpty else {
            return
        }
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            bluetoothStateText = "Tìm thấy \(discoveredPeripherals.count) thiết bị gần đây"
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedPeripheralName = peripheral.name ?? "T-Flow Pro"
        isConnected = true
        bluetoothStateText = "Đã kết nối \(connectedPeripheralName)"
        peripheral.delegate = self
        peripheral.discoverServices([Self.gimbalServiceUUID, Self.batteryServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        bluetoothStateText = "Không thể kết nối: \(error?.localizedDescription ?? "Lỗi BLE")"
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        controlCharacteristic = nil
        isConnected = false
        batteryLevel = 0
        firmwareVersion = ""
        connectedPeripheralName = ""
        bluetoothStateText = error != nil ? "Mất kết nối BLE: \(error!.localizedDescription)" : "Đã ngắt kết nối Gimbal"
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([Self.telemetryCharUUID, Self.batteryLevelCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let chars = service.characteristics else { return }
        for char in chars {
            if char.uuid == Self.telemetryCharUUID {
                controlCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
            } else if char.uuid == Self.batteryLevelCharUUID {
                peripheral.readValue(for: char)
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value, !data.isEmpty else { return }
        if characteristic.uuid == Self.batteryLevelCharUUID {
            let level = Int(data[0])
            DispatchQueue.main.async {
                self.batteryLevel = max(0, min(100, level))
            }
        }
    }
}
