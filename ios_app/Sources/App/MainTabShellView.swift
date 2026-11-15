//
//  MainTabShellView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Figma Node 96:3 — 20_splash, 26_home / 26_home_land, & 5-Tab Bottom Bar (with T-Flow Bot).
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 7. MAIN TAB NAVIGATION SHELL (FIGMA NODE 96:3 — 5 TABS + SPLASH + AUTH GATE)
// =====================================================================

struct MainTabShellView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSplash: Bool = true
    @State private var showCameraStudio: Bool = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 0.96)
                : UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 0.98)
        }
        appearance.shadowColor = UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor.black.withAlphaComponent(0.08)
                : UIColor.white.withAlphaComponent(0.08)
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            Group {
                if !store.isLoggedIn {
                    AuthSignInGateView()
                } else {
                    TabView(selection: $store.activeMainTab) {
                        HomeControlHubView(
                            onOpenCamera: {
                                showCameraStudio = true
                            }
                        )
                        .tabItem {
                            Label("Quay", systemImage: "camera.fill")
                        }
                        .tag(0)

                        MediaGallerySheetView(camera: camera, isEmbeddedTab: true)
                            .tabItem {
                                Label("Thư viện", systemImage: "photo.on.rectangle")
                            }
                            .tag(1)

                        GimbalDeviceHubView()
                            .tabItem {
                                Label("Thiết bị", systemImage: "gyroscope")
                            }
                            .tag(2)

                        TFlowAIChatAssistantView(
                            isEmbeddedTab: true,
                            onOpenCamera: {
                                showCameraStudio = true
                            }
                        )
                        .tabItem {
                            Label("T-Flow Bot", systemImage: "sparkles")
                        }
                        .tag(3)

                        UserProfilePermissionsView()
                            .tabItem {
                                Label("Hồ sơ", systemImage: "person.crop.circle.fill")
                            }
                            .tag(4)
                    }
                    .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
                    .toolbarBackground(
                        colorScheme == .light
                            ? Color(red: 0.97, green: 0.98, blue: 0.99).opacity(0.96)
                            : Color(red: 0.05, green: 0.05, blue: 0.07).opacity(0.98),
                        for: .tabBar
                    )
                    .toolbarBackground(.visible, for: .tabBar)
                    .fullScreenCover(isPresented: $showCameraStudio) {
                        CameraStudioNativeView(onBackToHomeHub: {
                            showCameraStudio = false
                        })
                        .environmentObject(store)
                        .environmentObject(ble)
                        .environmentObject(camera)
                    }
                    .sheet(isPresented: $store.showPairingModal) {
                        BLEPairingScanSheetView()
                    }
                    .sheet(isPresented: $store.showPermissionsModal) {
                        SystemPermissionsSheetView()
                    }
                    .sheet(isPresented: $store.showSignInSheet) {
                        AuthSignInGateView()
                    }
                    .sheet(isPresented: $store.showAiCopilotSheet) {
                        TFlowAIChatAssistantView(
                            isEmbeddedTab: false,
                            onOpenCamera: {
                                store.showAiCopilotSheet = false
                                showCameraStudio = true
                            }
                        )
                    }
                    .sheet(isPresented: $ble.showCalibrationModal) {
                        AutoCalibrationModalView(ble: ble)
                    }
                }
            }

            if showSplash {
                SplashLaunchScreenView()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TFlowOpenCameraStudio"))) { _ in
            if store.isLoggedIn {
                showCameraStudio = true
            }
        }
    }
}

// MARK: - 20_splash_dark: Splash Boot Screen

private struct SplashLaunchScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulseScale: CGFloat = 0.96

    private var accentYellow: Color {
        Color(red: 1.00, green: 0.84, blue: 0.04) // #FFD60A
    }

    var body: some View {
        ZStack {
            (colorScheme == .light ? Color(red: 0.96, green: 0.96, blue: 0.98) : Color.black)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [Color.white, Color(red: 0.92, green: 0.92, blue: 0.95)]
                                    : [Color(red: 0.17, green: 0.17, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.09)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                        )
                        .shadow(color: accentYellow.opacity(0.16), radius: 20, y: 8)

                    ZStack {
                        Circle()
                            .stroke(accentYellow, lineWidth: 3)
                            .frame(width: 44, height: 44)
                        Circle()
                            .fill(accentYellow)
                            .frame(width: 12, height: 12)
                        Rectangle()
                            .fill(accentYellow)
                            .frame(width: 3, height: 10)
                            .offset(y: -25)
                        Rectangle()
                            .fill(accentYellow)
                            .frame(width: 3, height: 10)
                            .offset(y: 25)
                        Rectangle()
                            .fill(accentYellow)
                            .frame(width: 10, height: 3)
                            .offset(x: -25)
                        Rectangle()
                            .fill(accentYellow)
                            .frame(width: 10, height: 3)
                            .offset(x: 25)
                    }
                    .scaleEffect(pulseScale)
                }
                .padding(.bottom, 24)

                Text("Smart Gimbal")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.5)
                    .foregroundColor(.primary)

                Text("Hệ thống chống rung 3 trục điện ảnh")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.top, 6)

                Spacer()

                VStack(spacing: 12) {
                    ProgressView()
                        .tint(accentYellow)
                        .scaleEffect(1.05)

                    Text("KHỞI TẠO HỆ THỐNG FOC 4.0")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.0)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 54)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulseScale = 1.04
                }
            }
        }
    }
}

// MARK: - 26_home & 26_home_land: Trung Tâm Điều Khiển (Tab 0 Home Hub)

private struct HomeControlHubView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme

    var onOpenCamera: () -> Void

    private let accentYellow = Color(red: 1.00, green: 0.84, blue: 0.04) // #FFD60A

    private var surfaceBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }

    private var cardBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height

                ScrollView(showsIndicators: false) {
                    if isLandscape {
                        HStack(alignment: .top, spacing: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                headerTitleBlock(isLandscape: true)
                                deviceHeroCard
                                cameraLaunchButton
                            }
                            .frame(maxWidth: .infinity)

                            VStack(alignment: .leading, spacing: 16) {
                                templatesSection
                                quickTipsSection
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            headerTitleBlock(isLandscape: false)
                            deviceHeroCard
                            cameraLaunchButton
                            templatesSection
                            quickTipsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                    }
                }
                .background(surfaceBackground.ignoresSafeArea())
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func headerTitleBlock(isLandscape: Bool) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SMART GIMBAL")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(accentYellow)

                Text("Trung tâm điều khiển")
                    .font(.system(size: isLandscape ? 24 : 28, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.activeMainTab = 3
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("T-Flow Bot")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(accentYellow))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    private var deviceHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ble.isConnected ? Color(UIColor.systemGreen) : Color(UIColor.systemOrange))
                            .frame(width: 8, height: 8)
                            .shadow(color: (ble.isConnected ? Color.green : Color.orange).opacity(0.65), radius: 4)

                        Text(ble.isConnected ? "ĐÃ KẾT NỐI" : "CHỜ GHÉP ĐÔI BLE")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.4)
                            .foregroundColor(ble.isConnected ? Color(UIColor.systemGreen) : Color(UIColor.systemOrange))
                    }

                    Text(ble.connectedPeripheralName.isEmpty ? "Smart Gimbal S1" : ble.connectedPeripheralName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Cân bằng 3 trục hoàn hảo • Khóa trục Tilt")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    if !ble.isConnected {
                        store.showPairingModal = true
                    } else {
                        store.activeMainTab = 2
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(ble.isConnected ? "\(ble.batteryLevel)%" : "--%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        Image(systemName: ble.isConnected ? "battery.75" : "antenna.radiowaves.left.and.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ble.isConnected ? Color(UIColor.systemGreen) : accentYellow)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.tertiarySystemFill))
                    )
                }
                .buttonStyle(.plain)
            }

            Divider()

            HStack {
                HStack(spacing: 4) {
                    Text("Chế độ:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("Theo dõi \(ble.gimbalMode)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.activeMainTab = 2
                } label: {
                    HStack(spacing: 3) {
                        Text("Cài đặt thiết bị")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(UIColor.systemBlue))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 0.5)
        )
    }

    private var cameraLaunchButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onOpenCamera()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Mở Camera Quay Phim")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentYellow)
            )
            .shadow(color: accentYellow.opacity(0.28), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MẪU QUAY ĐIỆN ẢNH")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    onOpenCamera()
                } label: {
                    Text("Xem tất cả")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            HStack(spacing: 12) {
                templateCard(
                    badge: "360°",
                    title: "Inception Roll",
                    subtitle: "Xoay ống kính vô cực",
                    colors: [Color(red: 0.25, green: 0.16, blue: 0.06), Color(red: 0.80, green: 0.52, blue: 0.10)],
                    symbol: "rotate.3d"
                ) {
                    ble.setGimbalModeWithHaptic("360°")
                    onOpenCamera()
                }

                templateCard(
                    badge: "ZOOM",
                    title: "Dolly Hitchcock",
                    subtitle: "Thu phóng quang học",
                    colors: [Color(red: 0.09, green: 0.20, blue: 0.36), Color(red: 0.18, green: 0.45, blue: 0.85)],
                    symbol: "camera.metering.center.weighted"
                ) {
                    ble.setGimbalModeWithHaptic("Follow")
                    camera.setZoom("2x")
                    ble.showToast("Cinema Template: Dolly Hitchcock Zoom")
                    onOpenCamera()
                }
            }
        }
    }

    private func templateCard(
        badge: String,
        title: String,
        subtitle: String,
        colors: [Color],
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 100)
                        .overlay(
                            Image(systemName: symbol)
                                .font(.system(size: 38, weight: .light))
                                .foregroundColor(.white.opacity(0.32))
                                .offset(x: 26, y: 10)
                        )

                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.60)))
                        .padding(8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HƯỚNG DẪN & MẸO NHANH")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    ble.showCalibrationModal = true
                } label: {
                    quickTipRow(
                        icon: "questionmark.circle",
                        iconBg: Color(UIColor.systemBlue),
                        title: "Cách cân bằng 3 trục vật lý",
                        subtitle: "Bảo vệ động cơ và tăng 2h pin"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 56)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    camera.aiTrackingEnabled = true
                    onOpenCamera()
                } label: {
                    quickTipRow(
                        icon: "face.smiling",
                        iconBg: Color(UIColor.systemOrange),
                        title: "Sử dụng AI ActiveTrack 6.0",
                        subtitle: "Bám nét chủ thể khi di chuyển nhanh"
                    )
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 0.5)
            )
        }
    }

    private func quickTipRow(icon: String, iconBg: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15.5, weight: .medium))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
