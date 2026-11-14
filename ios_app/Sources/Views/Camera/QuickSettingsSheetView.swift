//
//  QuickSettingsSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

// MARK: - =====================================================================
// 12. QUICK SETTINGS SHEET VIEW (SCREEN 04)
// =====================================================================

struct QuickSettingsSheetView: View {
    @ObservedObject var camera: CameraService
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Section 1: Camera Mode Cards
                    sectionHeader("CHẾ ĐỘ MÁY QUAY")
                    HStack(spacing: 12) {
                        modeSelectionCard(
                            icon: "sparkles",
                            badge: "🌟",
                            title: "Cơ Bản",
                            subtitle: "Tối giản • Tự động",
                            isSelected: !camera.isProMode
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                camera.isProMode = false
                            }
                        }

                        modeSelectionCard(
                            icon: "film",
                            badge: "🎬",
                            title: "Chuyên Nghiệp",
                            subtitle: "Đầy đủ thông số • Biểu đồ",
                            isSelected: camera.isProMode
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                camera.isProMode = true
                            }
                        }
                    }

                    // Section 2: UI Theme Cards
                    sectionHeader("CHỦ ĐỀ GIAO DIỆN")
                    HStack(spacing: 10) {
                        themeSelectionCard(badge: "🌙", title: "Tối", tag: "dark")
                        themeSelectionCard(badge: "☀️", title: "Sáng", tag: "light")
                        themeSelectionCard(badge: "⚙️", title: "Tự Động", tag: "auto")
                    }

                    // Section 3: 5 Modular Widget Toggles
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
                            title: "Biểu đồ RGB Histogram",
                            subtitle: "Đo sáng thời gian thực",
                            isOn: $camera.showHistogram
                        )
                        Divider().padding(.leading, 44)

                        // Group 4: Viewfinder Guides & Anti-Flicker
                        VStack(spacing: 10) {
                            widgetToggleRow(
                                index: "4",
                                icon: "grid",
                                title: "Lưới 3x3 Rule of Thirds",
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

                        // Group 5: Auto-Hide 3s & Touch Lock
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

                    // Quick Multi-Cam Status Badge
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

                    // Primary Blue Apply CTA
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
        icon: String,
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

struct ProManualControlsSheetView: View {
    @ObservedObject var camera: CameraService
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @State private var lockNotice: String? = nil

    private let shutterOptions = ["1/60s", "1/120s", "1/250s", "1/500s", "1/1000s"]
    private let isoOptions = [100, 200, 400, 800, 1600]
    private let wbOptions = [3200, 4300, 5600, 6500]
    private let lutOptions = [
        "Standard Rec.709",
        "Apple Log (Flat)",
        "Teal & Orange Cinema",
        "Sunset Golden Hour",
        "Noir B&W"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let notice = lockNotice {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                            Text(notice)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.18))
                        .cornerRadius(10)
                    }

                    // Shutter Speed
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TỐC ĐỘ MÀN TRẬP (SHUTTER): \(camera.shutterSpeed)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(shutterOptions, id: \.self) { opt in
                                    Button(opt) {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        camera.shutterSpeed = opt
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(camera.shutterSpeed == opt ? Color(red: 0.98, green: 0.72, blue: 0.10) : Color.white.opacity(0.1))
                                    .foregroundColor(camera.shutterSpeed == opt ? .black : .white)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // ISO Sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ĐỘ NHẠY SÁNG (ISO): \(camera.iso)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                        HStack(spacing: 8) {
                            ForEach(isoOptions, id: \.self) { isoVal in
                                Button("\(isoVal)") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    camera.iso = isoVal
                                }
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(camera.iso == isoVal ? Color(red: 0.98, green: 0.72, blue: 0.10) : Color.white.opacity(0.1))
                                .foregroundColor(camera.iso == isoVal ? .black : .white)
                                .cornerRadius(8)
                            }
                        }
                    }

                    // Exposure Compensation (EV)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("BÙ SÁNG (EV COMPENSATION)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.65))
                            Spacer()
                            Text(String(format: "%+.1f EV", camera.ev))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                        }
                        Slider(value: $camera.ev, in: -2.0...2.0, step: 0.1)
                            .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
                    }

                    // White Balance (Kelvin)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CÂN BẰNG TRẮNG (WB): \(camera.wbKelvin)K")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                        HStack(spacing: 8) {
                            ForEach(wbOptions, id: \.self) { kelvin in
                                Button("\(kelvin)K") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    camera.wbKelvin = kelvin
                                }
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(camera.wbKelvin == kelvin ? Color(red: 0.98, green: 0.72, blue: 0.10) : Color.white.opacity(0.1))
                                .foregroundColor(camera.wbKelvin == kelvin ? .black : .white)
                                .cornerRadius(8)
                            }
                        }
                    }

                    // 3D LUT Real-time Preview (Gated on store.is3DLutAllowed)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("BẢNG MÀU ĐIỆN ẢNH (3D LUT)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.65))
                            Spacer()
                            if !store.is3DLutAllowed {
                                Label("Đã Khóa (\(store.userTier))", systemImage: "lock.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }

                        VStack(spacing: 8) {
                            ForEach(lutOptions, id: \.self) { lut in
                                let isStandard = (lut == "Standard Rec.709")
                                let isLogLut = (lut == "Apple Log (Flat)")
                                let isAllowed = isStandard || (store.is3DLutAllowed && (!isLogLut || store.isProResAllowed))

                                Button(action: {
                                    if isAllowed {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        camera.activeLut = lut
                                        lockNotice = nil
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                        lockNotice = "Cần mở khóa Module 3D LUT / Apple Log tại Tab Tài Khoản để sử dụng '\(lut)'."
                                    }
                                }) {
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
                                                .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                        }
                                    }
                                    .foregroundColor(isAllowed ? .white : .white.opacity(0.45))
                                    .padding(12)
                                    .background(camera.activeLut == lut ? Color.white.opacity(0.14) : Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0.09, green: 0.09, blue: 0.11).ignoresSafeArea())
            .navigationTitle("Chỉnh Tay Phơi Sáng & LUT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                }
            }
        }
    }
}
