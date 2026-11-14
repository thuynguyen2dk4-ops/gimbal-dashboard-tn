//
//  QuickSettingsSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Cài Đặt Nhanh 8 ô (Figma 04_camera_menu_dropdown), Tùy biến HUD (05),
//  và Bảng Phơi Sáng Ruler Chuyên Nghiệp (Figma 09_pro_controls_sheet).
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 12A. QUICK SETTINGS 8-TILE DROPDOWN CARD (FIGMA 04_camera_menu_dropdown)
// =====================================================================

struct QuickSettingsDropdownCard: View {
    @ObservedObject var camera: CameraService
    @ObservedObject var ble: BLEGimbalManager
    @ObservedObject var store: SupabaseModuleStore
    var isLandscape: Bool = false
    var onOpenAspectBar: () -> Void
    var onOpenAdvancedSheet: () -> Void
    var onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }
    private var goldAccent: Color { Color(red: 1.0, green: 0.84, blue: 0.04) }
    private var primaryInk: Color { isLight ? Color.black : Color.white }
    private var secondaryInk: Color { isLight ? Color.black.opacity(0.60) : Color.white.opacity(0.70) }
    private var tileBg: Color { isLight ? Color.white.opacity(0.80) : Color.white.opacity(0.11) }
    private var segBg: Color { isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.12) }
    private var segSelBg: Color { isLight ? Color.white : Color(white: 0.38) }

    private var formattedResolution: String {
        camera.selectedResolution
            .replacingOccurrences(of: "1080 • 60", with: "1080p 60")
            .replacingOccurrences(of: " • ", with: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isLandscape ? 8 : 10) {
            // Header (.qs-h)
            HStack(spacing: 8) {
                Text("Smart Gimbal S1")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(secondaryInk)
                Spacer()
                Text("Cài Đặt Nhanh")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryInk)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenAdvancedSheet()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10.5, weight: .bold))
                        Text("HUD")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundColor(primaryInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(tileBg))
                }
                .buttonStyle(.plain)

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(primaryInk)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(tileBg))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            if isLandscape {
                landscapeTilesLayout
            } else {
                portraitTilesLayout
            }
        }
        .padding(isLandscape ? 12 : 14)
        .background(
            RoundedRectangle(cornerRadius: isLandscape ? 26 : 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: isLandscape ? 26 : 30, style: .continuous)
                        .fill(isLight ? Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.78) : Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.68))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: isLandscape ? 26 : 30, style: .continuous)
                .stroke(isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.14), lineWidth: 0.6)
        )
        .shadow(color: Color.black.opacity(isLight ? 0.16 : 0.34), radius: 24, y: 10)
    }

    // MARK: - Portrait 8-Tile Layout

    private var portraitTilesLayout: some View {
        VStack(spacing: 9) {
            // Tile 1 (Span 2): Aspect Ratio
            aspectTile

            // Tiles 2 & 3: Resolution + Rotate 90
            HStack(spacing: 9) {
                resolutionTile
                rotateTile
            }

            // Tile 4 (Span 2): Gimbal Mode
            gimbalModeTile

            // Tiles 5 & 6: Grid 3x3 + Self Timer
            HStack(spacing: 9) {
                gridTile
                timerTile
            }

            // Tiles 7 & 8: Micro + Interface Mode
            HStack(spacing: 9) {
                micTile
                    .frame(maxWidth: 118)
                interfaceTile
            }
        }
    }

    // MARK: - Landscape Compact 8-Tile Layout

    private var landscapeTilesLayout: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                aspectTile
                    .frame(maxWidth: .infinity)
                resolutionTile
                    .frame(width: 96)
                rotateTile
                    .frame(width: 82)
                gridTile
                    .frame(width: 82)
            }
            HStack(spacing: 8) {
                gimbalModeTile
                    .frame(maxWidth: .infinity)
                timerTile
                    .frame(width: 78)
                micTile
                    .frame(width: 98)
                interfaceTile
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Individual Tiles

    private var aspectTile: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Tỉ Lệ Khung Hình")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(secondaryInk)
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenAspectBar()
                } label: {
                    Text("5 tỉ lệ ›")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isLight ? Color(red: 0.72, green: 0.52, blue: 0.0) : goldAccent)
                }
                .buttonStyle(.plain)
            }

            segmentedControl(
                options: ["16:9", "9:16", "2.39:1"],
                selected: camera.selectedAspectRatio
            ) { ratio in
                camera.setAspectRatio(ratio)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tileBg))
    }

    private var resolutionTile: some View {
        Button {
            if camera.selectedResolution == "1080 • 60" && !store.isProResAllowed {
                camera.selectedResolution = "4K • 30"
            } else {
                camera.cycleResolution()
            }
        } label: {
            tileButtonBody(label: "Độ Phân Giải", value: formattedResolution, isOn: false)
        }
        .buttonStyle(.plain)
    }

    private var rotateTile: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                camera.toggleLandscapeHud()
            }
        } label: {
            tileButtonBody(
                label: "Xoay 90°",
                value: camera.isLandscapeMode ? "Ngang" : "Dọc",
                isOn: camera.isLandscapeMode
            )
        }
        .buttonStyle(.plain)
    }

    private var gimbalModeTile: some View {
        let selectedSegment: String = {
            let up = ble.gimbalMode.uppercased()
            if up == "LOCK" { return "Lock" }
            if up == "FPV" { return "FPV" }
            if up == "FOLLOW" || up == "PF" { return "Follow" }
            return ble.gimbalMode
        }()

        return VStack(alignment: .leading, spacing: 7) {
            Text("Chế Độ Gimbal")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(secondaryInk)

            segmentedControl(
                options: ["Follow", "Lock", "FPV"],
                selected: selectedSegment
            ) { mode in
                ble.setGimbalModeWithHaptic(mode == "Lock" ? "LOCK" : mode)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tileBg))
    }

    private var gridTile: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            camera.gridEnabled.toggle()
        } label: {
            tileButtonBody(
                label: "Lưới 3×3",
                value: camera.gridEnabled ? "Bật" : "Tắt",
                isOn: camera.gridEnabled
            )
        }
        .buttonStyle(.plain)
    }

    private var timerTile: some View {
        Button {
            camera.cycleSelfTimer()
        } label: {
            tileButtonBody(
                label: "Hẹn Giờ",
                value: camera.selfTimerSeconds == 0 ? "Tắt" : "\(camera.selfTimerSeconds)s",
                isOn: camera.selfTimerSeconds > 0
            )
        }
        .buttonStyle(.plain)
    }

    private var micTile: some View {
        Button {
            camera.cycleMicMode()
        } label: {
            tileButtonBody(
                label: "Micro",
                value: camera.micMode,
                isOn: camera.micMode != "Tắt"
            )
        }
        .buttonStyle(.plain)
    }

    private var interfaceTile: some View {
        let current = camera.isProMode ? "Chuyên Nghiệp" : "Cơ Bản"
        return VStack(alignment: .leading, spacing: 7) {
            Text("Giao Diện")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(secondaryInk)

            segmentedControl(
                options: ["Cơ Bản", "Chuyên Nghiệp"],
                selected: current
            ) { label in
                withAnimation(.easeInOut(duration: 0.2)) {
                    camera.setCameraInterfaceMode(pro: label == "Chuyên Nghiệp")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tileBg))
    }

    private func tileButtonBody(label: String, value: String, isOn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isOn ? Color.black.opacity(0.65) : secondaryInk)
                .lineLimit(1)
            Text(value)
                .font(.system(size: isLandscape ? 13 : 14, weight: .bold))
                .foregroundColor(isOn ? Color.black : primaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: isLandscape ? 54 : 62, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isOn ? goldAccent : tileBg)
        )
    }

    private func segmentedControl(
        options: [String],
        selected: String,
        onTap: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { opt in
                let active = (opt == selected)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onTap(opt)
                } label: {
                    Text(opt)
                        .font(.system(size: 11.5, weight: active ? .bold : .medium))
                        .foregroundColor(active ? primaryInk : secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(active ? segSelBg : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(segBg))
    }
}

// MARK: - =====================================================================
// 12B. ADVANCED HUD CUSTOMIZER SHEET VIEW
// =====================================================================

struct QuickSettingsSheetView: View {
    @ObservedObject var camera: CameraService
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let goldAccent = Color(red: 1.0, green: 0.84, blue: 0.04)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader("CHẾ ĐỘ MÁY QUAY")
                    HStack(spacing: 12) {
                        modeSelectionCard(
                            badge: "🌟",
                            title: "Cơ Bản",
                            subtitle: "Tối giản • Tự động",
                            isSelected: !camera.isProMode
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                camera.setCameraInterfaceMode(pro: false)
                            }
                        }

                        modeSelectionCard(
                            badge: "🎬",
                            title: "Chuyên Nghiệp",
                            subtitle: "Đầy đủ thông số • Biểu đồ",
                            isSelected: camera.isProMode
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                camera.setCameraInterfaceMode(pro: true)
                            }
                        }
                    }

                    sectionHeader("CHỦ ĐỀ GIAO DIỆN")
                    HStack(spacing: 10) {
                        themeSelectionCard(badge: "🌙", title: "Tối", tag: "dark")
                        themeSelectionCard(badge: "☀️", title: "Sáng", tag: "light")
                        themeSelectionCard(badge: "⚙️", title: "Tự Động", tag: "auto")
                    }

                    sectionHeader("5 MÔ-ĐUN HIỂN THỊ HUD")
                    VStack(spacing: 0) {
                        widgetToggleRow(
                            index: "1",
                            icon: "camera.aperture",
                            title: "Thông số Phơi sáng",
                            subtitle: "ISO • Shutter • WB",
                            isOn: $camera.showExposureReadout
                        )
                        Divider().padding(.leading, 44)
                        widgetToggleRow(
                            index: "2",
                            icon: "level",
                            title: "Thước thủy Gimbal",
                            subtitle: "Cân bằng chân trời 0.0°",
                            isOn: $camera.showHorizonLevel
                        )
                        Divider().padding(.leading, 44)
                        widgetToggleRow(
                            index: "3",
                            icon: "chart.bar.xaxis",
                            title: "Biểu đồ Histogram",
                            subtitle: "Đo sáng thời gian thực",
                            isOn: $camera.showHistogram
                        )
                        Divider().padding(.leading, 44)

                        VStack(spacing: 10) {
                            widgetToggleRow(
                                index: "4",
                                icon: "grid",
                                title: "Lưới 3×3 Rule of Thirds",
                                subtitle: "Căn khung hình chuẩn",
                                isOn: $camera.gridEnabled
                            )
                            HStack(spacing: 12) {
                                Toggle("Zebra 95%", isOn: $camera.zebraEnabled)
                                    .font(.system(size: 12, weight: .semibold))
                                Toggle("Focus Peaking", isOn: $camera.peakingEnabled)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .tint(appleBlue)
                            .padding(.horizontal, 14)

                            HStack {
                                Text("Chống nhấp nháy")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("", selection: $camera.antiFlicker) {
                                    Text("50Hz").tag("50Hz")
                                    Text("60Hz").tag("60Hz")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 130)
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                        }

                        Divider().padding(.leading, 44)

                        VStack(spacing: 0) {
                            widgetToggleRow(
                                index: "5",
                                icon: "eye.slash",
                                title: "Tự động ẩn sau 3 giây",
                                subtitle: "Làm sạch khung hình khi quay",
                                isOn: $camera.autoHideControls3s
                            )
                            Divider().padding(.leading, 44)
                            widgetToggleRow(
                                index: "•",
                                icon: "lock.shield",
                                title: "Khóa chạm màn hình",
                                subtitle: "Touch Lock chống chạm nhầm",
                                isOn: $camera.touchLockEnabled
                            )
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))

                    HStack {
                        Image(systemName: "video.badge.waveform.fill")
                            .foregroundColor(store.isMultiCamAllowed ? .green : goldAccent)
                        Text("Multi-Cam Director Studio")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(store.isMultiCamAllowed ? "ĐÃ MỞ KHÓA" : "ĐÃ KHÓA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(store.isMultiCamAllowed ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((store.isMultiCamAllowed ? Color.green : Color.red).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(UIColor.secondarySystemGroupedBackground)))

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    } label: {
                        Text("Áp Dụng Cấu Hình Giao Diện")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(appleBlue)
                            .cornerRadius(14)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tùy Biến Bố Cục Giao Diện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(appleBlue)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.8)
            .foregroundColor(.secondary)
    }

    private func modeSelectionCard(
        badge: String,
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(badge)
                        .font(.system(size: 18))
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? appleBlue : .secondary)
                }
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? appleBlue.opacity(colorScheme == .light ? 0.10 : 0.18) : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? appleBlue : Color.clear, lineWidth: 1.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func themeSelectionCard(badge: String, title: String, tag: String) -> some View {
        let isSelected = camera.uiThemeMode == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                camera.uiThemeMode = tag
            }
        } label: {
            VStack(spacing: 6) {
                Text(badge)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? appleBlue.opacity(colorScheme == .light ? 0.10 : 0.18) : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? appleBlue : Color.clear, lineWidth: 1.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func widgetToggleRow(
        index: String,
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appleBlue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(index). \(title)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .tint(appleBlue)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - =====================================================================
// 12C. PRO MANUAL EXPOSURE PANEL & RULERS (FIGMA 09_pro_controls_sheet)
// =====================================================================

struct ProManualControlsSheetView: View {
    @ObservedObject var camera: CameraService
    @ObservedObject var store: SupabaseModuleStore
    var isOverlayPanel: Bool = false
    var onClose: (() -> Void)? = nil
    var onRequirePaywall: (() -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var lockNotice: String? = nil

    private let shutterOptions = ["1/30s", "1/60s", "1/120s", "1/240s", "1/500s", "1/1000s"]
    private let isoOptions = [50, 100, 200, 400, 800]
    private let lutOptions = [
        "Standard Rec.709",
        "Apple Log (Flat)",
        "Teal & Orange Cinema",
        "Sunset Golden Hour",
        "Noir B&W"
    ]

    private var isLight: Bool { colorScheme == .light }
    private var goldAccent: Color { Color(red: 1.0, green: 0.84, blue: 0.04) }
    private var selectedInk: Color { isLight ? Color(red: 0.72, green: 0.52, blue: 0.0) : goldAccent }
    private var primaryInk: Color { isLight ? Color.black : Color.white }
    private var secondaryInk: Color { isLight ? Color.black.opacity(0.62) : Color.white.opacity(0.68) }
    private var subtleBorder: Color { isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.14) }
    private var pillBg: Color { isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.10) }

    private var wbDescriptor: String {
        switch camera.wbKelvin {
        case ..<3600: return "ẤM ĐÈN TUNGSTEN"
        case 3600..<4800: return "TRUNG TÍNH"
        case 4800..<6000: return "ÁNH NẮNG"
        default: return "BÓNG RÂM"
        }
    }

    var body: some View {
        if isOverlayPanel {
            panelContent
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(isLight ? Color(red: 0.96, green: 0.96, blue: 0.98).opacity(0.80) : Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.72))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(subtleBorder, lineWidth: 0.6)
                )
                .shadow(color: Color.black.opacity(isLight ? 0.14 : 0.30), radius: 24, y: 10)
        } else {
            NavigationStack {
                ScrollView {
                    panelContent
                        .padding(18)
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("Điều Khiển Phơi Sáng")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Xong") { dismiss() }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selectedInk)
                    }
                }
            }
        }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: isOverlayPanel ? 10 : 14) {
            // Header: Điều Khiển Phơi Sáng | AUTO / MANUAL
            HStack(spacing: 8) {
                Text("Điều Khiển Phơi Sáng")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryInk)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    camera.isManualExposure.toggle()
                    if !camera.isManualExposure {
                        camera.shutterSpeed = "1/120s"
                        camera.iso = 100
                        camera.wbKelvin = 5600
                        camera.ev = 0.0
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("AUTO")
                            .font(.system(size: 10.5, weight: camera.isManualExposure ? .medium : .bold))
                            .foregroundColor(camera.isManualExposure ? secondaryInk : selectedInk)
                        Text("/")
                            .font(.system(size: 10.5))
                            .foregroundColor(secondaryInk)
                        Text("MANUAL")
                            .font(.system(size: 10.5, weight: camera.isManualExposure ? .bold : .medium))
                            .foregroundColor(camera.isManualExposure ? selectedInk : secondaryInk)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(pillBg))
                    .overlay(Capsule().stroke(subtleBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)

                if isOverlayPanel, let onClose = onClose {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(primaryInk)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(pillBg))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let notice = lockNotice {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(selectedInk)
                    Text(notice)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(primaryInk)
                    Spacer()
                    if let onRequirePaywall = onRequirePaywall {
                        Button("Mở khóa") {
                            onRequirePaywall()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(goldAccent))
                    }
                }
                .padding(9)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.16)))
            }

            // Shutter Speed Ruler (1/60, 1/120, 1/240)
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("TỐC ĐỘ MÀN TRẬP")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(secondaryInk)
                        .tracking(0.3)
                    Spacer()
                    Text(camera.shutterSpeed)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(selectedInk)
                }

                rulerControl(
                    labels: ["1/30", "1/60", "1/120", "1/240", "1/500", "1/1000"],
                    selectedIndex: shutterOptions.firstIndex(of: camera.shutterSpeed) ?? 2
                ) { idx in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    camera.shutterSpeed = shutterOptions[idx]
                    camera.isManualExposure = true
                }
            }
            .padding(.top, 2)

            Divider().overlay(subtleBorder)

            // ISO Sensitivity Ruler (50, 100, 200, 400, 800)
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("ĐỘ NHẠY ISO")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(secondaryInk)
                        .tracking(0.3)
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(camera.iso)")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryInk)
                        if camera.iso == 100 {
                            Text("NATIVE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(secondaryInk)
                        }
                    }
                }

                rulerControl(
                    labels: isoOptions.map { "\($0)" },
                    selectedIndex: isoOptions.firstIndex(of: camera.iso) ?? 1
                ) { idx in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    camera.iso = isoOptions[idx]
                    camera.isManualExposure = true
                }
            }

            Divider().overlay(subtleBorder)

            // White Balance Gradient Track
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("CÂN BẰNG TRẮNG")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(secondaryInk)
                        .tracking(0.3)
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(camera.wbKelvin)K")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryInk)
                        Text(wbDescriptor)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(secondaryInk)
                    }
                }

                whiteBalanceSliderTrack

                HStack(spacing: 6) {
                    ForEach([3200, 4300, 5600, 6500], id: \.self) { kelvin in
                        let isSel = abs(camera.wbKelvin - kelvin) < 150
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            camera.wbKelvin = kelvin
                            camera.isManualExposure = true
                        } label: {
                            Text("\(kelvin)K")
                                .font(.system(size: 10.5, weight: isSel ? .bold : .medium, design: .monospaced))
                                .foregroundColor(isSel ? .black : secondaryInk)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(isSel ? goldAccent : pillBg))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().overlay(subtleBorder)

            // Focus Peaking Toggle (09_pro_controls_sheet_dark.html)
            HStack {
                Text("Cảnh Báo Nét Focus Peaking")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryInk)
                Spacer()
                Toggle("", isOn: $camera.peakingEnabled)
                    .labelsHidden()
                    .tint(goldAccent)
            }

            // Compact LUT & EV strip (visible cleanly inside sheet or expanded scroll)
            if !isOverlayPanel {
                Divider().overlay(subtleBorder)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("BÙ SÁNG (EV)")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(secondaryInk)
                        Spacer()
                        Text(String(format: "%+.1f EV", camera.ev))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedInk)
                    }
                    Slider(value: $camera.ev, in: -2.0...2.0, step: 0.1)
                        .tint(goldAccent)
                }

                Divider().overlay(subtleBorder)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BẢNG MÀU ĐIỆN ẢNH (3D LUT)")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(secondaryInk)
                        Spacer()
                        if !store.is3DLutAllowed {
                            Label("Khóa (\(store.userTier))", systemImage: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }

                    ForEach(lutOptions, id: \.self) { lut in
                        let isStandard = (lut == "Standard Rec.709")
                        let isLogLut = (lut == "Apple Log (Flat)")
                        let isAllowed = isStandard || (store.is3DLutAllowed && (!isLogLut || store.isProResAllowed))

                        Button {
                            if isAllowed {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                camera.activeLut = lut
                                lockNotice = nil
                            } else {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                lockNotice = "Cần mở khóa Module 3D LUT / Apple Log để dùng '\(lut)'."
                            }
                        } label: {
                            HStack {
                                Text(lut)
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                if !isAllowed {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red)
                                } else if camera.activeLut == lut {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(selectedInk)
                                }
                            }
                            .foregroundColor(isAllowed ? primaryInk : secondaryInk.opacity(0.6))
                            .padding(11)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(camera.activeLut == lut ? goldAccent.opacity(0.16) : pillBg)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func rulerControl(
        labels: [String],
        selectedIndex: Int,
        onSelectIndex: @escaping (Int) -> Void
    ) -> some View {
        let count = max(1, labels.count)
        return GeometryReader { geo in
            let w = max(1, geo.size.width)
            let needleX = count > 1
                ? CGFloat(selectedIndex) / CGFloat(count - 1) * (w - 36) + 18
                : w * 0.5

            ZStack(alignment: .topLeading) {
                // Fine & major tick marks
                Canvas { context, size in
                    let tickCount = 32
                    for i in 0...tickCount {
                        let x = CGFloat(i) / CGFloat(tickCount) * (size.width - 36) + 18
                        let isMajor = (i % 6 == 0)
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: 2))
                        p.addLine(to: CGPoint(x: x, y: isMajor ? 13 : 8))
                        context.stroke(
                            p,
                            with: .color(primaryInk.opacity(isMajor ? 0.65 : 0.25)),
                            lineWidth: isMajor ? 1.2 : 0.8
                        )
                    }
                }
                .frame(height: 16)

                // Gold active needle
                RoundedRectangle(cornerRadius: 1)
                    .fill(goldAccent)
                    .frame(width: 2.5, height: 18)
                    .position(x: needleX, y: 9)

                // Interactive preset labels
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { idx, txt in
                        let isSel = (idx == selectedIndex)
                        Button {
                            onSelectIndex(idx)
                        } label: {
                            Text(txt)
                                .font(.system(size: 10, weight: isSel ? .bold : .medium, design: .monospaced))
                                .foregroundColor(isSel ? selectedInk : secondaryInk)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .offset(y: 18)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        let ratio = max(0, min(1, (value.location.x - 18) / max(1, w - 36)))
                        let idx = Int(round(ratio * CGFloat(count - 1)))
                        if idx != selectedIndex {
                            onSelectIndex(idx)
                        }
                    }
            )
        }
        .frame(height: 32)
    }

    private var whiteBalanceSliderTrack: some View {
        let minK: Double = 2800
        let maxK: Double = 7500
        let progress = CGFloat(max(0, min(1, (Double(camera.wbKelvin) - minK) / (maxK - minK))))

        return GeometryReader { geo in
            let w = max(24, geo.size.width)
            let knobX = 11 + progress * (w - 22)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.61, blue: 0.79),
                                Color(red: 0.79, green: 0.83, blue: 0.87),
                                Color(red: 0.91, green: 0.85, blue: 0.73),
                                Color(red: 0.85, green: 0.65, blue: 0.42)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)

                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.28), radius: 4, y: 1)
                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                    .position(x: knobX, y: 11)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = max(0, min(1, (value.location.x - 11) / max(1, w - 22)))
                        let rawK = minK + Double(ratio) * (maxK - minK)
                        camera.wbKelvin = Int((rawK / 100.0).rounded() * 100.0)
                        camera.isManualExposure = true
                    }
            )
        }
        .frame(height: 22)
    }
}
