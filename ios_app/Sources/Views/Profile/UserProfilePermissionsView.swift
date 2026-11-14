//
//  UserProfilePermissionsView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Figma Node 96:3 — 21_onboarding, 22_signin, 23_permissions,
//  24_pairing_scan, 25_pairing_success, 35_profile + Hồ sơ cá nhân & Cookie Session.
//

import SwiftUI
import AVFoundation
import CoreBluetooth
import Photos
import UIKit

// MARK: - 1. USER PROFILE TAB (35_profile_dark / light)

struct UserProfilePermissionsView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedModule: ModuleDetailItem? = nil
    @State private var showPaywallSheet: Bool = false
    @State private var showPersonalInfoSheet: Bool = false
    @State private var showPairingSheet: Bool = false
    @State private var showPermissionsSheet: Bool = false
    @State private var showModuleMatrix: Bool = false

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
    }

    private var activeModuleCount: Int {
        store.modules.filter { $0 }.count
    }

    private let moduleCatalog: [(title: String, icon: String, desc: String)] = [
        ("AI Vision Tracking", "viewfinder", "Khóa nét khuôn mặt 60fps"),
        ("4K 60fps Apple Log", "film.fill", "Quay màu phẳng Cinema 10-bit"),
        ("Motionlapse Waypoint", "timelapse", "Lập trình điểm trượt tự động"),
        ("Multi-Cam Studio", "rectangle.grid.2x2.fill", "Đồng bộ 4 góc máy Wi-Fi"),
        ("Cinema 3D LUTs", "camera.filters", "Áp màu điện ảnh thời gian thực"),
        ("FOC Micro-Tuning", "slider.horizontal.3", "Chỉnh mô-men động cơ 3 trục"),
        ("Raw Sensor Telemetry", "waveform.path.ecg", "Thông số góc IMU trực tiếp")
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerRow
                    if !store.isLoggedIn {
                        guestSignInBanner
                    }
                    userHeaderCard
                    cloudStorageCard
                    accountSectionHeader
                    accountManagementGroup
                }
                .padding(.bottom, 28)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPersonalInfoSheet) {
                PersonalInfoEditSheetView()
            }
            .sheet(isPresented: $showPaywallSheet) {
                SubscriptionPaywallSheetView(store: store)
            }
            .sheet(isPresented: $showPairingSheet) {
                BLEPairingScanSheetView()
            }
            .sheet(isPresented: $showPermissionsSheet) {
                SystemPermissionsSheetView()
            }
            .sheet(item: $selectedModule) { item in
                ModuleDetailInspectorSheet(detail: item, store: store)
                    .presentationDetents([.medium])
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center) {
            Text("Hồ sơ")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button {
                store.syncWithCloud()
            } label: {
                HStack(spacing: 6) {
                    if store.isSyncing {
                        ProgressView()
                            .scaleEffect(0.75)
                    } else {
                        Circle()
                            .fill(store.isOnline ? Color(UIColor.systemGreen) : Color.secondary)
                            .frame(width: 7, height: 7)
                    }
                    Text(store.isSyncing ? "Đang đồng bộ" : store.lastSyncTime)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemBlue))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var guestSignInBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accentGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Đang dùng chế độ Khách")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Đăng nhập để lưu Cookie Session, bảo hành & dự án Cloud")
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.showSignInSheet = true
            } label: {
                Text("Đăng nhập / Đăng ký tài khoản")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accentGold)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentGold.opacity(0.45), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var userHeaderCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPersonalInfoSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.84, blue: 0.04),
                                    Color(red: 1.00, green: 0.62, blue: 0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color(red: 1.00, green: 0.62, blue: 0.04).opacity(0.32), radius: 8, y: 4)

                    Text(store.currentUser.avatarInitials)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(store.currentUser.fullName)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(store.isLoggedIn ? "PRO" : "KHÁCH")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(accentGold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(
                                Capsule()
                                    .fill(accentGold.opacity(0.18))
                                    .overlay(
                                        Capsule().stroke(accentGold.opacity(0.38), lineWidth: 0.6)
                                    )
                            )
                    }

                    Text(store.currentUser.email)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if store.isLoggedIn {
                        Text("Serial: \(store.currentUser.gimbalSerial) • \(store.userTier)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var cloudStorageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Lưu trữ Đám mây Gimbal Pro")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("142 GB / 200 GB")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            GeometryReader { geo in
                let totalWidth = max(1, geo.size.width)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 8)

                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(UIColor.systemBlue))
                            .frame(width: totalWidth * 0.50)
                        Rectangle()
                            .fill(Color(UIColor.systemPurple))
                            .frame(width: totalWidth * 0.15)
                        Rectangle()
                            .fill(accentGold)
                            .frame(width: totalWidth * 0.06)
                    }
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            .frame(height: 8)

            HStack(spacing: 14) {
                storageLegendDot(color: Color(UIColor.systemBlue), label: "Video 4K (100GB)")
                storageLegendDot(color: Color(UIColor.systemPurple), label: "Dự án (30GB)")
                storageLegendDot(color: accentGold, label: "LUTs (12GB)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    private func storageLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    private var accountSectionHeader: some View {
        Text("QUẢN LÝ TÀI KHOẢN")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.secondary)
            .padding(.horizontal, 32)
            .padding(.top, 4)
            .padding(.bottom, -6)
    }

    private var accountManagementGroup: some View {
        VStack(spacing: 0) {
            profileActionRow(
                icon: "person.text.rectangle.fill",
                iconBg: Color(UIColor.systemBlue),
                iconFg: .white,
                title: "Thông tin cá nhân",
                subtitle: "Hồ sơ, SĐT, Serial & Cookie phiên"
            ) {
                showPersonalInfoSheet = true
            }

            Divider().padding(.leading, 56)

            profileActionRow(
                icon: "crown.fill",
                iconBg: accentGold,
                iconFg: .black,
                title: "Gói thành viên Pro",
                subtitle: "\(store.userTier) • Gia hạn 12/2027"
            ) {
                showPaywallSheet = true
            }

            Divider().padding(.leading, 56)

            profileActionRow(
                icon: "gyroscope",
                iconBg: Color(UIColor.systemBlue),
                iconFg: .white,
                title: "Thiết bị của tôi",
                subtitle: "2 Gimbal đã ghép đôi • BLE \(ble.batteryLevel)%"
            ) {
                showPairingSheet = true
            }

            Divider().padding(.leading, 56)

            profileActionRow(
                icon: "lock.shield.fill",
                iconBg: Color(UIColor.systemIndigo),
                iconFg: .white,
                title: "Quyền truy cập hệ thống",
                subtitle: "Camera, Micro, Bluetooth, Ảnh"
            ) {
                showPermissionsSheet = true
            }

            Divider().padding(.leading, 56)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showModuleMatrix.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    rowIconBadge(icon: "square.grid.2x2.fill", bg: Color(UIColor.systemOrange), fg: .white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ma trận 7 Mô-đun Tính Năng Cloud")
                            .font(.system(size: 16.5))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("\(activeModuleCount)/7 đang bật • Camera \(camera.isProMode ? "Pro" : "Cơ bản")")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: showModuleMatrix ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if showModuleMatrix {
                VStack(spacing: 0) {
                    HStack {
                        Text("Chế độ Camera mặc định")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Chế độ Camera", selection: Binding(
                            get: { camera.isProMode },
                            set: { camera.setCameraInterfaceMode(pro: $0) }
                        )) {
                            Text("Cơ bản").tag(false)
                            Text("Pro").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.45))

                    ForEach(0..<moduleCatalog.count, id: \.self) { index in
                        let meta = moduleCatalog[index]
                        let isEnabled = store.modules.indices.contains(index) ? store.modules[index] : false

                        Divider().padding(.leading, 56)

                        Button {
                            selectedModule = ModuleDetailItem(
                                index: index,
                                title: meta.title,
                                icon: meta.icon,
                                desc: meta.desc
                            )
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: meta.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isEnabled ? accentGold : .secondary)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(meta.title)
                                        .font(.system(size: 14.5, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(meta.desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { store.modules.indices.contains(index) ? store.modules[index] : false },
                                    set: { _ in store.toggleModule(at: index) }
                                ))
                                .labelsHidden()
                                .tint(Color(UIColor.systemBlue))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().padding(.leading, 56)

            HStack(spacing: 12) {
                rowIconBadge(icon: "icloud.and.arrow.up.fill", bg: Color(UIColor.systemGreen), fg: .white)

                Text("Tự động sao lưu dự án")
                    .font(.system(size: 16.5))
                    .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: $store.autoBackupProjects)
                    .labelsHidden()
                    .tint(Color(UIColor.systemGreen))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.logout()
            } label: {
                Text(store.isLoggedIn ? "Đăng xuất tài khoản" : "Thoát chế độ Khách")
                    .font(.system(size: 16.5, weight: .medium))
                    .foregroundColor(Color(UIColor.systemRed))
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 16)
    }

    private func profileActionRow(
        icon: String,
        iconBg: Color,
        iconFg: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                rowIconBadge(icon: icon, bg: iconBg, fg: iconFg)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16.5))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func rowIconBadge(icon: String, bg: Color, fg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(bg)
                .frame(width: 28, height: 28)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(fg)
        }
    }
}

// MARK: - 2. AUTH SIGN-IN & ONBOARDING GATE (21_onboarding + 22_signin)

struct AuthSignInGateView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showOnboarding: Bool = false
    @State private var onboardingPage: Int = 0
    @State private var selectedTab: Int = 0 // 0 = Đăng nhập, 1 = Đăng ký

    @State private var loginIdentifier: String = ""
    @State private var loginPassword: String = ""
    @State private var showLoginPassword: Bool = false

    @State private var regFullName: String = ""
    @State private var regEmail: String = ""
    @State private var regPhone: String = ""
    @State private var regPassword: String = ""
    @State private var regSerial: String = "TF-G31-PRO"
    @State private var showRegPassword: Bool = false

    @State private var authError: String = ""

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
    }

    private let onboardingSlides: [(title: String, subtitle: String, icon: String)] = [
        (
            "Chống Rung Điện Ảnh 3 Trục",
            "Thuật toán FOC 4.0 triệt tiêu rung chấn tức thì, mang lại những thước phim mượt mà chuẩn Hollywood ngay trên iPhone của bạn.",
            "gyroscope"
        ),
        (
            "AI DeepTrack 3.0 Thông Minh",
            "Nhận diện khuôn mặt, thú cưng hoặc chạm chọn khóa bất kỳ vật thể nào ở tốc độ 60fps.",
            "viewfinder"
        ),
        (
            "4K Apple Log & 3D LUTs",
            "Quay màu phẳng điện ảnh, đồng bộ tài khoản qua Cookie bảo mật và lưu trữ đám mây tự động.",
            "camera.filters"
        )
    ]

    var body: some View {
        NavigationStack {
            Group {
                if showOnboarding {
                    onboardingStepView
                } else {
                    signInFormView
                }
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .toolbar {
                if store.isGuestMode || store.isLoggedIn {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Đóng") {
                            store.showSignInSheet = false
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                showOnboarding = !store.hasCompletedOnboarding && !store.isGuestMode && !store.isLoggedIn
            }
        }
    }

    private var onboardingStepView: some View {
        VStack(spacing: 0) {
            TabView(selection: $onboardingPage) {
                ForEach(0..<onboardingSlides.count, id: \.self) { idx in
                    let slide = onboardingSlides[idx]
                    VStack(spacing: 22) {
                        Spacer()

                        if idx == 0 {
                            OnboardingGimbalVectorIllustration(accentGold: accentGold)
                                .frame(height: 230)
                        } else {
                            ZStack {
                                Circle()
                                    .stroke(Color(UIColor.separator), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                    .frame(width: 170, height: 170)
                                Circle()
                                    .fill(accentGold.opacity(0.16))
                                    .frame(width: 96, height: 96)
                                Image(systemName: slide.icon)
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(accentGold)
                            }
                            .frame(height: 230)
                        }

                        VStack(spacing: 10) {
                            Text(slide.title)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            Text(slide.subtitle)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<onboardingSlides.count, id: \.self) { idx in
                    Capsule()
                        .fill(onboardingPage == idx ? accentGold : Color(UIColor.tertiaryLabel))
                        .frame(width: onboardingPage == idx ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: onboardingPage)
                }
            }
            .padding(.bottom, 20)

            VStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if onboardingPage < onboardingSlides.count - 1 {
                        withAnimation {
                            onboardingPage += 1
                        }
                    } else {
                        store.hasCompletedOnboarding = true
                        withAnimation {
                            showOnboarding = false
                        }
                    }
                } label: {
                    Text(onboardingPage < onboardingSlides.count - 1 ? "Tiếp tục" : "Bắt đầu ngay")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white : Color.black)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    store.hasCompletedOnboarding = true
                    withAnimation {
                        showOnboarding = false
                    }
                } label: {
                    Text("Bỏ qua")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(UIColor.secondarySystemFill))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
    }

    private var signInFormView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accentGold)
                            .frame(width: 60, height: 60)
                            .shadow(color: accentGold.opacity(0.28), radius: 10, y: 5)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.black)
                    }

                    Text(selectedTab == 0 ? "Đăng nhập tài khoản" : "Đăng ký tài khoản T-Flow")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Đồng bộ cấu hình gimbal & preset màu của bạn")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 14)

                Picker("Chế độ tài khoản", selection: $selectedTab) {
                    Text("Đăng nhập").tag(0)
                    Text("Đăng ký tài khoản").tag(1)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTab) { _ in
                    authError = ""
                }

                if !authError.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(UIColor.systemRed))
                        Text(authError)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(UIColor.systemRed))
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(UIColor.systemRed).opacity(0.12))
                    )
                }

                if selectedTab == 0 {
                    loginTabContent
                } else {
                    registerTabContent
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.hasCompletedOnboarding = true
                    store.continueAsGuest()
                    store.showSignInSheet = false
                    dismiss()
                } label: {
                    Text("Bỏ qua, dùng thử (Khách)")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(UIColor.secondarySystemFill))
                        )
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(store.isLoggedIn ? Color(UIColor.systemGreen) : .secondary)
                    Text("Cookie Session: tflow_session_token (HTTPCookieStorage.shared)")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                Button {
                    withAnimation {
                        onboardingPage = 0
                        showOnboarding = true
                    }
                } label: {
                    Text("Xem giới thiệu Chống Rung 3 Trục")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                }
                .padding(.top, 2)

                Text("Bằng việc tiếp tục, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    private var loginTabContent: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 22)
                    TextField("Email hoặc Số điện thoại", text: $loginIdentifier)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 22)
                    if showLoginPassword {
                        TextField("Mật khẩu", text: $loginPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Mật khẩu", text: $loginPassword)
                    }
                    Button {
                        showLoginPassword.toggle()
                    } label: {
                        Image(systemName: showLoginPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }

            HStack {
                Button {
                    loginIdentifier = "thuynguyen2dk4@gmail.com"
                    loginPassword = "admin"
                    authError = ""
                } label: {
                    Text("Điền nhanh Admin (thuynguyen2dk4@gmail.com)")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                }
                Spacer()
            }

            Button {
                let res = store.login(identifier: loginIdentifier, password: loginPassword)
                if res.ok {
                    authError = ""
                    store.hasCompletedOnboarding = true
                    store.showSignInSheet = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                } else {
                    authError = res.message
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            } label: {
                Text("Đăng nhập")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accentGold)
                    )
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Rectangle().fill(Color(UIColor.separator)).frame(height: 0.5)
                Text("HOẶC")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Rectangle().fill(Color(UIColor.separator)).frame(height: 0.5)
            }
            .padding(.vertical, 4)

            Button {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                store.hasCompletedOnboarding = true
                store.signInWithApple()
                store.showSignInSheet = false
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Đăng nhập bằng Apple")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white : Color.black)
                )
            }
            .buttonStyle(.plain)

            Button {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                store.hasCompletedOnboarding = true
                store.signInWithGoogle()
                store.showSignInSheet = false
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Text("G")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(
                                LinearGradient(
                                    colors: [Color(UIColor.systemBlue), Color(UIColor.systemGreen)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                    Text("Đăng nhập bằng Google")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(UIColor.separator), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var registerTabContent: some View {
        VStack(spacing: 10) {
            authFieldRow(icon: "person.fill", placeholder: "Họ và tên", text: $regFullName)
            authFieldRow(icon: "envelope.fill", placeholder: "Email", text: $regEmail, keyboard: .emailAddress, autocap: .never)
            authFieldRow(icon: "phone.fill", placeholder: "Số điện thoại", text: $regPhone, keyboard: .phonePad)

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 22)
                if showRegPassword {
                    TextField("Mật khẩu (tối thiểu 4 ký tự)", text: $regPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("Mật khẩu (tối thiểu 4 ký tự)", text: $regPassword)
                }
                Button {
                    showRegPassword.toggle()
                } label: {
                    Image(systemName: showRegPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )

            authFieldRow(icon: "barcode.viewfinder", placeholder: "Mã Serial Gimbal (VD: TF-G31-PRO)", text: $regSerial, autocap: .characters)

            Button {
                let res = store.register(
                    fullName: regFullName,
                    email: regEmail,
                    phone: regPhone,
                    password: regPassword,
                    gimbalSerial: regSerial
                )
                if res.ok {
                    authError = ""
                    store.hasCompletedOnboarding = true
                    store.showSignInSheet = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                } else {
                    authError = res.message
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            } label: {
                Text("Tạo tài khoản & Tạo Session Cookie")
                    .font(.system(size: 16.5, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accentGold)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private func authFieldRow(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        autocap: TextInputAutocapitalization = .words
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 22)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap)
                .autocorrectionDisabled()
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - 3. PERSONAL INFO & COOKIE SESSION EDITOR

struct PersonalInfoEditSheetView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var gimbalSerial: String = ""
    @State private var newPassword: String = ""
    @State private var statusBanner: String? = nil

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
    }

    private var formattedSessionDate: String {
        guard let date = store.sessionCreatedAt else { return "Chưa kích hoạt" }
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return df.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.00, green: 0.84, blue: 0.04),
                                            Color(red: 1.00, green: 0.62, blue: 0.04)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 54, height: 54)
                            Text(store.currentUser.avatarInitials)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(fullName.isEmpty ? store.currentUser.fullName : fullName)
                                .font(.system(size: 17, weight: .bold))
                            Text("\(store.userTier) • Thành viên từ \(store.currentUser.memberSince)")
                                .font(.system(size: 12.5))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let banner = statusBanner {
                    Section {
                        Text(banner)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                }

                Section("Thông tin cá nhân & Bảo hành") {
                    LabeledContent("Họ và tên") {
                        TextField("Nhập họ tên", text: $fullName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Email") {
                        TextField("email@domain.com", text: $email)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    LabeledContent("Số điện thoại") {
                        TextField("0909...", text: $phone)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.phonePad)
                    }
                    LabeledContent("Địa chỉ") {
                        TextField("Địa chỉ giao nhận / BH", text: $address)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Serial Gimbal") {
                        TextField("TF-G31-PRO", text: $gimbalSerial)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                    LabeledContent("Đổi mật khẩu") {
                        SecureField("Để trống nếu giữ nguyên", text: $newPassword)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Phiên Đăng Nhập & Cookie Bảo Mật") {
                    HStack {
                        Text("Session ID")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(store.sessionId.isEmpty ? "--" : store.sessionId)
                            .font(.system(size: 12.5, design: .monospaced))
                            .lineLimit(1)
                    }

                    HStack {
                        Text("Cookie Token")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(store.sessionCookieToken.isEmpty ? "Chưa cấp (Khách)" : store.sessionCookieToken)
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    HStack {
                        Text("Thời điểm tạo phiên")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedSessionDate)
                            .font(.system(size: 13))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("HTTPCookieStorage.shared")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(store.activeCookieSummary)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        store.refreshSessionCookie()
                        statusBanner = "✓ Đã làm mới Cookie Session (tflow_session_token)"
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("Làm mới Cookie Session")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                    }
                }

                Section {
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        store.updatePersonalProfile(
                            fullName: fullName,
                            email: email,
                            phone: phone,
                            address: address,
                            gimbalSerial: gimbalSerial,
                            newPassword: newPassword
                        )
                        newPassword = ""
                        statusBanner = "✓ Đã lưu thông tin cá nhân & đồng bộ Cloud"
                    } label: {
                        Text("Lưu thông tin cá nhân")
                            .font(.system(size: 16.5, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(accentGold)
                            )
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Thông tin cá nhân")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                fullName = store.currentUser.fullName
                email = store.currentUser.email
                phone = store.currentUser.phone
                address = store.currentUser.address
                gimbalSerial = store.currentUser.gimbalSerial
            }
        }
    }
}

// MARK: - 4. BLE PAIRING SCAN & SUCCESS (24_pairing_scan + 25_pairing_success)

struct BLEPairingScanSheetView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var pulseRadar: Bool = false
    @State private var connectingDeviceName: String? = nil
    @State private var isPairedSuccess: Bool = false
    @State private var pairedDeviceName: String = "Smart Gimbal S1"

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if isPairedSuccess {
                    pairedSuccessContent
                } else {
                    scanningContent
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(isPairedSuccess ? "Kết nối thành công" : "Ghép đôi Bluetooth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulseRadar = true
                }
            }
        }
    }

    private var scanningContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.systemBlue).opacity(0.25), lineWidth: 1.5)
                        .frame(width: 130, height: 130)
                        .scaleEffect(pulseRadar ? 1.06 : 0.95)
                    Circle()
                        .stroke(Color(UIColor.systemBlue).opacity(0.5), lineWidth: 1.5)
                        .frame(width: 90, height: 90)
                        .scaleEffect(pulseRadar ? 1.04 : 0.96)
                    Circle()
                        .fill(Color(UIColor.systemBlue).opacity(0.15))
                        .overlay(
                            Circle().stroke(Color(UIColor.systemBlue), lineWidth: 1.5)
                        )
                        .frame(width: 50, height: 50)
                    Circle()
                        .fill(Color(UIColor.systemBlue))
                        .frame(width: 14, height: 14)
                        .shadow(color: Color(UIColor.systemBlue), radius: 8)
                }
                .frame(width: 140, height: 140)
                .padding(.top, 12)

                Text("Đang tìm kiếm Gimbal...")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                Text("Giữ gimbal gần iPhone và đảm bảo Bluetooth đã bật")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text("THIẾT BỊ TÌM THẤY")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                VStack(spacing: 0) {
                    discoveredDeviceRow(
                        name: "Smart Gimbal S1",
                        badge: "Gần nhất",
                        subtitle: "Tín hiệu cực mạnh (-42 dBm) • Sẵn sàng ghép đôi",
                        icon: "antenna.radiowaves.left.and.right",
                        iconBg: Color(UIColor.systemGreen),
                        buttonTitle: "Kết nối",
                        isPrimary: true
                    )

                    Divider().padding(.leading, 56)

                    discoveredDeviceRow(
                        name: "Smart Gimbal S2",
                        badge: nil,
                        subtitle: "Tín hiệu trung bình (-78 dBm)",
                        icon: "gyroscope",
                        iconBg: Color(UIColor.systemGray),
                        buttonTitle: "Ghép",
                        isPrimary: false
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 24)
    }

    private func discoveredDeviceRow(
        name: String,
        badge: String?,
        subtitle: String,
        icon: String,
        iconBg: Color,
        buttonTitle: String,
        isPrimary: Bool
    ) -> some View {
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
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 16.5, weight: .semibold))
                        .foregroundColor(.primary)
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGreen))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.systemGreen).opacity(0.16))
                                    .overlay(
                                        Capsule().stroke(Color(UIColor.systemGreen).opacity(0.32), lineWidth: 0.5)
                                    )
                            )
                    }
                }
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                connectToDevice(name)
            } label: {
                Group {
                    if connectingDeviceName == name {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(buttonTitle)
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                .foregroundColor(isPrimary ? .black : .primary)
                .frame(width: 80, height: 32)
                .background(
                    Capsule()
                        .fill(isPrimary ? accentGold : Color(UIColor.secondarySystemFill))
                )
            }
            .buttonStyle(.plain)
            .disabled(connectingDeviceName != nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var pairedSuccessContent: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                OnboardingGimbalVectorIllustration(accentGold: accentGold)
                    .frame(width: 160, height: 180)

                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemGreen))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(Color(UIColor.secondarySystemGroupedBackground), lineWidth: 2)
                        )
                        .shadow(color: Color(UIColor.systemGreen).opacity(0.4), radius: 8, y: 3)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: -6, y: -6)
            }
            .padding(.top, 16)

            VStack(spacing: 4) {
                Text("Đã kết nối thành công!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                Text("\(pairedDeviceName) đã sẵn sàng cho mọi cú máy")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                successStatusRow(
                    icon: "battery.100",
                    iconBg: Color(UIColor.systemGreen),
                    title: "Mức pin thiết bị",
                    trailing: "\(ble.batteryLevel)% (Khoảng 8.5 giờ)"
                )
                Divider().padding(.leading, 56)
                successStatusRow(
                    icon: "info.circle.fill",
                    iconBg: Color(UIColor.systemBlue),
                    title: "Phiên bản Firmware",
                    trailing: "\(ble.firmwareVersion) (Mới nhất)"
                )
                Divider().padding(.leading, 56)
                successStatusRow(
                    icon: "gyroscope",
                    iconBg: Color(UIColor.systemOrange),
                    title: "Chế độ khởi động",
                    trailing: "Theo dõi \(ble.gimbalMode)"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.activeMainTab = 0
                    dismiss()
                } label: {
                    Text("Bắt đầu quay phim")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(accentGold)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.activeMainTab = 2
                    dismiss()
                } label: {
                    Text("Vào trang thiết bị")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(UIColor.secondarySystemFill))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func successStatusRow(icon: String, iconBg: Color, title: String, trailing: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 16.5))
                .foregroundColor(.primary)
            Spacer()
            Text(trailing)
                .font(.system(size: 14.5))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func connectToDevice(_ name: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        connectingDeviceName = name
        pairedDeviceName = name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            ble.isConnected = true
            store.deviceName = name
            connectingDeviceName = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.25)) {
                isPairedSuccess = true
            }
        }
    }
}

// MARK: - 5. SYSTEM PERMISSIONS SHEET (23_permissions)

struct SystemPermissionsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var cameraGranted: Bool = false
    @State private var micGranted: Bool = false
    @State private var bleStatusText: String = "Kiểm tra"
    @State private var bleGranted: Bool = false
    @State private var photosGranted: Bool = false
    @State private var cameraDenied: Bool = false
    @State private var micDenied: Bool = false
    @State private var photosDenied: Bool = false
    @State private var isRequesting: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quyền truy cập")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Để Smart Gimbal hoạt động ổn định và quay phim mượt mà nhất")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    VStack(spacing: 0) {
                        permissionRow(
                            icon: "camera.fill",
                            bg: Color(UIColor.systemBlue),
                            title: "Camera",
                            subtitle: "Quay video 4K HDR và bám nét chủ thể theo thời gian thực",
                            granted: cameraGranted,
                            denied: cameraDenied,
                            customBadge: nil
                        )
                        Divider().padding(.leading, 56)
                        permissionRow(
                            icon: "mic.fill",
                            bg: Color(UIColor.systemOrange),
                            title: "Microphone",
                            subtitle: "Thu âm thanh vòm độ nét cao và lọc tiếng ồn gió",
                            granted: micGranted,
                            denied: micDenied,
                            customBadge: nil
                        )
                        Divider().padding(.leading, 56)
                        permissionRow(
                            icon: "antenna.radiowaves.left.and.right",
                            bg: Color(UIColor.systemIndigo),
                            title: "Bluetooth",
                            subtitle: "Kết nối và đồng bộ phím điều khiển với Smart Gimbal",
                            granted: bleGranted,
                            denied: false,
                            customBadge: bleStatusText
                        )
                        Divider().padding(.leading, 56)
                        permissionRow(
                            icon: "photo.on.rectangle.angled",
                            bg: Color(UIColor.systemGreen),
                            title: "Thư viện ảnh",
                            subtitle: "Lưu trữ thước phim điện ảnh và chỉnh sửa nhanh clip",
                            granted: photosGranted,
                            denied: photosDenied,
                            customBadge: nil
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        Button {
                            requestAllPermissions()
                        } label: {
                            HStack(spacing: 8) {
                                if isRequesting {
                                    ProgressView()
                                        .tint(colorScheme == .dark ? .black : .white)
                                }
                                Text("Cho phép truy cập tất cả")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white : Color.black)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isRequesting)

                        if cameraDenied || micDenied || photosDenied {
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text("Mở Cài đặt iOS để bật quyền bị từ chối")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Để sau")
                                .font(.system(size: 15.5, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(UIColor.secondarySystemFill))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                refreshStatuses()
            }
        }
    }

    private func permissionRow(
        icon: String,
        bg: Color,
        title: String,
        subtitle: String,
        granted: Bool,
        denied: Bool,
        customBadge: String?
    ) -> some View {
        let badgeLabel: String = customBadge ?? (granted ? "Đã cấp" : (denied ? "Từ chối" : "Chưa cấp"))
        let badgeColor: Color = granted
            ? Color(UIColor.systemGreen)
            : (denied ? Color(UIColor.systemRed) : Color(UIColor.systemOrange))

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(bg)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16.5, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text(badgeLabel)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(badgeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(badgeColor.opacity(0.16))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func refreshStatuses() {
        let camStatus = AVCaptureDevice.authorizationStatus(for: .video)
        cameraGranted = (camStatus == .authorized)
        cameraDenied = (camStatus == .denied || camStatus == .restricted)

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        micGranted = (micStatus == .authorized)
        micDenied = (micStatus == .denied || micStatus == .restricted)

        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photosGranted = (photoStatus == .authorized || photoStatus == .limited)
        photosDenied = (photoStatus == .denied || photoStatus == .restricted)

        let bleAuth = CBManager.authorization
        switch bleAuth {
        case .allowedAlways:
            bleGranted = true
            bleStatusText = "Đã cấp"
        case .denied, .restricted:
            bleGranted = false
            bleStatusText = "Từ chối"
        default:
            bleGranted = false
            bleStatusText = "Chưa cấp"
        }
    }

    private func requestAllPermissions() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isRequesting = true

        AVCaptureDevice.requestAccess(for: .video) { _ in
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                    DispatchQueue.main.async {
                        refreshStatuses()
                        isRequesting = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }
        }
    }
}

// MARK: - 6. SHARED VECTOR GIMBAL ILLUSTRATION (21_onboarding + 25_pairing_success)

private struct OnboardingGimbalVectorIllustration: View {
    let accentGold: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(UIColor.separator), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .frame(width: 150, height: 150)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(accentGold, lineWidth: 1.8)
                        )
                        .frame(width: 22, height: 68)
                        .overlay(
                            Circle()
                                .fill(accentGold)
                                .frame(width: 4, height: 4)
                                .offset(y: -22)
                        )

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.primary)
                        .frame(width: 7, height: 48)

                    ZStack {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.primary)
                            .frame(width: 68, height: 7)

                        HStack {
                            Circle()
                                .fill(accentGold)
                                .frame(width: 16, height: 16)
                            Spacer()
                            Circle()
                                .fill(accentGold)
                                .frame(width: 16, height: 16)
                        }
                        .frame(width: 76)
                    }
                }
                .offset(x: -4, y: 6)

                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.primary)
                        .frame(width: 7, height: 34)
                }
                .frame(width: 66)
                .offset(x: 16)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.primary)
                    .frame(width: 28, height: 13)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: 16, height: 62)
                    .overlay(
                        VStack(spacing: 7) {
                            Circle().fill(accentGold).frame(width: 6, height: 6)
                            Circle().fill(Color(UIColor.systemGreen)).frame(width: 4, height: 4)
                        }
                        .offset(y: -10)
                    )
            }
        }
    }
}
