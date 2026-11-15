//
//  GimbalDeviceHubView.swift
//  SmartGimbalPro
//
//  Figma Node 96:3 — 30_device (Device Hub & Blue Sliders),
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
    @State private var showEngineerDashboardSheet: Bool = false
    @State private var showFeatureFlagsSheet: Bool = false
    @State private var showProTuning: Bool = true
    @State private var joystickOffset: CGSize = .zero

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A
    private let iosBlue = Color(UIColor.systemBlue)
    private let gimbalModes = ["PF", "Lock", "Follow", "FPV", "POV"]

    private var surfaceBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }

    private var cardBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }

    private var cardStroke: Color {
        Color(UIColor.separator).opacity(0.35)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Thiết bị")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 4)

                    heroDeviceCard
                    gimbalModeSegmentedStrip
                    quickActionsSection
                    axisTuningSection

                    DisclosureGroup(isExpanded: $showProTuning) {
                        VStack(spacing: 14) {
                            virtualJoystickCard
                            threeAxisTelemetrySection
                            focTorqueSection
                            multiCamDirectorCard
                        }
                        .padding(.top, 10)
                    } label: {
                        Text("ĐIỀU KHIỂN NÂNG CAO & TELEMETRY FOC")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.4)
                            .foregroundColor(.secondary)
                    }
                    .tint(iosBlue)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(cardStroke, lineWidth: 0.5))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .background(surfaceBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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
            .sheet(isPresented: $showEngineerDashboardSheet) {
                EngineerTelemetryDashboardView()
            }
            .sheet(isPresented: $showFeatureFlagsSheet) {
                FeatureFlagsAdminView()
            }
            .onChange(of: ble.firmwareVersion) { newFw in
                store.updateDeviceTelemetry(battery: ble.batteryLevel, firmware: newFw)
            }
            .onChange(of: ble.isConnected) { connected in
                if connected {
                    store.updateDeviceTelemetry(battery: ble.batteryLevel, firmware: ble.firmwareVersion)
                }
            }
        }
    }

    // MARK: - 1. Hero Device Card (30_device)

    private var heroDeviceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                GimbalDeviceThumbVector(accentYellow: accentYellow)
                    .frame(width: 70, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.tertiarySystemFill))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ble.isConnected ? Color(UIColor.systemGreen) : Color(UIColor.systemOrange))
                            .frame(width: 8, height: 8)

                        Text(ble.isConnected ? "ĐÃ KẾT NỐI (BLE 5.3)" : "CHỜ KẾT NỐI (BLE 5.3)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ble.isConnected ? Color(UIColor.systemGreen) : Color(UIColor.systemOrange))
                    }

                    Text(ble.connectedPeripheralName.isEmpty ? "Smart Gimbal S1" : ble.connectedPeripheralName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    let batteryLabel = ble.isConnected ? "\(ble.batteryLevel)%" : "92%"
                    let fwLabel = ble.firmwareVersion.isEmpty ? "v2.4.1" : ble.firmwareVersion
                    HStack(spacing: 4) {
                        Text("Pin:")
                        Text(batteryLabel).fontWeight(.semibold).foregroundColor(.primary)
                        Text("• FW:")
                        Text(fwLabel).fontWeight(.semibold).foregroundColor(.primary)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            store.showPairingModal = true
                        } label: {
                            Label("Quét BLE", systemImage: "dot.radiowaves.left.and.right")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color(UIColor.tertiarySystemFill)))
                        }
                        .buttonStyle(.plain)

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showFirmwareUpdateSheet = true
                        } label: {
                            Label("FW \(ble.latestFirmwareVersion)", systemImage: "arrow.down.circle.fill")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(accentYellow))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)
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
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 0.5))
    }

    // MARK: - 2. Gimbal Mode Segmented Strip (30_device)

    private var gimbalModeSegmentedStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHẾ ĐỘ HOẠT ĐỘNG")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)

            HStack(spacing: 2) {
                ForEach(gimbalModes, id: \.self) { mode in
                    let isSelected = ble.gimbalMode.caseInsensitiveCompare(mode) == .orderedSame
                    Button {
                        ble.setGimbalModeWithHaptic(mode)
                    } label: {
                        Text(mode)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? Color(UIColor.tertiarySystemBackground) : Color.clear)
                                    .shadow(color: isSelected ? Color.black.opacity(0.18) : .clear, radius: 2, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemFill))
            )
        }
    }

    // MARK: - 3. Quick Actions (30_device)

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THAO TÁC NHANH")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                quickActionRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconBg: Color(UIColor.systemBlue),
                    title: "Hiệu chỉnh 6 mặt cảm biến",
                    trailing: nil
                ) {
                    ble.showCalibrationModal = true
                }
                Divider().padding(.leading, 56)

                quickActionRow(
                    icon: "gyroscope",
                    iconBg: Color(UIColor.systemGreen),
                    title: "Tự động cân bằng động cơ",
                    trailing: ble.isCalibrating ? "\(Int(ble.calibrationProgress * 100))%" : nil
                ) {
                    ble.startCoGCalibration()
                    ble.showCalibrationModal = true
                }
                Divider().padding(.leading, 56)

                quickActionRow(
                    icon: "arrow.down.app.fill",
                    iconBg: Color(UIColor.systemOrange),
                    title: "Cập nhật phần mềm (OTA)",
                    trailing: ble.latestFirmwareVersion
                ) {
                    showFirmwareUpdateSheet = true
                }
                Divider().padding(.leading, 56)

                if store.isAdmin {
                quickActionRow(
                    icon: "waveform.path.ecg",
                    iconBg: Color(UIColor.systemPurple),
                    title: "Bảng điều khiển Kỹ sư FOC",
                    trailing: "20kHz"
                ) {
                    showEngineerDashboardSheet = true
                }
                Divider().padding(.leading, 56)
                }

                quickActionRow(
                    icon: "gearshape.fill",
                    iconBg: Color(UIColor.systemGray),
                    title: "Cài đặt hệ thống & Giao diện",
                    trailing: camera.uiThemeMode == "light" ? "Sáng" : (camera.uiThemeMode == "auto" ? "Tự động" : "Tối")
                ) {
                    showDeviceSettingsSheet = true
                }
            }
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(cardStroke, lineWidth: 0.5))
        }
    }

    private func quickActionRow(
        icon: String,
        iconBg: Color,
        title: String,
        trailing: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(iconBg)
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.system(size: 15.5, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                if let trailing = trailing {
                    Text(trailing)
                        .font(.system(size: 13.5))
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Axis Smoothness & Joystick Sliders (30_device Blue Style)

    private var axisTuningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TINH CHỈNH THÔNG SỐ TRỤC")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)

            VStack(spacing: 14) {
                axisSliderRow(
                    title: "Độ nhạy cần điều khiển (Joystick)",
                    value: $ble.joystickSensitivity,
                    range: 0.1...1.0
                )
                Divider()
                axisSliderRow(
                    title: "Độ mượt trục Pan (Xoay ngang)",
                    value: $ble.smoothPan,
                    range: 0.1...1.0
                )
                Divider()
                axisSliderRow(
                    title: "Độ mượt trục Tilt (Nghiêng dọc)",
                    value: $ble.smoothTilt,
                    range: 0.1...1.0
                )
                Divider()
                axisSliderRow(
                    title: "Độ mượt trục Roll (Cuộn nghiêng)",
                    value: $ble.smoothRoll,
                    range: 0.1...1.0
                )
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(cardStroke, lineWidth: 0.5))
        }
    }

    private func axisSliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.system(size: 13.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(iosBlue)
            }
            Slider(value: value, in: range)
                .tint(iosBlue)
        }
    }

    // MARK: - 5. 2D Virtual Joystick

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
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(UIColor.tertiarySystemGroupedBackground)))
    }

    // MARK: - 6. 3-Axis IMU Telemetry

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

    // MARK: - 7. FOC Motor Torque

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
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(UIColor.tertiarySystemGroupedBackground)))
        .opacity(store.isFocTuningAllowed ? 1.0 : 0.6)
        .disabled(!store.isFocTuningAllowed)
    }

    // MARK: - 8. Multi-Cam Director Card

    private var multiCamDirectorCard: some View {
        HStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showMultiCamSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.split.2x2.fill")
                        .foregroundColor(.indigo)
                    Text("Multi-Cam Director")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.tertiarySystemGroupedBackground)))
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showFeatureFlagsSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(iosBlue)
                    Text("Cờ tính năng")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.tertiarySystemGroupedBackground)))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Gimbal 3-Axis Miniature Illustration (30_device_dark.html SVG)

private struct GimbalDeviceThumbVector: View {
    let accentYellow: Color

    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 100.0
            let sy = size.height / 120.0
            let s = min(sx, sy)
            let dx = (size.width - 100.0 * s) * 0.5
            let dy = (size.height - 120.0 * s) * 0.5

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: dx + x * s, y: dy + y * s)
            }

            let primaryInk = Color.primary.opacity(0.85)

            // Handle
            let handle = Path(roundedRect: CGRect(x: dx + 44 * s, y: dy + 60 * s, width: 12 * s, height: 50 * s), cornerRadius: 6 * s)
            ctx.fill(handle, with: .color(primaryInk))

            // Power dot on handle
            let dot = Path(ellipseIn: CGRect(x: dx + 47.5 * s, y: dy + 71.5 * s, width: 5 * s, height: 5 * s))
            ctx.fill(dot, with: .color(accentYellow))

            // Pan base block
            let base = Path(roundedRect: CGRect(x: dx + 38 * s, y: dy + 50 * s, width: 24 * s, height: 10 * s), cornerRadius: 3 * s)
            ctx.fill(base, with: .color(primaryInk))

            // Main curved arm
            var arm = Path()
            arm.move(to: pt(50, 50))
            arm.addLine(to: pt(50, 34))
            arm.addLine(to: pt(74, 34))
            arm.addLine(to: pt(74, 16))
            arm.addLine(to: pt(30, 16))
            ctx.stroke(arm, with: .color(primaryInk), style: StrokeStyle(lineWidth: 5 * s, lineCap: .round, lineJoin: .round))

            // Joint motors
            let m1 = Path(ellipseIn: CGRect(x: dx + 68 * s, y: dy + 10 * s, width: 12 * s, height: 12 * s))
            let m2 = Path(ellipseIn: CGRect(x: dx + 24 * s, y: dy + 10 * s, width: 12 * s, height: 12 * s))
            ctx.fill(m1, with: .color(accentYellow))
            ctx.fill(m2, with: .color(accentYellow))
        }
    }
}

// MARK: - 32_firmware_update: Firmware OTA Sheet

struct FirmwareUpdateSheetView: View {
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) private var dismiss

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A

    private var isUpToDate: Bool {
        !ble.isUpdatingFirmware && ble.firmwareVersion == ble.latestFirmwareVersion
    }

    private var displayProgress: Double {
        if ble.isUpdatingFirmware {
            return ble.firmwareUpdateProgress
        }
        return isUpToDate ? 1.0 : 0.74
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero OTA Card matching 32_firmware_update_dark.html
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isUpToDate ? "ĐÃ CẬP NHẬT MỚI NHẤT" : "BẢN CẬP NHẬT MỚI")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(isUpToDate ? Color(UIColor.systemGreen) : accentYellow))

                                Text("Firmware \(ble.latestFirmwareVersion)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.top, 2)

                                let curFw = ble.firmwareVersion.isEmpty ? "v2.4.0" : ble.firmwareVersion
                                Text("Dung lượng: 14.8 MB • Hiện tại: \(curFw)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("\(Int(displayProgress * 100))%")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(isUpToDate ? Color(UIColor.systemGreen) : accentYellow)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(UIColor.tertiarySystemFill))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isUpToDate ? Color(UIColor.systemGreen) : accentYellow)
                                    .frame(width: max(6, geo.size.width * displayProgress))
                                    .animation(.easeOut(duration: 0.15), value: displayProgress)
                            }
                        }
                        .frame(height: 6)
                        .padding(.top, 4)

                        Text(
                            ble.isUpdatingFirmware
                                ? "Đang truyền gói firmware vào Smart Gimbal S1..."
                                : (isUpToDate ? "Smart Gimbal S1 đã cài đặt phiên bản mới nhất." : "Sẵn sàng truyền gói firmware vào Smart Gimbal S1 qua BLE 5.3 OTA.")
                        )
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 0.5)
                    )

                    Text("GHI CHÚ BẢN PHÁT HÀNH")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.bottom, -6)

                    VStack(alignment: .leading, spacing: 10) {
                        releaseNoteText(
                            number: "1. Tối ưu thuật toán FOC 4.0:",
                            body: "Tăng 30% lực mô-men xoắn cho trục Roll khi gắn iPhone 16 Pro Max kèm ốp nặng."
                        )
                        releaseNoteText(
                            number: "2. Giảm độ trễ BLE 5.3:",
                            body: "Thời gian phản hồi cử chỉ joystick tức thì hơn 35%."
                        )
                        releaseNoteText(
                            number: "3. Sửa lỗi:",
                            body: "Triệt tiêu rung giật vi mô khi di chuyển tốc độ cao góc thấp."
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )

                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color(UIColor.systemOrange))
                            .frame(width: 3)
                            .cornerRadius(2)

                        Text("**Lưu ý:** Giữ gimbal cách điện thoại dưới 1 mét và không tắt nguồn trong khi cài đặt.")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(UIColor.systemOrange).opacity(0.12))
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
                                : (isUpToDate ? "Đã cập nhật mới nhất • Đóng" : "Cài đặt Firmware \(ble.latestFirmwareVersion)")
                        )
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isUpToDate ? Color(UIColor.systemGreen) : accentYellow)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(ble.isUpdatingFirmware)
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Cập nhật phần mềm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Cài đặt")
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
            }
        }
    }

    private func releaseNoteText(number: String, body: String) -> some View {
        (Text(number).fontWeight(.bold) + Text(" \(body)"))
            .font(.system(size: 14))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 33_settings & 34_appearance: Device Settings & Appearance Selector

struct DeviceSettingsSheetView: View {
    @ObservedObject var camera: CameraService
    @ObservedObject var store: SupabaseModuleStore
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCodec: String = "ProRes 422HQ"
    private let resolutions = ["4K 60fps HDR", "4K • 60", "4K • 30", "1080 • 60"]

    private var themeLabel: String {
        switch camera.uiThemeMode {
        case "light": return "Sáng"
        case "auto": return "Tự động"
        default: return "Tối"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("GIAO DIỆN & CHẾ ĐỘ") {
                    NavigationLink {
                        AppearanceSettingsSubView(camera: camera)
                    } label: {
                        settingsRowLabel(
                            icon: "sun.max.fill",
                            bg: Color(UIColor.systemBlue),
                            title: "Giao diện",
                            trailing: themeLabel
                        )
                    }

                    NavigationLink {
                        AppearanceSettingsSubView(camera: camera)
                    } label: {
                        settingsRowLabel(
                            icon: "camera.fill",
                            bg: Color(UIColor.systemOrange),
                            title: "Chế độ camera mặc định",
                            trailing: camera.isProMode ? "Chuyên nghiệp" : "Cơ bản"
                        )
                    }
                }

                Section("QUAY & LƯU TRỮ") {
                    Picker(selection: $camera.selectedResolution) {
                        ForEach(resolutions, id: \.self) { res in
                            Text(res).tag(res)
                        }
                    } label: {
                        settingsIconTitle(icon: "video.fill", bg: Color(UIColor.systemRed), title: "Chất lượng video")
                    }

                    Picker(selection: $selectedCodec) {
                        Text("ProRes 422HQ").tag("ProRes 422HQ")
                        Text("HEVC (H.265) 10-bit").tag("HEVC 10-bit")
                    } label: {
                        settingsIconTitle(icon: "film", bg: Color(UIColor.systemPurple), title: "Định dạng nén")
                    }

                    Toggle(isOn: $store.saveToPhotosEnabled) {
                        settingsIconTitle(icon: "photo.fill", bg: Color(UIColor.systemGreen), title: "Lưu vào Ảnh")
                    }
                    .tint(Color(UIColor.systemGreen))

                    Toggle(isOn: $camera.gridEnabled) {
                        settingsIconTitle(icon: "square.grid.2x2.fill", bg: Color(UIColor.systemYellow), title: "Hiển thị lưới & Cân bằng")
                    }
                    .tint(Color(UIColor.systemGreen))
                }

                Section("KẾT NỐI & ÂM THANH") {
                    Toggle(isOn: $store.autoReconnectBLE) {
                        settingsIconTitle(icon: "dot.radiowaves.left.and.right", bg: Color(UIColor.systemBlue), title: "Tự động kết nối lại")
                    }
                    .tint(Color(UIColor.systemGreen))

                    Toggle(isOn: $store.gyroBeepsEnabled) {
                        settingsIconTitle(icon: "speaker.wave.2.fill", bg: Color(UIColor.systemGray), title: "Âm thanh bíp Gimbal")
                    }
                    .tint(Color(UIColor.systemGreen))

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            ble.showCalibrationModal = true
                        }
                    } label: {
                        settingsIconTitle(icon: "arrow.triangle.2.circlepath", bg: Color(UIColor.systemBlue), title: "Hiệu chỉnh cảm biến 6 mặt")
                    }

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            store.showPairingModal = true
                        }
                    } label: {
                        settingsIconTitle(icon: "antenna.radiowaves.left.and.right", bg: Color(UIColor.systemIndigo), title: "Quét / Ghép đôi Bluetooth")
                    }
                }

                Section(
                    header: Text("CHUNG"),
                    footer: Text("Smart Gimbal Pro for iOS • Thiết kế bởi Đội ngũ Kỹ thuật")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                ) {
                    settingsRowLabel(icon: "globe", bg: Color(UIColor.systemBlue), title: "Ngôn ngữ", trailing: "Tiếng Việt")
                    settingsRowLabel(icon: "questionmark.circle.fill", bg: Color(UIColor.systemTeal), title: "Trợ giúp & Hướng dẫn", trailing: "")
                    settingsRowLabel(icon: "info.circle.fill", bg: Color(UIColor.systemGray), title: "Giới thiệu Smart Gimbal", trailing: "v3.2.0")
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Xong")
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
            }
        }
    }

    private func settingsIconTitle(icon: String, bg: Color, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(bg)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 15.5))
                .foregroundColor(.primary)
        }
    }

    private func settingsRowLabel(icon: String, bg: Color, title: String, trailing: String) -> some View {
        HStack(spacing: 12) {
            settingsIconTitle(icon: icon, bg: bg, title: title)
            Spacer()
            if !trailing.isEmpty {
                Text(trailing)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 34_appearance: Giao Diện & Chế Độ Visual Selector

struct AppearanceSettingsSubView: View {
    @ObservedObject var camera: CameraService

    private let iosBlue = Color(UIColor.systemBlue)
    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("CHỦ ĐỀ HIỂN THỊ")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                HStack(spacing: 12) {
                    appearanceCard(mode: "light", title: "Sáng")
                    appearanceCard(mode: "dark", title: "Tối")
                    appearanceCard(mode: "auto", title: "Tự động")
                }

                Text("CHẾ ĐỘ CAMERA MẶC ĐỊNH")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                HStack(spacing: 12) {
                    cameraModeCard(
                        isPro: false,
                        title: "Cơ bản",
                        desc: "Giao diện một chạm đơn giản, tự động lấy nét và tối ưu cho quay vlog nhanh."
                    )
                    cameraModeCard(
                        isPro: true,
                        title: "Chuyên nghiệp",
                        desc: "Kiểm soát toàn bộ ISO, Shutter, Cân bằng trắng, Focus peaking và Histogram."
                    )
                }
            }
            .padding(16)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Giao diện & Chế độ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func appearanceCard(mode: String, title: String) -> some View {
        let isSelected = camera.uiThemeMode == mode
        let topBarColor: Color = mode == "light" ? Color(white: 0.90) : (mode == "dark" ? Color(white: 0.17) : Color.gray.opacity(0.35))
        let midBoxColor: Color = mode == "auto" ? accentYellow : iosBlue

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            camera.uiThemeMode = mode
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if mode == "light" {
                        Color.white
                    } else if mode == "dark" {
                        Color(red: 0.11, green: 0.11, blue: 0.12)
                    } else {
                        LinearGradient(
                            colors: [.white, .white, Color(red: 0.11, green: 0.11, blue: 0.12), Color(red: 0.11, green: 0.11, blue: 0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }

                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(topBarColor)
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(midBoxColor)
                            .frame(height: 36)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(topBarColor)
                            .frame(height: 14)
                        Spacer(minLength: 0)
                    }
                    .padding(6)
                }
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? iosBlue : Color(UIColor.separator), lineWidth: isSelected ? 2 : 1)
                )

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? iosBlue : .primary)

                ZStack {
                    Circle()
                        .fill(isSelected ? iosBlue : Color.clear)
                        .frame(width: 20, height: 20)
                    Circle()
                        .stroke(isSelected ? iosBlue : Color(UIColor.separator), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func cameraModeCard(isPro: Bool, title: String, desc: String) -> some View {
        let isSelected = camera.isProMode == isPro
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            camera.setCameraInterfaceMode(pro: isPro)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(isSelected ? iosBlue : Color.clear)
                            .frame(width: 18, height: 18)
                        Circle()
                            .stroke(isSelected ? iosBlue : Color(UIColor.separator), lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? iosBlue : Color(UIColor.separator), lineWidth: isSelected ? 2 : 0.8)
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
