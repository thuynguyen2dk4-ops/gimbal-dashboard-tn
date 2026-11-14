//
//  GimbalDeviceHubView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Trung tâm Thiết bị Gimbal (12_Settings_Device_Hub) & Multi-Cam Studio (13_Multicam_Director_Studio).
//

import SwiftUI

struct GimbalDeviceHubView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var joystickOffset: CGSize = .zero
    @State private var showMultiCamSheet: Bool = false
    @State private var showPaywallSheet: Bool = false

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroDeviceCard
                    threeAxisTelemetrySection
                    coGBalanceCard
                    multiCamDirectorCard
                    virtualJoystickCard
                    focTorqueSection
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Gimbal Hub")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $ble.showCalibrationModal) {
                AutoCalibrationModalView(ble: ble)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showMultiCamSheet) {
                MultiCamDirectorStudioSheetView(ble: ble, store: store)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showPaywallSheet) {
                SubscriptionPaywallSheetView(store: store)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Hero Device Card

    private var heroDeviceCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(goldAccent.opacity(0.16))
                    .frame(width: 54, height: 54)
                Image(systemName: "gyroscope")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(goldAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(store.deviceName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Circle()
                        .fill(ble.isConnected ? Color.green : goldAccent)
                        .frame(width: 8, height: 8)
                }
                Text(ble.isConnected ? "BLE 5.3 • Độ trễ 4ms" : "Sẵn sàng kết nối")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    badgeTag(icon: "battery.75", text: "\(ble.batteryLevel)%", color: .green)
                    badgeTag(icon: "dial.low.fill", text: ble.gimbalMode, color: goldAccent)
                }
                .padding(.top, 2)
            }

            Spacer()

            Button {
                ble.isConnected.toggle()
                ble.showToast(ble.isConnected ? "Đã kết nối BLE 5.3" : "Đã ngắt kết nối")
            } label: {
                Text(ble.isConnected ? "Ngắt" : "Kết nối")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ble.isConnected ? Color.gray : appleBlue)
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    // MARK: - 3-Axis Telemetry

    private var threeAxisTelemetrySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CẢM BIẾN 3 TRỤC IMU")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.secondary)
                Spacer()
                if !store.isRawTelemetryAllowed {
                    Button("Mở khóa Pro") {
                        showPaywallSheet = true
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(goldAccent)
                }
            }

            HStack(spacing: 10) {
                AxisAngleCard(
                    axis: "ROLL",
                    angle: store.isRawTelemetryAllowed ? String(format: "%.1f°", ble.rollAngle) : "LOCK",
                    status: abs(ble.rollAngle) < 1.5 ? "Cân bằng" : "Đang chỉnh",
                    color: .green
                )
                AxisAngleCard(
                    axis: "PITCH",
                    angle: store.isRawTelemetryAllowed ? String(format: "%.1f°", ble.pitchAngle) : "LOCK",
                    status: "Ổn định",
                    color: appleBlue
                )
                AxisAngleCard(
                    axis: "PAN",
                    angle: store.isRawTelemetryAllowed ? String(format: "%.0f°", ble.panAngle) : "LOCK",
                    status: "360° Free",
                    color: goldAccent
                )
            }
        }
    }

    // MARK: - CoG Auto-Balance Card

    private var coGBalanceCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "scope")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(appleBlue)
                .frame(width: 44, height: 44)
                .background(appleBlue.opacity(0.14))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text("Cân Bằng Trọng Tâm CoG")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Text("Tự động đo tải 3 trục")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                ble.showCalibrationModal = true
                ble.startCoGCalibration()
            } label: {
                Text("Cân bằng")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(goldAccent)
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    // MARK: - Multi-Cam Director Studio Card (13_Multicam_Director_Studio)

    private var multiCamDirectorCard: some View {
        Button {
            if store.isMultiCamAllowed {
                showMultiCamSheet = true
            } else {
                showPaywallSheet = true
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.8), appleBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "rectangle.grid.2x2.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Multi-Cam Director Studio")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        if !store.isMultiCamAllowed {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(goldAccent)
                        }
                    }
                    Text("Điều phối 4 góc máy • Tally Live")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Virtual Joystick Card

    private var virtualJoystickCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("JOYSTICK ẢO PAN / TILT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Độ nhạy \(Int(ble.joystickSensitivity * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(goldAccent)
            }

            ZStack {
                Circle()
                    .fill(colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.06))
                    .frame(width: 140, height: 140)
                Circle()
                    .stroke(goldAccent.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(goldAccent)
                    .frame(width: 44, height: 44)
                    .shadow(color: goldAccent.opacity(0.35), radius: 8)
                    .offset(joystickOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let maxR: CGFloat = 46
                                let dx = value.translation.width
                                let dy = value.translation.height
                                let dist = sqrt(dx * dx + dy * dy)
                                let scale = dist > maxR ? maxR / dist : 1.0
                                let clamped = CGSize(width: dx * scale, height: dy * scale)
                                joystickOffset = clamped
                                ble.sendManualJoystick(
                                    x: Double(clamped.width / maxR),
                                    y: Double(-clamped.height / maxR)
                                )
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    joystickOffset = .zero
                                }
                            }
                    )
            }

            Slider(value: $ble.joystickSensitivity, in: 0.2...1.0)
                .tint(goldAccent)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    // MARK: - FOC Torque Tuning

    private var focTorqueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MÔ-MEN XOẮN ĐỘNG CƠ FOC")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.secondary)
                Spacer()
                if !store.isFocTuningAllowed {
                    Button("Khóa Pro") {
                        showPaywallSheet = true
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(goldAccent)
                }
            }

            TorqueSliderRow(title: "Pan Motor", value: $ble.panTorque)
                .disabled(!store.isFocTuningAllowed)
                .opacity(store.isFocTuningAllowed ? 1.0 : 0.45)

            TorqueSliderRow(title: "Tilt Motor", value: $ble.tiltTorque)
                .disabled(!store.isFocTuningAllowed)
                .opacity(store.isFocTuningAllowed ? 1.0 : 0.45)

            TorqueSliderRow(title: "Roll Motor", value: $ble.rollTorque)
                .disabled(!store.isFocTuningAllowed)
                .opacity(store.isFocTuningAllowed ? 1.0 : 0.45)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    private func badgeTag(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}

// MARK: - Multi-Cam Director Studio Sheet (13_Multicam_Director_Studio)

struct MultiCamDirectorStudioSheetView: View {
    @ObservedObject var ble: BLEGimbalManager
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) private var dismiss

    @State private var activeProgramCam: String = "CAM A"
    @State private var isGenlockSynced: Bool = true

    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)

    private struct CameraFeed: Identifiable {
        let id: String
        let role: String
        let lens: String
        let status: String
    }

    private let feeds: [CameraFeed] = [
        CameraFeed(id: "CAM A", role: "Master Gimbal", lens: "24mm • 4K60", status: "LIVE"),
        CameraFeed(id: "CAM B", role: "Góc Rộng", lens: "13mm • 4K30", status: "SYNC"),
        CameraFeed(id: "CAM C", role: "Cận Cảnh Tele", lens: "77mm • 4K60", status: "SYNC"),
        CameraFeed(id: "CAM D", role: "Overhead", lens: "24mm • 1080p", status: "STANDBY")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                // Genlock & Master Sync Header Bar
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isGenlockSynced ? Color.green : goldAccent)
                            .frame(width: 8, height: 8)
                        Text(isGenlockSynced ? "Genlock Wi-Fi 6 • 0.8ms" : "Đang đồng bộ...")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    Spacer()
                    Button("Cut Program") {
                        ble.showToast("PGM: \(activeProgramCam)")
                    }
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 2x2 Multi-View Grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(feeds) { feed in
                        let isLive = activeProgramCam == feed.id
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            activeProgramCam = feed.id
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.10, green: 0.13, blue: 0.20), Color.black],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 155)

                                VStack {
                                    HStack {
                                        Text(feed.id)
                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(isLive ? Color.red : goldAccent)
                                            .cornerRadius(5)
                                        Spacer()
                                        Text(isLive ? "PGM" : feed.status)
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(isLive ? .red : .green)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.black.opacity(0.65))
                                            .cornerRadius(4)
                                    }
                                    Spacer()
                                }
                                .padding(10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feed.role)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(feed.lens)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(10)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isLive ? Color.red : appleBlue.opacity(0.25), lineWidth: isLive ? 2.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Multi-Cam Director Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
