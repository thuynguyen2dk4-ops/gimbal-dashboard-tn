//
//  GimbalDeviceHubView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 14. TAB 2: GIMBAL DEVICE HUB VIEW (SCREEN 30 & 31)
// =====================================================================

struct GimbalDeviceHubView: View {
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var store: SupabaseModuleStore
    @State private var joystickDragOffset: CGSize = .zero

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // HERO HARDWARE CARD
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    TFlowBrandLogo(size: 26)
                                    Text("T-Flow Pro S1")
                                        .font(.system(size: 20, weight: .bold))
                                }
                                Text("Titanium Aerospace Edition • BLE 5.3")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            HStack(spacing: 5) {
                                Circle().fill(Color.green).frame(width: 7, height: 7)
                                Text("50Hz FOC Synced")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Divider().background(Color.white.opacity(0.1))

                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PIN 4500mAh").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("\(ble.batteryLevel)%").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("XUNG ĐIỀU KHIỂN").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("20 kHz").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.green)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRMWARE").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("v2.4.1").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12), lineWidth: 1))

                    // 3-AXIS REALTIME FOC ANGLE GAUGES (Pan, Tilt, Roll)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("GÓC QUAY 3 TRỤC THỜI GIAN THỰC (50Hz IMU)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            if !store.isRawTelemetryAllowed {
                                Label("Đã Khóa", systemImage: "lock.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }

                        if store.isRawTelemetryAllowed {
                            HStack(spacing: 12) {
                                AxisAngleCard(axis: "ROLL", angle: String(format: "%.2f°", ble.rollAngle), status: "Chuẩn Cân", color: .green)
                                AxisAngleCard(axis: "TILT", angle: String(format: "%+.1f°", ble.pitchAngle), status: "Góc Chụp", color: Color(red: 0.98, green: 0.72, blue: 0.10))
                                AxisAngleCard(axis: "PAN", angle: String(format: "%.1f°", ble.panAngle), status: "Quay 360°", color: .cyan)
                            }
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.red)
                                Text("Cần mở khóa Module '500Hz Gyro Raw Telemetry' tại Tab Tài Khoản (gói hiện tại: \(store.userTier)) để xem số liệu góc IMU.")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                        }
                    }

                    // TỰ ĐỘNG CÂN BẰNG TRỌNG TÂM (CoG)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HIỆU CHUẨN ĐỘNG CƠ COG")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            ble.showCalibrationModal = true
                            ble.startCoGCalibration()
                        }) {
                            HStack {
                                Image(systemName: "scope")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tự Động Cân Bằng Trọng Tâm (CoG)")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Tự triệt tiêu rung lắc tải trọng • Sai số ±0.01°")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }

                    // TACTILE VIRTUAL JOYSTICK CONTROLLER
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("CẦN ĐIỀU KHIỂN JOYSTICK ẢO (PAN & TILT)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(ble.joystickSensitivity > 0.7 ? "Thể Thao (1.0x)" : (ble.joystickSensitivity > 0.4 ? "Chuẩn (0.6x)" : "Điện Ảnh Mượt (0.3x)"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                        }

                        // Circular Touch Pad
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 170, height: 170)
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5))

                            // Crosshair lines
                            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 140, height: 1)
                            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 140)

                            // Draggable Thumb Knob
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.98, green: 0.72, blue: 0.10), Color.orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                                .shadow(color: Color.black.opacity(0.5), radius: 6)
                                .offset(joystickDragOffset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let maxDist: CGFloat = 58
                                            let dist = hypot(value.translation.width, value.translation.height)
                                            if dist < maxDist {
                                                joystickDragOffset = value.translation
                                            } else {
                                                let angle = atan2(value.translation.height, value.translation.width)
                                                joystickDragOffset = CGSize(width: cos(angle) * maxDist, height: sin(angle) * maxDist)
                                            }
                                            let nx = Double(joystickDragOffset.width / maxDist)
                                            let ny = Double(joystickDragOffset.height / maxDist)
                                            ble.sendManualJoystick(x: nx, y: ny)
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                joystickDragOffset = .zero
                                            }
                                        }
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        // Sensitivity Slider
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Độ Nhạy Phản Hồi: \(Int(ble.joystickSensitivity * 100))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))

                            Slider(value: $ble.joystickSensitivity, in: 0.1...1.0)
                                .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .cornerRadius(18)

                    // 3-AXIS MOTOR TORQUE LIMITS
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("LỰC KÉO ĐỘNG CƠ PURE FOC (TORQUE)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            if !store.isFocTuningAllowed {
                                Label("Đã Khóa", systemImage: "lock.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }

                        VStack(spacing: 12) {
                            TorqueSliderRow(title: "Pan Motor (Yaw Axis)", value: $ble.panTorque)
                            TorqueSliderRow(title: "Tilt Motor (Pitch Axis)", value: $ble.tiltTorque)
                            TorqueSliderRow(title: "Roll Motor (Horizon Axis)", value: $ble.rollTorque)
                        }
                        .disabled(!store.isFocTuningAllowed)
                        .opacity(store.isFocTuningAllowed ? 1.0 : 0.45)

                        if !store.isFocTuningAllowed {
                            Text("🔒 Cần mở khóa Module 'FOC Motor Micro-Tuning' tại Tab Tài Khoản (gói \(store.userTier)) để tinh chỉnh lực kéo động cơ.")
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.9))
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .cornerRadius(18)
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Thiết Bị T-Flow Pro")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $ble.showCalibrationModal) {
                AutoCalibrationModalView(ble: ble)
            }
        }
    }
}
