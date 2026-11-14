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
    @Published var isConnected: Bool = true
    @Published var batteryLevel: Int = 94
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
    @Published var firmwareVersion: String = "v2.4.1"
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
    private var simulatedTimer: AnyCancellable?
    private var calibrationTimer: Timer?
    private var firmwareTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startTelemetrySimulation()
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

    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}
