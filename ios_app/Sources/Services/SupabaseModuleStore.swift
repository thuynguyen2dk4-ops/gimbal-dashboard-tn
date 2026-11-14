//
//  SupabaseModuleStore.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Auth Session (HTTPCookieStorage.shared + UserDefaults), Hồ sơ cá nhân & 7-Module Cloud Sync.
//

import SwiftUI
import Combine
import UIKit

// MARK: - =====================================================================
// 3. CLOUD SUPABASE MODULE & AUTH SESSION STORE
// =====================================================================

final class SupabaseModuleStore: ObservableObject {
    // Existing Cloud & 7-Module Permissions State (Preserved)
    @Published var userName: String = "Thủy Nguyễn (Founder)"
    @Published var userTier: String = "VIP LIFETIME"
    @Published var deviceName: String = "Smart Gimbal S1 Titanium"
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: String = "Vừa xong"
    @Published var modules: [Bool] = [true, true, true, true, true, true, true]

    // Navigation & Modal Coordination State (Figma Node 96:3)
    @Published var activeMainTab: Int = 0
    @Published var showSignInSheet: Bool = false
    @Published var showPairingModal: Bool = false
    @Published var showPermissionsModal: Bool = false
    @Published var showAiCopilotSheet: Bool = false

    // Auth & Session Cookie State
    @Published var isLoggedIn: Bool = false
    @Published var isGuestMode: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUser: UserAccountProfile = UserAccountProfile(
        fullName: "Thủy Nguyễn",
        email: "thuynguyen2dk4@gmail.com",
        phone: "0909 123 456",
        address: "TP. Thủ Đức, TP.HCM",
        gimbalSerial: "TF-G31-PRO",
        memberSince: "11/2025"
    )
    @Published var sessionId: String = ""
    @Published var sessionCookieToken: String = ""
    @Published var sessionCreatedAt: Date? = nil

    // Studio & Hardware Preferences
    @Published var autoBackupProjects: Bool = true
    @Published var saveToPhotosEnabled: Bool = true
    @Published var gyroBeepsEnabled: Bool = true
    @Published var autoReconnectBLE: Bool = true

    private struct StoredAccount: Codable {
        var password: String
        var profile: UserAccountProfile
    }

    private struct PersistedSession: Codable {
        var sessionId: String
        var sessionCookieToken: String
        var createdAt: Date
        var email: String
    }

    private let tierStorageKey = "tflow_user_tier_v1"
    private let modulesStorageKey = "tflow_user_modules_v1"
    private let authSessionStorageKey = "tflow_auth_session_v1"
    private let userProfileStorageKey = "tflow_user_profile_v1"
    private let registeredAccountsStorageKey = "tflow_registered_accounts_v1"

    private let cookieName = "tflow_session_token"
    private let cookieDomain = ".t-flow-tech.vercel.app"

    init() {
        loadPersistedState()
    }

    // MARK: - Persisted State & Cookie Hydration

    private func loadPersistedState() {
        let defaults = UserDefaults.standard
        if let savedTier = defaults.string(forKey: tierStorageKey), !savedTier.isEmpty {
            userTier = savedTier
        }
        if let savedModules = defaults.array(forKey: modulesStorageKey) as? [Bool], savedModules.count == 7 {
            modules = savedModules
        }
        if let profileData = defaults.data(forKey: userProfileStorageKey),
           let decodedProfile = try? JSONDecoder().decode(UserAccountProfile.self, from: profileData) {
            currentUser = decodedProfile
        }

        if let sessionData = defaults.data(forKey: authSessionStorageKey),
           let savedSession = try? JSONDecoder().decode(PersistedSession.self, from: sessionData),
           !savedSession.sessionCookieToken.isEmpty {
            sessionId = savedSession.sessionId
            sessionCookieToken = savedSession.sessionCookieToken
            sessionCreatedAt = savedSession.createdAt
            isLoggedIn = true
            isGuestMode = false
            hasCompletedOnboarding = true
            userName = currentUser.fullName
            writeSessionCookie(token: savedSession.sessionCookieToken)
        }
    }

    private func persistState() {
        let defaults = UserDefaults.standard
        defaults.set(userTier, forKey: tierStorageKey)
        defaults.set(modules, forKey: modulesStorageKey)
        if let encodedProfile = try? JSONEncoder().encode(currentUser) {
            defaults.set(encodedProfile, forKey: userProfileStorageKey)
        }
    }

    private func loadRegisteredAccounts() -> [StoredAccount] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: registeredAccountsStorageKey),
              let accounts = try? JSONDecoder().decode([StoredAccount].self, from: data) else {
            return []
        }
        return accounts
    }

    private func saveRegisteredAccounts(_ accounts: [StoredAccount]) {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: registeredAccountsStorageKey)
        }
    }

    private func createAndPersistSession(for profile: UserAccountProfile) {
        let newSessionId = "SESS-\(UUID().uuidString.prefix(8))"
        let newToken = "tflow_tok_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
        let now = Date()

        currentUser = profile
        userName = profile.fullName
        sessionId = newSessionId
        sessionCookieToken = newToken
        sessionCreatedAt = now
        isLoggedIn = true
        isGuestMode = false
        hasCompletedOnboarding = true
        showSignInSheet = false

        let persisted = PersistedSession(
            sessionId: newSessionId,
            sessionCookieToken: newToken,
            createdAt: now,
            email: profile.email
        )
        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: authSessionStorageKey)
        }
        writeSessionCookie(token: newToken)
        persistState()
    }

    private func writeSessionCookie(token: String) {
        let properties: [HTTPCookiePropertyKey: Any] = [
            .domain: cookieDomain,
            .path: "/",
            .name: cookieName,
            .value: token,
            .secure: "TRUE",
            .expires: Date().addingTimeInterval(30 * 24 * 3600)
        ]
        if let cookie = HTTPCookie(properties: properties) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }

    private func clearSessionCookies() {
        let storage = HTTPCookieStorage.shared
        for cookie in storage.cookies ?? [] {
            if cookie.name == cookieName || cookie.domain.contains("t-flow-tech.vercel.app") {
                storage.deleteCookie(cookie)
            }
        }
    }

    var activeCookieSummary: String {
        let stored = (HTTPCookieStorage.shared.cookies ?? []).first {
            $0.name == cookieName || $0.domain.contains("t-flow-tech.vercel.app")
        }
        if let cookie = stored {
            let preview = String(cookie.value.prefix(16))
            return "\(cookie.name)=\(preview)… (\(cookie.domain))"
        }
        if !sessionCookieToken.isEmpty {
            let preview = String(sessionCookieToken.prefix(16))
            return "\(cookieName)=\(preview)… (\(cookieDomain))"
        }
        return "Chưa có Cookie phiên"
    }

    // MARK: - Authentication Actions

    func login(identifier: String, password: String) -> (ok: Bool, message: String) {
        let idTrimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let idLower = idTrimmed.lowercased()
        let pwTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !idTrimmed.isEmpty, !pwTrimmed.isEmpty else {
            return (false, "Vui lòng nhập Email/SĐT và mật khẩu.")
        }

        // Check user-registered accounts first
        let accounts = loadRegisteredAccounts()
        let normalizedPhoneInput = idTrimmed.replacingOccurrences(of: " ", with: "")
        if let matched = accounts.first(where: { acc in
            let accPhone = acc.profile.phone.replacingOccurrences(of: " ", with: "")
            return (acc.profile.email.lowercased() == idLower || accPhone == normalizedPhoneInput)
                && acc.password == pwTrimmed
        }) {
            createAndPersistSession(for: matched.profile)
            return (true, "Đăng nhập thành công")
        }

        // Built-in Founder/Demo Studio account support
        let isDemoAccount = idLower == "thuynguyen2dk4@gmail.com" || normalizedPhoneInput == "0909123456"
        if isDemoAccount && (pwTrimmed == "admin" || pwTrimmed == "123456" || pwTrimmed == "tflow") {
            let profile = currentUser.email.lowercased() == "thuynguyen2dk4@gmail.com"
                ? currentUser
                : UserAccountProfile(
                    fullName: "Thủy Nguyễn",
                    email: "thuynguyen2dk4@gmail.com",
                    phone: "0909 123 456",
                    address: "TP. Thủ Đức, TP.HCM",
                    gimbalSerial: "TF-G31-PRO",
                    memberSince: "11/2025"
                )
            createAndPersistSession(for: profile)
            return (true, "Đăng nhập thành công")
        }

        return (false, "Email/SĐT hoặc mật khẩu chưa chính xác.")
    }

    func register(
        fullName: String,
        email: String,
        phone: String,
        password: String,
        gimbalSerial: String
    ) -> (ok: Bool, message: String) {
        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSerial = gimbalSerial.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            return (false, "Vui lòng nhập họ và tên.")
        }
        guard cleanEmail.contains("@") && cleanEmail.contains(".") else {
            return (false, "Email không hợp lệ.")
        }
        guard cleanPassword.count >= 4 else {
            return (false, "Mật khẩu cần tối thiểu 4 ký tự.")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yyyy"
        let profile = UserAccountProfile(
            fullName: cleanName,
            email: cleanEmail,
            phone: cleanPhone.isEmpty ? "0909 000 000" : cleanPhone,
            address: currentUser.address,
            gimbalSerial: cleanSerial.isEmpty ? "TF-G31-PRO" : cleanSerial.uppercased(),
            memberSince: formatter.string(from: Date())
        )

        var accounts = loadRegisteredAccounts()
        accounts.removeAll { $0.profile.email.lowercased() == cleanEmail.lowercased() }
        accounts.append(StoredAccount(password: cleanPassword, profile: profile))
        saveRegisteredAccounts(accounts)

        createAndPersistSession(for: profile)
        return (true, "Tạo tài khoản & Cookie Session thành công")
    }

    func signInWithApple() {
        let profile = currentUser.email.isEmpty
            ? UserAccountProfile(
                fullName: "Thủy Nguyễn",
                email: "thuynguyen2dk4@gmail.com",
                phone: "0909 123 456",
                address: "TP. Thủ Đức, TP.HCM",
                gimbalSerial: "TF-G31-PRO",
                memberSince: "11/2025"
            )
            : currentUser
        createAndPersistSession(for: profile)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func signInWithGoogle() {
        signInWithApple()
    }

    func continueAsGuest() {
        isGuestMode = true
        isLoggedIn = false
        hasCompletedOnboarding = true
        showSignInSheet = false
        userName = "Khách Studio"
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func refreshSessionCookie() {
        let newToken = "tflow_tok_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
        sessionCookieToken = newToken
        sessionCreatedAt = Date()
        if sessionId.isEmpty {
            sessionId = "SESS-\(UUID().uuidString.prefix(8))"
        }
        let persisted = PersistedSession(
            sessionId: sessionId,
            sessionCookieToken: newToken,
            createdAt: sessionCreatedAt ?? Date(),
            email: currentUser.email
        )
        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: authSessionStorageKey)
        }
        writeSessionCookie(token: newToken)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func updatePersonalProfile(
        fullName: String,
        email: String,
        phone: String,
        address: String,
        gimbalSerial: String,
        newPassword: String? = nil
    ) {
        let updated = UserAccountProfile(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? currentUser.fullName : fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? currentUser.email : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            gimbalSerial: gimbalSerial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            memberSince: currentUser.memberSince
        )

        let oldEmail = currentUser.email.lowercased()
        currentUser = updated
        userName = updated.fullName
        persistState()

        if let pw = newPassword?.trimmingCharacters(in: .whitespacesAndNewlines), !pw.isEmpty {
            var accounts = loadRegisteredAccounts()
            if let idx = accounts.firstIndex(where: { $0.profile.email.lowercased() == oldEmail || $0.profile.email.lowercased() == updated.email.lowercased() }) {
                accounts[idx].password = pw
                accounts[idx].profile = updated
            } else {
                accounts.append(StoredAccount(password: pw, profile: updated))
            }
            saveRegisteredAccounts(accounts)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func logout() {
        clearSessionCookies()
        UserDefaults.standard.removeObject(forKey: authSessionStorageKey)
        sessionId = ""
        sessionCookieToken = ""
        sessionCreatedAt = nil
        isLoggedIn = false
        isGuestMode = false
        activeMainTab = 0
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - 7-Module Permissions & Cloud Sync (Preserved)

    var isAiVisionAllowed: Bool { modules.indices.contains(0) ? modules[0] : true }
    var isProResAllowed: Bool { modules.indices.contains(1) ? modules[1] : true }
    var isMotionlapseAllowed: Bool { modules.indices.contains(2) ? modules[2] : true }
    var isMultiCamAllowed: Bool { modules.indices.contains(3) ? modules[3] : true }
    var is3DLutAllowed: Bool { modules.indices.contains(4) ? modules[4] : true }
    var isFocTuningAllowed: Bool { modules.indices.contains(5) ? modules[5] : true }
    var isRawTelemetryAllowed: Bool { modules.indices.contains(6) ? modules[6] : true }

    func toggleModule(at index: Int) {
        guard modules.indices.contains(index) else { return }
        modules[index].toggle()
        persistState()
        syncWithCloud()
    }

    func setTier(_ tier: String) {
        userTier = tier
        if tier == "Free Starter" {
            modules = [false, false, false, false, false, false, false]
        } else if tier == "Creator Pro" {
            modules = [true, true, true, true, true, false, false]
        } else {
            modules = [true, true, true, true, true, true, true]
        }
        persistState()
        syncWithCloud()
    }

    func syncWithCloud() {
        persistState()
        isSyncing = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.isSyncing = false
            self.isOnline = true
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.lastSyncTime = formatter.string(from: Date())
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
