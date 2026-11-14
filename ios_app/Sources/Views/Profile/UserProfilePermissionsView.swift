//
//  UserProfilePermissionsView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Figma Node 96:3 — 21_onboarding, 22_signin, 23_permissions,
//  24_pairing_scan, 25_pairing_success, 35_profile + Hồ sơ cá nhân & Cookie Session.
//

import SwiftUI
import AuthenticationServices
import AVFoundation
import CoreBluetooth
import CryptoKit
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
    @State private var showDeleteAccountConfirm: Bool = false
    @State private var isDeletingAccount: Bool = false

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
                        let serialLabel = store.currentUser.gimbalSerial.isEmpty ? "Chưa kích hoạt Serial" : "Serial: \(store.currentUser.gimbalSerial)"
                        Text("\(serialLabel) • \(store.userTier)")
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
        let totalBytes = max(Double(camera.realTotalStorageBytes), 1.0)
        let fillFraction = camera.realTotalStorageBytes > 0
            ? min(1.0, max(0.06, Double(camera.realTotalStorageBytes) / max(Double(camera.realTotalStorageBytes), 50.0 * 1024.0 * 1024.0)))
            : 0.0
        let videoRatio = camera.realTotalStorageBytes > 0 ? fillFraction * (Double(camera.realVideoStorageBytes) / totalBytes) : 0.0
        let photoRatio = camera.realTotalStorageBytes > 0 ? fillFraction * (Double(camera.realPhotoStorageBytes) / totalBytes) : 0.0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Thư viện Thiết bị")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(camera.capturedMedia.isEmpty ? "Chưa có dữ liệu" : "\(camera.capturedMedia.count) tệp • \(camera.totalLibraryStorageBytesFormatted)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            GeometryReader { geo in
                let totalWidth = max(1, geo.size.width)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 8)

                    if camera.realTotalStorageBytes > 0 {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(UIColor.systemBlue))
                                .frame(width: totalWidth * videoRatio)
                            Rectangle()
                                .fill(accentGold)
                                .frame(width: totalWidth * photoRatio)
                        }
                        .frame(height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
            }
            .frame(height: 8)

            HStack(spacing: 14) {
                storageLegendDot(color: Color(UIColor.systemBlue), label: "\(camera.realVideoCount) Video (\(camera.videoStorageFormatted))")
                storageLegendDot(color: accentGold, label: "\(camera.realPhotoCount) Ảnh (\(camera.photoStorageFormatted))")
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
                subtitle: "Hồ sơ, SĐT, Địa chỉ & Mã Serial"
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
                subtitle: ble.isConnected
                    ? "\(store.deviceName) • Pin \(ble.batteryLevel)%\(ble.firmwareVersion.isEmpty ? "" : " • FW \(ble.firmwareVersion)")"
                    : "Chưa kết nối thiết bị • Chạm để quét BLE"
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
                Text("Đăng xuất tài khoản")
                    .font(.system(size: 16.5, weight: .medium))
                    .foregroundColor(Color(UIColor.systemOrange))
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                showDeleteAccountConfirm = true
            } label: {
                HStack(spacing: 8) {
                    if isDeletingAccount {
                        ProgressView().scaleEffect(0.85)
                    }
                    Text("Xóa vĩnh viễn tài khoản")
                        .font(.system(size: 16.5, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemRed))
                }
                .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.plain)
            .disabled(isDeletingAccount || !store.isLoggedIn)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 16)
        .confirmationDialog(
            "Xóa vĩnh viễn tài khoản T-Flow?",
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("Xóa tài khoản và dữ liệu Cloud", role: .destructive) {
                isDeletingAccount = true
                store.deleteCurrentAccount { _, _ in
                    isDeletingAccount = false
                }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Hồ sơ, phiên đăng nhập và quyền đồng bộ trên Cloud sẽ bị xóa và không thể khôi phục.")
        }
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

@MainActor
private final class NativeOAuthCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, ASWebAuthenticationPresentationContextProviding {
    static let googleClientId = "725853259455-83tapd22sn2en4cht3jdiaa0ehn734ac.apps.googleusercontent.com"
    static let googleCallbackScheme = "com.googleusercontent.apps.725853259455-83tapd22sn2en4cht3jdiaa0ehn734ac"
    static let googleRedirectUri = "com.googleusercontent.apps.725853259455-83tapd22sn2en4cht3jdiaa0ehn734ac:/oauth2redirect"

    private var appleCompletion: ((Result<(email: String, fullName: String), Error>) -> Void)?
    private var webAuthSession: ASWebAuthenticationSession?

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        Self.activeWindow()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        Self.activeWindow()
    }

    private static func activeWindow() -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let key = scene.windows.first(where: { $0.isKeyWindow }) {
                return key
            }
        }
        return scenes.first?.windows.first ?? ASPresentationAnchor()
    }

    func signInWithApple(completion: @escaping (Result<(email: String, fullName: String), Error>) -> Void) {
        self.appleCompletion = completion
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
                self.appleCompletion?(.failure(NSError(domain: "TFlowOAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không nhận được thông tin Apple ID."])))
                self.appleCompletion = nil
                return
            }
            var resolvedEmail = cred.email ?? ""
            if resolvedEmail.isEmpty, let tokenData = cred.identityToken, let jwt = Self.decodeJWTPayload(tokenData) {
                resolvedEmail = (jwt["email"] as? String) ?? ""
            }
            var assembledName = ""
            if let nameComponents = cred.fullName {
                assembledName = PersonNameComponentsFormatter().string(from: nameComponents).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if resolvedEmail.isEmpty {
                self.appleCompletion?(.failure(NSError(domain: "TFlowOAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Apple ID chưa chia sẻ email. Hãy bật quyền chia sẻ Email trong cài đặt Apple ID hoặc dùng đăng nhập Email."])))
            } else {
                self.appleCompletion?(.success((resolvedEmail.lowercased(), assembledName)))
            }
            self.appleCompletion = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.appleCompletion?(.failure(error))
            self.appleCompletion = nil
        }
    }

    func signInWithGoogle(completion: @escaping (Result<(email: String, fullName: String, avatarUrl: String), Error>) -> Void) {
        let verifier = Self.randomURLSafeString(length: 64)
        let challengeData = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(challengeData).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.googleClientId),
            URLQueryItem(name: "redirect_uri", value: Self.googleRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "select_account")
        ]
        guard let authURL = components.url else {
            completion(.failure(NSError(domain: "TFlowOAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "URL Google OAuth không hợp lệ."])))
            return
        }

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: Self.googleCallbackScheme) { [weak self] callbackURL, error in
            Task { @MainActor in
                self?.webAuthSession = nil
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let callbackURL = callbackURL,
                      let cbComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = cbComponents.queryItems?.first(where: { $0.name == "code" })?.value,
                      !code.isEmpty else {
                    let errDesc = callbackURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "error" })?.value } ?? "Không nhận được mã xác thực Google"
                    completion(.failure(NSError(domain: "TFlowOAuth", code: -4, userInfo: [NSLocalizedDescriptionKey: errDesc])))
                    return
                }
                Self.exchangeGoogleCode(code: code, codeVerifier: verifier, completion: completion)
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        self.webAuthSession = session
        session.start()
    }

    private static func exchangeGoogleCode(
        code: String,
        codeVerifier: String,
        completion: @escaping (Result<(email: String, fullName: String, avatarUrl: String), Error>) -> Void
    ) {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var bodyItems = URLComponents()
        bodyItems.queryItems = [
            URLQueryItem(name: "client_id", value: googleClientId),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "redirect_uri", value: googleRedirectUri)
        ]
        req.httpBody = bodyItems.percentEncodedQuery?.data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data,
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "TFlowOAuth", code: -5, userInfo: [NSLocalizedDescriptionKey: "Phản hồi token Google không hợp lệ."])))
                }
                return
            }
            if let errMsg = json["error_description"] as? String ?? json["error"] as? String {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "TFlowOAuth", code: -6, userInfo: [NSLocalizedDescriptionKey: "Google OAuth: \(errMsg)"])))
                }
                return
            }
            let accessToken = json["access_token"] as? String ?? ""
            let idToken = json["id_token"] as? String ?? ""
            if !accessToken.isEmpty {
                var userReq = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!)
                userReq.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                URLSession.shared.dataTask(with: userReq) { uData, _, _ in
                    if let uData = uData,
                       let uJson = (try? JSONSerialization.jsonObject(with: uData)) as? [String: Any],
                       let email = (uJson["email"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                       !email.isEmpty {
                        let name = (uJson["name"] as? String) ?? ""
                        let pic = (uJson["picture"] as? String) ?? ""
                        DispatchQueue.main.async { completion(.success((email, name, pic))) }
                        return
                    }
                    Self.fallbackFromIdToken(idToken, completion: completion)
                }.resume()
            } else {
                Self.fallbackFromIdToken(idToken, completion: completion)
            }
        }.resume()
    }

    private static func fallbackFromIdToken(
        _ idToken: String,
        completion: @escaping (Result<(email: String, fullName: String, avatarUrl: String), Error>) -> Void
    ) {
        if let tokenData = idToken.data(using: .utf8),
           let jwt = decodeJWTPayloadString(idToken) ?? decodeJWTPayload(tokenData),
           let email = (jwt["email"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !email.isEmpty {
            let name = (jwt["name"] as? String) ?? ""
            let pic = (jwt["picture"] as? String) ?? ""
            DispatchQueue.main.async { completion(.success((email, name, pic))) }
            return
        }
        DispatchQueue.main.async {
            completion(.failure(NSError(domain: "TFlowOAuth", code: -7, userInfo: [NSLocalizedDescriptionKey: "Không đọc được thông tin email Google."])))
        }
    }

    private static func decodeJWTPayload(_ tokenData: Data) -> [String: Any]? {
        guard let str = String(data: tokenData, encoding: .utf8) else { return nil }
        return decodeJWTPayloadString(str)
    }

    private static func decodeJWTPayloadString(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let payloadData = Data(base64Encoded: base64),
              let obj = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }
        return obj
    }

    private static func randomURLSafeString(length: Int) -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }
}

struct GoogleGLogoView: View {
    var size: CGFloat = 20

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = min(canvasSize.width, canvasSize.height) / 24.0
            let t = CGAffineTransform(scaleX: s, y: s)

            // Red top arc
            var red = Path()
            red.move(to: CGPoint(x: 12, y: 5.38))
            red.addCurve(to: CGPoint(x: 16.21, y: 7.01), control1: CGPoint(x: 13.62, y: 5.38), control2: CGPoint(x: 15.06, y: 5.94))
            red.addLine(to: CGPoint(x: 19.36, y: 3.86))
            red.addCurve(to: CGPoint(x: 12, y: 1.0), control1: CGPoint(x: 17.45, y: 2.09), control2: CGPoint(x: 14.97, y: 1.0))
            red.addCurve(to: CGPoint(x: 2.18, y: 7.07), control1: CGPoint(x: 7.7, y: 1.0), control2: CGPoint(x: 3.99, y: 3.47))
            red.addLine(to: CGPoint(x: 5.84, y: 9.91))
            red.addCurve(to: CGPoint(x: 12, y: 5.38), control1: CGPoint(x: 6.71, y: 7.31), control2: CGPoint(x: 9.14, y: 5.38))
            red.closeSubpath()
            ctx.fill(red.applying(t), with: .color(Color(red: 234/255, green: 67/255, blue: 53/255)))

            // Blue right bar
            var blue = Path()
            blue.move(to: CGPoint(x: 22.56, y: 12.25))
            blue.addCurve(to: CGPoint(x: 22.36, y: 10.0), control1: CGPoint(x: 22.56, y: 11.47), control2: CGPoint(x: 22.49, y: 10.72))
            blue.addLine(to: CGPoint(x: 12, y: 10.0))
            blue.addLine(to: CGPoint(x: 12, y: 14.26))
            blue.addLine(to: CGPoint(x: 17.92, y: 14.26))
            blue.addCurve(to: CGPoint(x: 15.71, y: 17.57), control1: CGPoint(x: 17.66, y: 15.63), control2: CGPoint(x: 16.88, y: 16.79))
            blue.addLine(to: CGPoint(x: 19.28, y: 20.34))
            blue.addCurve(to: CGPoint(x: 22.56, y: 12.25), control1: CGPoint(x: 21.36, y: 18.42), control2: CGPoint(x: 22.56, y: 15.6))
            blue.closeSubpath()
            ctx.fill(blue.applying(t), with: .color(Color(red: 66/255, green: 133/255, blue: 244/255)))

            // Yellow left arc
            var yellow = Path()
            yellow.move(to: CGPoint(x: 5.84, y: 14.09))
            yellow.addCurve(to: CGPoint(x: 5.49, y: 12.0), control1: CGPoint(x: 5.62, y: 13.43), control2: CGPoint(x: 5.49, y: 12.73))
            yellow.addCurve(to: CGPoint(x: 5.84, y: 9.91), control1: CGPoint(x: 5.49, y: 11.27), control2: CGPoint(x: 5.62, y: 10.57))
            yellow.addLine(to: CGPoint(x: 2.18, y: 7.07))
            yellow.addCurve(to: CGPoint(x: 1.0, y: 12.0), control1: CGPoint(x: 1.43, y: 8.55), control2: CGPoint(x: 1.0, y: 10.22))
            yellow.addCurve(to: CGPoint(x: 2.18, y: 16.93), control1: CGPoint(x: 1.0, y: 13.78), control2: CGPoint(x: 1.43, y: 15.45))
            yellow.addLine(to: CGPoint(x: 5.84, y: 14.09))
            yellow.closeSubpath()
            ctx.fill(yellow.applying(t), with: .color(Color(red: 251/255, green: 188/255, blue: 5/255)))

            // Green bottom arc
            var green = Path()
            green.move(to: CGPoint(x: 12, y: 23.0))
            green.addCurve(to: CGPoint(x: 19.28, y: 20.34), control1: CGPoint(x: 14.97, y: 23.0), control2: CGPoint(x: 17.46, y: 22.02))
            green.addLine(to: CGPoint(x: 15.71, y: 17.57))
            green.addCurve(to: CGPoint(x: 12, y: 18.62), control1: CGPoint(x: 14.73, y: 18.23), control2: CGPoint(x: 13.48, y: 18.62))
            green.addCurve(to: CGPoint(x: 5.84, y: 14.09), control1: CGPoint(x: 9.14, y: 18.62), control2: CGPoint(x: 6.71, y: 16.69))
            green.addLine(to: CGPoint(x: 2.18, y: 16.93))
            green.addCurve(to: CGPoint(x: 12, y: 23.0), control1: CGPoint(x: 3.99, y: 20.53), control2: CGPoint(x: 7.7, y: 23.0))
            green.closeSubpath()
            ctx.fill(green.applying(t), with: .color(Color(red: 52/255, green: 168/255, blue: 83/255)))
        }
        .frame(width: size, height: size)
    }
}

struct AuthSignInGateView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showOnboarding: Bool = false
    @State private var onboardingPage: Int = 0
    @State private var selectedTab: Int = 0 // 0 = Đăng nhập, 1 = Đăng ký
    @StateObject private var oauthCoordinator = NativeOAuthCoordinator()
    @State private var isAuthBusy: Bool = false

    @State private var loginIdentifier: String = ""
    @State private var loginPassword: String = ""
    @State private var showLoginPassword: Bool = false

    @State private var regFullName: String = ""
    @State private var regEmail: String = ""
    @State private var regPhone: String = ""
    @State private var regPassword: String = ""
    @State private var regSerial: String = ""
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
            "Quay màu phẳng điện ảnh, đồng bộ hồ sơ và lưu trữ thư viện thiết bị thực tế.",
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
                if store.isLoggedIn {
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
                showOnboarding = !store.hasCompletedOnboarding && !store.isLoggedIn
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

            Button {
                isAuthBusy = true
                authError = ""
                store.login(identifier: loginIdentifier, password: loginPassword) { ok, message in
                    isAuthBusy = false
                    if ok {
                        authError = ""
                        store.hasCompletedOnboarding = true
                        store.showSignInSheet = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    } else {
                        authError = message
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isAuthBusy {
                        ProgressView().tint(.black)
                    }
                    Text("Đăng nhập")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentGold)
                )
            }
            .buttonStyle(.plain)
            .disabled(isAuthBusy)

            HStack(spacing: 12) {
                Rectangle().fill(Color(UIColor.separator)).frame(height: 0.5)
                Text("HOẶC")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Rectangle().fill(Color(UIColor.separator)).frame(height: 0.5)
            }
            .padding(.vertical, 4)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                authError = ""
                isAuthBusy = true
                oauthCoordinator.signInWithApple { result in
                    switch result {
                    case .success(let info):
                        store.signInWithOAuthAccount(email: info.email, fullName: info.fullName, provider: "Apple") { ok, msg in
                            isAuthBusy = false
                            if ok {
                                authError = ""
                                store.hasCompletedOnboarding = true
                                store.showSignInSheet = false
                                dismiss()
                            } else {
                                authError = msg
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            }
                        }
                    case .failure(let error):
                        isAuthBusy = false
                        let nsErr = error as NSError
                        if nsErr.domain != ASAuthorizationError.errorDomain || nsErr.code != ASAuthorizationError.canceled.rawValue {
                            authError = "Apple Sign-In: \(error.localizedDescription)"
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                }
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
            .disabled(isAuthBusy)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                authError = ""
                isAuthBusy = true
                oauthCoordinator.signInWithGoogle { result in
                    switch result {
                    case .success(let info):
                        store.signInWithOAuthAccount(
                            email: info.email,
                            fullName: info.fullName,
                            provider: "Google",
                            avatarUrl: info.avatarUrl
                        ) { ok, msg in
                            isAuthBusy = false
                            if ok {
                                authError = ""
                                store.hasCompletedOnboarding = true
                                store.showSignInSheet = false
                                dismiss()
                            } else {
                                authError = msg
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            }
                        }
                    case .failure(let error):
                        isAuthBusy = false
                        let nsErr = error as NSError
                        if nsErr.domain != ASWebAuthenticationSessionError.errorDomain || nsErr.code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            authError = "Google OAuth: \(error.localizedDescription)"
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    GoogleGLogoView(size: 20)
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
            .disabled(isAuthBusy)
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
                    TextField("Mật khẩu (tối thiểu 6 ký tự)", text: $regPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("Mật khẩu (tối thiểu 6 ký tự)", text: $regPassword)
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

            authFieldRow(icon: "barcode.viewfinder", placeholder: "Mã Serial Gimbal (không bắt buộc)", text: $regSerial, autocap: .characters)

            Button {
                isAuthBusy = true
                authError = ""
                store.register(
                    fullName: regFullName,
                    email: regEmail,
                    phone: regPhone,
                    password: regPassword,
                    gimbalSerial: regSerial
                ) { ok, message in
                    isAuthBusy = false
                    if ok {
                        authError = ""
                        store.hasCompletedOnboarding = true
                        store.showSignInSheet = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    } else {
                        authError = message
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isAuthBusy {
                        ProgressView().tint(.black)
                    }
                    Text("Đăng ký")
                        .font(.system(size: 16.5, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentGold)
                )
            }
            .buttonStyle(.plain)
            .disabled(isAuthBusy)
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

// MARK: - 3. PERSONAL INFO EDITOR

struct PersonalInfoEditSheetView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var district: String = ""
    @State private var shippingNotes: String = ""
    @State private var jobTitle: String = ""
    @State private var cameraSetup: String = ""
    @State private var gimbalSerial: String = ""
    @State private var newPassword: String = ""
    @State private var statusBanner: String? = nil
    @State private var errorBanner: String? = nil

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
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

                if let err = errorBanner {
                    Section {
                        Text(err)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemRed))
                    }
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
                    LabeledContent("Nghề nghiệp / Vai trò") {
                        TextField("VD: Filmmaker / Vlogger", text: $jobTitle)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Thiết bị quay chính") {
                        TextField("VD: iPhone 16 Pro Max", text: $cameraSetup)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Serial Gimbal") {
                        TextField("Nhập mã Serial (nếu có)", text: $gimbalSerial)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                    LabeledContent("Đổi mật khẩu") {
                        SecureField("Tối thiểu 6 ký tự (để trống nếu giữ)", text: $newPassword)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Địa chỉ giao nhận & Bảo hành") {
                    LabeledContent("Địa chỉ") {
                        TextField("Số nhà, đường, phường/xã", text: $address)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Quận / Huyện") {
                        TextField("Quận / Huyện", text: $district)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Tỉnh / Thành phố") {
                        TextField("TP. Hồ Chí Minh / Hà Nội...", text: $city)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Ghi chú giao nhận") {
                        TextField("Thời gian nhận hàng / bảo hành", text: $shippingNotes)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    Button {
                        let cleanPw = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleanPw.isEmpty && cleanPw.count < 6 {
                            errorBanner = "Mật khẩu mới cần tối thiểu 6 ký tự."
                            statusBanner = nil
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            return
                        }
                        errorBanner = nil
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        store.updatePersonalProfile(
                            fullName: fullName,
                            email: email,
                            phone: phone,
                            address: address,
                            city: city,
                            district: district,
                            shippingNotes: shippingNotes,
                            jobTitle: jobTitle,
                            cameraSetup: cameraSetup,
                            gimbalSerial: gimbalSerial,
                            newPassword: newPassword
                        )
                        newPassword = ""
                        statusBanner = "✓ Đã lưu thông tin cá nhân & đồng bộ Web / Cloud"
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
                city = store.currentUser.city
                district = store.currentUser.district
                shippingNotes = store.currentUser.shippingNotes
                jobTitle = store.currentUser.jobTitle
                cameraSetup = store.currentUser.cameraSetup
                gimbalSerial = store.currentUser.gimbalSerial == "TF-G31-PRO" ? "" : store.currentUser.gimbalSerial
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
    @State private var pairedDeviceName: String = "T-Flow Pro"

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if isPairedSuccess || ble.isConnected {
                    pairedSuccessContent
                } else {
                    scanningContent
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle((isPairedSuccess || ble.isConnected) ? "Kết nối thành công" : "Ghép đôi Bluetooth")
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
                if !ble.isConnected {
                    ble.startScan()
                } else {
                    pairedDeviceName = ble.connectedPeripheralName.isEmpty ? store.deviceName : ble.connectedPeripheralName
                    isPairedSuccess = true
                }
            }
            .onDisappear {
                ble.stopScan()
            }
            .onChange(of: ble.isConnected) { connected in
                if connected {
                    let finalName = ble.connectedPeripheralName.isEmpty
                        ? (connectingDeviceName ?? "T-Flow Pro")
                        : ble.connectedPeripheralName
                    pairedDeviceName = finalName
                    store.deviceName = finalName
                    store.updateDeviceTelemetry(
                        deviceName: finalName,
                        battery: ble.batteryLevel,
                        firmware: ble.firmwareVersion
                    )
                    connectingDeviceName = nil
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPairedSuccess = true
                    }
                } else {
                    connectingDeviceName = nil
                    isPairedSuccess = false
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

                Text(ble.isScanning ? "Đang tìm kiếm Gimbal..." : "Ghép nối Bluetooth BLE")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                Text(ble.bluetoothStateText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("THIẾT BỊ TÌM THẤY (\(ble.discoveredPeripherals.count))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        if ble.isScanning {
                            ble.stopScan()
                        } else {
                            ble.startScan()
                        }
                    } label: {
                        Text(ble.isScanning ? "Dừng quét" : "Quét lại")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(accentGold)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                if ble.discoveredPeripherals.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 26))
                            .foregroundColor(.secondary)
                        Text(ble.isScanning
                             ? "Đang dò sóng Bluetooth Low Energy xung quanh..."
                             : "Chưa phát hiện phần cứng Gimbal ở chế độ chờ ghép nối.")
                            .font(.system(size: 13.5))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            ble.startScan()
                        } label: {
                            Text("Bắt đầu quét thiết bị")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(accentGold))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(ble.discoveredPeripherals.enumerated()), id: \.element.identifier) { idx, peripheral in
                            if idx > 0 {
                                Divider().padding(.leading, 56)
                            }
                            let pName = peripheral.name ?? "Thiết bị T-Flow BLE"
                            discoveredDeviceRow(
                                name: pName,
                                badge: idx == 0 ? "Gần nhất" : nil,
                                subtitle: "UUID: \(peripheral.identifier.uuidString.prefix(8)) • BLE 5.3",
                                icon: "antenna.radiowaves.left.and.right",
                                iconBg: idx == 0 ? Color(UIColor.systemGreen) : Color(UIColor.systemGray),
                                buttonTitle: "Kết nối",
                                isPrimary: idx == 0
                            ) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                connectingDeviceName = pName
                                ble.connect(to: peripheral)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 16)
                }
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
        isPrimary: Bool,
        onTap: @escaping () -> Void
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
                onTap()
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
                    trailing: ble.batteryLevel > 0 ? "\(ble.batteryLevel)%" : "Đang đọc telemetry BLE"
                )
                Divider().padding(.leading, 56)
                successStatusRow(
                    icon: "info.circle.fill",
                    iconBg: Color(UIColor.systemBlue),
                    title: "Phiên bản Firmware",
                    trailing: ble.firmwareVersion.isEmpty ? "Chưa rõ" : ble.firmwareVersion
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

                Button {
                    ble.disconnect()
                    isPairedSuccess = false
                    ble.startScan()
                } label: {
                    Text("Ngắt kết nối Gimbal")
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundColor(Color(UIColor.systemRed))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
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
