//
//  GimbalDeviceHubView.swift
//  SmartGimbalPro
//
//  Figma Node 96:3 — 26_home (Templates), 30_device (Device Hub & Sliders),
//  32_firmware_update (OTA), 33_settings & 34_appearance (Settings + Theme).
//

import SwiftUI
import UIKit

struct GimbalDeviceHubView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme

    @State private var showMultiCamSheet: Bool = false
    @State private var showFirmwareUpdateSheet: Bool = false
    @State private var showDeviceSettingsSheet: Bool = false
    @State private var joystickOffset: CGSize = .zero

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A
    private let gimbalModes = ["PF", "Lock", "Follow", "FPV", "POV"]

    private var surfaceBackground: Color {
        colorScheme == .light ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color(red: 0.04, green: 0.04, blue: 0.06)
    }

    private var cardBackground: Color {
        colorScheme == .light ? Color.white : Color.white.opacity(0.06)
    }

    private var cardStroke: Color {
        colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.10)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroDeviceCard
                    gimbalModeSegmentedStrip
                    quickActionsSection
                    cinemaTemplatesSection
                    axisTuningSection
                    virtualJoystickCard
                    threeAxisTelemetrySection
                    focTorqueSection
                    multiCamDirectorCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(surfaceBackground.ignoresSafeArea())
            .navigationTitle("Thiết bị")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDeviceSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(accentYellow)
                    }
                }
            }
            .sheet(isPresented: $ble.showCalibrationModal) {
                AutoCalibrationModalView(ble: ble)
            }
            .sheet(isPresented: $showMultiCamSheet) {
                MultiCamDirectorStudioSheetView(ble: ble, store: store)
            }
            .sheet(isPresented: $showFirmwareUpdateSheet) {
                FirmwareUpdateSheetView(ble: ble)
            }
            .sheet(isPresented: $showDeviceSettingsSheet) {
                DeviceSettingsSheetView(camera: camera, store: store, ble: ble)
            }
        }
    }

    // MARK: - 1. Hero Device Card (30_device)

    private var heroDeviceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(ble.isConnected ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)

                        Text(ble.isConnected ? "ĐÃ KẾT NỐI (BLE 5.3)" : "CHƯA KẾT NỐI BLE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(ble.isConnected ? .green : .orange)
                    }

                    Text("Smart Gimbal S1")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Pin: \(ble.batteryLevel)% • FW: \(ble.firmwareVersion)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentYellow.opacity(0.14))
                        .frame(width: 56, height: 56)

                    Image(systemName: "gyroscope")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(accentYellow)
                }
            }

            if ble.isCalibrating {
                HStack(spacing: 8) {
                    ProgressView(value: ble.calibrationProgress)
                        .tint(accentYellow)
                    Text("\(Int(ble.calibrationProgress * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(accentYellow)
                }
            }

            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.showPairingModal = true
                } label: {
                    Label("Quét/Ghép đôi BLE", systemImage: "dot.radiowaves.left.and.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.secondary.opacity(0.15))
                        )
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showFirmwareUpdateSheet = true
                } label: {
                    Label("Cập nhật FW \(ble.latestFirmwareVersion)", systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(accentYellow)
                        )
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardStroke, lineWidth: 1))
    }

    // MARK: - 2. Gimbal Mode Segmented Strip (30_device)

    private var gimbalModeSegmentedStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CHẾ ĐỘ HOẠT ĐỘNG")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                Spacer()
                Text(ble.gimbalMode)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accentYellow)
            }

            HStack(spacing: 6) {
                ForEach(gimbalModes, id: \.self) { mode in
                    let isSelected = ble.gimbalMode.caseInsensitiveCompare(mode) == .orderedSame
                    Button {
                        ble.setGimbalModeWithHaptic(mode)
                    } label: {
                        Text(mode)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isSelected ? .black : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? accentYellow : Color.secondary.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardStroke, lineWidth: 1))
    }

    // MARK: - 3. Quick Actions (30_device)

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THAO TÁC NHANH")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                quickActionRow(
                    icon: "cube.transparent",
                    iconBg: .blue,
                    title: "Hiệu chỉnh 6 mặt cảm biến",
                    subtitle: "Đặt phẳng & khóa Zero Roll ±0.01°"
                ) {
                    ble.showCalibrationModal = true
                }
                Divider().padding(.leading, 52)

                quickActionRow(
                    icon: "gyroscope",
                    iconBg: .orange,
                    title: "Tự động cân bằng động cơ",
                    subtitle: ble.isCalibrating ? ble.calibrationStepText : "Bơm xung Pure FOC 20kHz dò trọng tâm"
                ) {
                    ble.startCoGCalibration()
                }
                Divider().padding(.leading, 52)

                quickActionRow(
                    icon: "video.fill",
                    iconBg: .red,
                    title: "Mở Camera Quay Phim",
                    subtitle: camera.isProMode ? "Đang bật chế độ Chuyên nghiệp (Pro)" : "Đang bật chế độ Cơ bản"
                ) {
                    store.activeMainTab = 0
                }
                Divider().padding(.leading, 52)

                quickActionRow(
                    icon: "sparkles",
                    iconBg: .purple,
                    title: "Trợ lý AI Copilot",
                    subtitle: "Hỏi đáp thông số & điều khiển Gimbal bằng lệnh"
                ) {
                    store.showAiCopilotSheet = true
                }
                Divider().padding(.leading, 52)

                quickActionRow(
                    icon: "slider.horizontal.3",
                    iconBg: .gray,
                    title: "Cài đặt & Giao diện",
                    subtitle: "Sáng/Tối, Cơ bản/Pro, 4K & kết nối BLE"
                ) {
                    showDeviceSettingsSheet = true
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardStroke, lineWidth: 1))
        }
    }

    private func quickActionRow(
        icon: String,
        iconBg: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBg)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Cinema Templates (26_home)

    private var cinemaTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MẪU QUAY ĐIỆN ẢNH (TEMPLATES)")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                cinemaTemplateCard(
                    title: "360° Inception Roll",
                    subtitle: "Xoay trục Roll 360° tự động",
                    icon: "rotate.3d",
                    gradient: [Color(red: 0.98, green: 0.72, blue: 0.10), Color(red: 0.85, green: 0.42, blue: 0.08)]
                ) {
                    ble.setGimbalModeWithHaptic("360°")
                    store.activeMainTab = 0
                }

                cinemaTemplateCard(
                    title: "ZOOM Dolly Hitchcock",
                    subtitle: "Bám chuyển động + Zoom 2x",
                    icon: "camera.aperture",
                    gradient: [Color(red: 0.16, green: 0.50, blue: 0.98), Color(red: 0.34, green: 0.24, blue: 0.90)]
                ) {
                    ble.setGimbalModeWithHaptic("Follow")
                    camera.setZoom("2x")
                    ble.showToast("Cinema Template: ZOOM Dolly Hitchcock")
                    store.activeMainTab = 0
                }
            }
        }
    }

    private func cinemaTemplateCard(
        title: String,
        subtitle: String,
        icon: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.22)))

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.86))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 5. Axis Smoothness & Joystick Sliders (30_device)

    private var axisTuningSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TINH CHỈNH TRỤC & JOYSTICK")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.secondary)

            axisSliderRow(
                title: "Độ nhạy cần điều khiển (Joystick)",
                value: $ble.joystickSensitivity,
                range: 0.1...1.0
            )
            axisSliderRow(
                title: "Độ mượt trục Pan",
                value: $ble.smoothPan,
                range: 0.1...1.0
            )
            axisSliderRow(
                title: "Độ mượt trục Tilt",
                value: $ble.smoothTilt,
                range: 0.1...1.0
            )
            axisSliderRow(
                title: "Độ mượt trục Roll",
                value: $ble.smoothRoll,
                range: 0.1...1.0
            )
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardStroke, lineWidth: 1))
    }

    private func axisSliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(accentYellow)
            }
            Slider(value: value, in: range)
                .tint(accentYellow)
        }
    }

    // MARK: - 6. 2D Virtual Joystick

    private var virtualJoystickCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ĐIỀU KHIỂN JOYSTICK ẢO (PAN / TILT)")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "Pan %.1f°", ble.panAngle))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(accentYellow)
            }

            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 136, height: 136)
                    .overlay(Circle().stroke(cardStroke, lineWidth: 1))

                Circle()
                    .fill(accentYellow)
                    .frame(width: 48, height: 48)
                    .shadow(color: accentYellow.opacity(0.35), radius: 8)
                    .offset(joystickOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let maxRadius: CGFloat = 44
                                let dx = gesture.translation.width
                                let dy = gesture.translation.height
                                let dist = sqrt(dx * dx + dy * dy)
                                let scale = dist > maxRadius ? maxRadius / dist : 1.0
                                let clamped = CGSize(width: dx * scale, height: dy * scale)
                                joystickOffset = clamped
                                ble.sendManualJoystick(
                                    x: Double(clamped.width / maxRadius),
                                    y: Double(clamped.height / maxRadius)
                                )
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    joystickOffset = .zero
                                }
                            }
                    )
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardStroke, lineWidth: 1))
    }

    // MARK: - 7. 3-Axis IMU Telemetry

    private var threeAxisTelemetrySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CẢM BIẾN IMU 3 TRỤC (50Hz)")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                Spacer()
                Text(store.isRawTelemetryAllowed ? "LIVE" : "LOCKED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(store.isRawTelemetryAllowed ? .green : .orange)
            }

            HStack(spacing: 10) {
                AxisAngleCard(
                    axis: "ROLL",
                    angle: String(format: "%.2f°", ble.rollAngle),
                    status: "Zero Drift",
                    color: .cyan
                )
                AxisAngleCard(
                    axis: "PITCH",
                    angle: String(format: "%.1f°", ble.pitchAngle),
                    status: "Ổn định",
                    color: accentYellow
                )
                AxisAngleCard(
                    axis: "PAN",
                    angle: String(format: "%.1f°", ble.panAngle),
                    status: ble.gimbalMode,
                    color: .green
                )
            }
        }
    }

    // MARK: - 8. FOC Motor Torque

    private var focTorqueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MÔ-MEN ĐỘNG CƠ PURE FOC 20KHZ")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                Spacer()
                Text(store.isFocTuningAllowed ? "VIP" : "PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(accentYellow)
            }

            TorqueSliderRow(title: "Lực giữ trục Pan", value: $ble.panTorque)
            TorqueSliderRow(title: "Lực giữ trục Tilt", value: $ble.tiltTorque)
            TorqueSliderRow(title: "Lực giữ trục Roll", value: $ble.rollTorque)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardStroke, lineWidth: 1))
        .opacity(store.isFocTuningAllowed ? 1.0 : 0.6)
        .disabled(!store.isFocTuningAllowed)
    }

    // MARK: - 9. Multi-Cam Director Card (Preserved)

    private var multiCamDirectorCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showMultiCamSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.indigo.opacity(0.20))
                        .frame(width: 44, height: 44)
                    Image(systemName: "rectangle.split.2x2.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.indigo)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Multi-Cam Director Studio")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Đồng bộ 4 góc quay LAN + Gimbal Master")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 32_firmware_update: Firmware OTA Sheet

struct FirmwareUpdateSheetView: View {
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A

    private var isUpToDate: Bool {
        !ble.isUpdatingFirmware && ble.firmwareVersion == ble.latestFirmwareVersion
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 9)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: ble.isUpdatingFirmware ? ble.firmwareUpdateProgress : (isUpToDate ? 1.0 : 0.18))
                            .stroke(isUpToDate ? Color.green : accentYellow, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.15), value: ble.firmwareUpdateProgress)

                        VStack(spacing: 2) {
                            Image(systemName: isUpToDate ? "checkmark.seal.fill" : "cpu")
                                .font(.system(size: 26))
                                .foregroundColor(isUpToDate ? .green : accentYellow)
                            Text(
                                ble.isUpdatingFirmware
                                    ? "\(Int(ble.firmwareUpdateProgress * 100))%"
                                    : (isUpToDate ? "Mới nhất" : ble.latestFirmwareVersion)
                            )
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text("Firmware \(ble.latestFirmwareVersion)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Phiên bản hiện tại: \(ble.firmwareVersion) • BLE 5.3 OTA")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("NỘI DUNG BẢN CẬP NHẬT")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.secondary)

                        releaseNoteRow(
                            badge: "FOC 4.0",
                            text: "Tối ưu vòng điều khiển Pure FOC 20kHz, giảm rung trục Roll khi chạy bộ."
                        )
                        releaseNoteRow(
                            badge: "BLE 5.3",
                            text: "Tăng tốc độ ghép đôi không chạm và truyền Telemetry góc nghiêng 50Hz."
                        )
                        releaseNoteRow(
                            badge: "AI 360°",
                            text: "Bổ sung khóa mượt góc xoay 360° Inception & Zoom Dolly Hitchcock."
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .light ? Color.white : Color.white.opacity(0.06))
                    )

                    Button {
                        if isUpToDate {
                            dismiss()
                        } else {
                            ble.startFirmwareUpdate()
                        }
                    } label: {
                        Text(
                            ble.isUpdatingFirmware
                                ? "Đang nạp Firmware OTA..."
                                : (isUpToDate ? "Đã cập nhật mới nhất • Đóng" : "Cập nhật Firmware \(ble.latestFirmwareVersion)")
                        )
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(isUpToDate ? Color.green : accentYellow)
                        )
                    }
                    .disabled(ble.isUpdatingFirmware)
                }
                .padding(20)
            }
            .background(
                (colorScheme == .light ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color.black)
                    .ignoresSafeArea()
            )
            .navigationTitle("Cập nhật Firmware")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(accentYellow)
                }
            }
        }
    }

    private func releaseNoteRow(badge: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(badge)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(accentYellow))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 33_settings & 34_appearance: Device Settings & Theme Sheet

struct DeviceSettingsSheetView: View {
    @ObservedObject var camera: CameraService
    @ObservedObject var store: SupabaseModuleStore
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) private var dismiss

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A
    private let resolutions = ["4K • 60", "4K • 30", "1080 • 60"]

    var body: some View {
        NavigationStack {
            Form {
                Section("GIAO DIỆN & CHỦ ĐỀ (34_APPEARANCE)") {
                    HStack(spacing: 10) {
                        themeOptionCard(mode: "light", title: "Sáng", icon: "sun.max.fill")
                        themeOptionCard(mode: "dark", title: "Tối", icon: "moon.fill")
                        themeOptionCard(mode: "auto", title: "Tự động", icon: "circle.lefthalf.filled")
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chế độ Camera mặc định")
                            .font(.system(size: 13, weight: .semibold))
                        Picker("Chế độ Camera mặc định", selection: Binding(
                            get: { camera.isProMode ? 1 : 0 },
                            set: { idx in camera.setCameraInterfaceMode(pro: idx == 1) }
                        )) {
                            Text("Cơ bản").tag(0)
                            Text("Chuyên nghiệp").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                }

                Section("CAMERA & QUAY PHIM (33_SETTINGS)") {
                    Picker("Độ phân giải", selection: $camera.selectedResolution) {
                        ForEach(resolutions, id: \.self) { res in
                            Text(res).tag(res)
                        }
                    }

                    Toggle("Lưới bố cục (Grid 1/3)", isOn: $camera.gridEnabled)
                    Toggle("Lưu tự động vào Ảnh", isOn: $store.saveToPhotosEnabled)
                }

                Section("GIMBAL & KẾT NỐI") {
                    Toggle("Tự động kết nối BLE", isOn: $store.autoReconnectBLE)
                    Toggle("Âm thanh bíp Gimbal", isOn: $store.gyroBeepsEnabled)

                    Button("Hiệu chỉnh cảm biến 6 mặt") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            ble.showCalibrationModal = true
                        }
                    }

                    Button("Quét / Ghép đôi Bluetooth") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            store.showPairingModal = true
                        }
                    }
                }
            }
            .navigationTitle("Cài đặt & Giao diện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(accentYellow)
                }
            }
        }
    }

    private func themeOptionCard(mode: String, title: String, icon: String) -> some View {
        let isSelected = camera.uiThemeMode == mode
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            camera.uiThemeMode = mode
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentYellow : Color.secondary.opacity(0.14))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preserved Multi-Cam Director Studio

struct CameraFeed: Identifiable {
    let id: String
    let angleName: String
    let lens: String
    let status: String
}

struct MultiCamDirectorStudioSheetView: View {
    @ObservedObject var ble: BLEGimbalManager
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) private var dismiss

    @State private var activeCamId: String = "CH-01"
    private let feeds: [CameraFeed] = [
        CameraFeed(id: "CH-01", angleName: "Gimbal Master (Wide 1x)", lens: "24mm f/1.78", status: "LIVE"),
        CameraFeed(id: "CH-02", angleName: "Góc phụ Trái (Ultra-Wide)", lens: "13mm f/2.2", status: "SYNCED"),
        CameraFeed(id: "CH-03", angleName: "Cận cảnh (Telephoto 5x)", lens: "120mm f/2.8", status: "SYNCED"),
        CameraFeed(id: "CH-04", angleName: "Drone Overhead (Top-Down)", lens: "4K 60fps", status: "STANDBY")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(feeds) { feed in
                        let isLive = feed.id == activeCamId
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            activeCamId = feed.id
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(feed.id)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(isLive ? .black : .white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(isLive ? Color(red: 1.0, green: 0.84, blue: 0.04) : Color.white.opacity(0.18)))
                                    Spacer()
                                    Text(isLive ? "PGM" : feed.status)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(isLive ? .red : .secondary)
                                }

                                Text(feed.angleName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)

                                Text(feed.lens)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.secondary.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isLive ? Color.red : Color.secondary.opacity(0.2), lineWidth: isLive ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Text("Active Program Feed: \(activeCamId) • Pin Gimbal \(ble.batteryLevel)%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Multi-Cam Director")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}
