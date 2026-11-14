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
    @Published var userName: String = ""
    @Published var userTier: String = "Standard"
    @Published var deviceName: String = "Smart Gimbal S1 Titanium"
    @Published var deviceBattery: Int = 94
    @Published var deviceFirmware: String = "v2.4.1"
    @Published var cloudUsersCount: Int = 0
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
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUser: UserAccountProfile = UserAccountProfile(
        fullName: "",
        email: "",
        phone: "",
        address: "",
        gimbalSerial: "TF-G31-PRO",
        memberSince: ""
    )

    private static let legacyFakeDemoEmails: Set<String> = [
        "mailinh.vlog@gmail.com",
        "minh.cinema@gmail.com",
        "long.director@gmail.com",
        "huong.studio@gmail.com",
        "ngoc.pro@gmail.com",
        "dung.travel@gmail.com"
    ]

    private static let legacyFakeDemoIds: Set<String> = [
        "usr-mailinh",
        "usr-minh",
        "usr-long",
        "usr-huong",
        "usr-ngoc",
        "usr-dung"
    ]
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
    private let deviceNameStorageKey = "tflow_device_name_v1"
    private let deviceBatteryStorageKey = "tflow_device_battery_v1"
    private let deviceFirmwareStorageKey = "tflow_device_firmware_v1"

    private let cookieName = "tflow_session_token"
    private let cookieDomain = ".t-flow-tech.vercel.app"

    private let supabaseRestURL = "https://dlgkrwodxdsbbliwdnkg.supabase.co/rest/v1"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZ2tyd29keGRzYmJsaXdkbmtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxMjIwNjQsImV4cCI6MjEwOTY5ODA2NH0.Lg6C6MpLhX_CoKgWtl_nhWLGNw5NuYE9FZJoTxXnu6I"
    private let supabaseWriteQueue = DispatchQueue(label: "com.tflow.supabase.write.serial", qos: .utility)
    private var activePushCount: Int = 0

    private enum SyncPayloadMode {
        case full
        case profileOnly
        case modulesOnly
        case telemetryOnly
    }

    private struct SupabaseUserRow: Codable {
        var id: String?
        var name: String?
        var email: String?
        var phone: String?
        var device: String?
        var tier: String?
        var tier_badge: String?
        var member_since: String?
        var serial: String?
        var warranty_days: Int?
        var battery: Int?
        var firmware: String?
        var status: String?
        var modules: [Bool]?
        var is_admin: Bool?
        var last_active: String?
    }

    private struct SupabaseFullPayload: Encodable {
        var id: String
        var name: String
        var email: String
        var phone: String
        var device: String
        var tier: String
        var tier_badge: String
        var member_since: String
        var serial: String
        var warranty_days: Int
        var battery: Int
        var firmware: String
        var status: String
        var modules: [Bool]
        var is_admin: Bool
        var last_active: String
    }

    private struct SupabaseProfilePatch: Encodable {
        var name: String
        var email: String
        var phone: String
        var serial: String
        var last_active: String
    }

    private struct SupabaseModulesPatch: Encodable {
        var tier: String
        var tier_badge: String
        var modules: [Bool]
        var last_active: String
    }

    private struct SupabaseTelemetryPatch: Encodable {
        var device: String
        var battery: Int
        var firmware: String
        var last_active: String
    }

    init() {
        loadPersistedState()
        syncWithCloud()
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
        if let savedDevice = defaults.string(forKey: deviceNameStorageKey), !savedDevice.isEmpty {
            deviceName = savedDevice
        }
        if defaults.object(forKey: deviceBatteryStorageKey) != nil {
            deviceBattery = defaults.integer(forKey: deviceBatteryStorageKey)
        }
        if let savedFw = defaults.string(forKey: deviceFirmwareStorageKey), !savedFw.isEmpty {
            deviceFirmware = savedFw
        }
        if let sessionData = defaults.data(forKey: authSessionStorageKey),
           let savedSession = try? JSONDecoder().decode(PersistedSession.self, from: sessionData),
           !savedSession.sessionCookieToken.isEmpty,
           !Self.legacyFakeDemoEmails.contains(savedSession.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
            if let profileData = defaults.data(forKey: userProfileStorageKey),
               let decodedProfile = try? JSONDecoder().decode(UserAccountProfile.self, from: profileData),
               !Self.legacyFakeDemoEmails.contains(decodedProfile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
                currentUser = decodedProfile
            }
            sessionId = savedSession.sessionId
            sessionCookieToken = savedSession.sessionCookieToken
            sessionCreatedAt = savedSession.createdAt
            isLoggedIn = true
            hasCompletedOnboarding = true
            userName = currentUser.fullName
            writeSessionCookie(token: savedSession.sessionCookieToken)
        } else {
            defaults.removeObject(forKey: authSessionStorageKey)
            defaults.removeObject(forKey: userProfileStorageKey)
            clearSessionCookies()
            isLoggedIn = false
            userName = ""
            currentUser = UserAccountProfile(
                fullName: "",
                email: "",
                phone: "",
                address: "",
                gimbalSerial: "TF-G31-PRO",
                memberSince: ""
            )
        }
    }

    private func persistState() {
        let defaults = UserDefaults.standard
        defaults.set(userTier, forKey: tierStorageKey)
        defaults.set(modules, forKey: modulesStorageKey)
        defaults.set(deviceName, forKey: deviceNameStorageKey)
        defaults.set(deviceBattery, forKey: deviceBatteryStorageKey)
        defaults.set(deviceFirmware, forKey: deviceFirmwareStorageKey)
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
        let filtered = accounts.filter {
            !Self.legacyFakeDemoEmails.contains($0.profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }
        if filtered.count != accounts.count {
            saveRegisteredAccounts(filtered)
        }
        return filtered
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
            syncUserRecordAfterLogin(for: matched.profile)
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
            phone: cleanPhone,
            address: currentUser.address,
            gimbalSerial: cleanSerial.isEmpty ? "TF-G31-PRO" : cleanSerial.uppercased(),
            memberSince: formatter.string(from: Date())
        )

        var accounts = loadRegisteredAccounts()
        accounts.removeAll { $0.profile.email.lowercased() == cleanEmail.lowercased() }
        accounts.append(StoredAccount(password: cleanPassword, profile: profile))
        saveRegisteredAccounts(accounts)

        createAndPersistSession(for: profile)
        pushCurrentUserToSupabase(mode: .full)
        return (true, "Đăng ký tài khoản thành công")
    }

    func signInWithOAuthAccount(
        email: String,
        fullName: String,
        provider: String
    ) -> (ok: Bool, message: String) {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanEmail.contains("@"),
              cleanEmail.contains("."),
              !Self.legacyFakeDemoEmails.contains(cleanEmail) else {
            return (false, "Vui lòng nhập địa chỉ email \(provider) hợp lệ.")
        }

        var accounts = loadRegisteredAccounts()
        let existingIdx = accounts.firstIndex { $0.profile.email.lowercased() == cleanEmail }
        let existingProfile = existingIdx.map { accounts[$0].profile }

        let cleanedInputName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackLocalName = cleanEmail.components(separatedBy: "@").first?
            .replacingOccurrences(of: ".", with: " ")
            .capitalized ?? cleanEmail
        let resolvedName: String
        if !cleanedInputName.isEmpty {
            resolvedName = cleanedInputName
        } else if let existingName = existingProfile?.fullName, !existingName.isEmpty {
            resolvedName = existingName
        } else {
            resolvedName = fallbackLocalName
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yyyy"
        let profile = UserAccountProfile(
            fullName: resolvedName,
            email: cleanEmail,
            phone: existingProfile?.phone ?? "",
            address: existingProfile?.address ?? "",
            gimbalSerial: existingProfile?.gimbalSerial ?? "TF-G31-PRO",
            memberSince: (existingProfile?.memberSince.isEmpty == false)
                ? existingProfile!.memberSince
                : formatter.string(from: Date())
        )

        if let idx = existingIdx {
            accounts[idx].profile = profile
        } else {
            let oauthCredential = "oauth_\(provider.lowercased())_\(UUID().uuidString)"
            accounts.append(StoredAccount(password: oauthCredential, profile: profile))
        }
        saveRegisteredAccounts(accounts)

        hasCompletedOnboarding = true
        createAndPersistSession(for: profile)
        syncUserRecordAfterLogin(for: profile)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return (true, "Đăng nhập \(provider) thành công")
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

        var accounts = loadRegisteredAccounts()
        let cleanedNewPw = newPassword?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let idx = accounts.firstIndex(where: { $0.profile.email.lowercased() == oldEmail || $0.profile.email.lowercased() == updated.email.lowercased() }) {
            accounts[idx].profile = updated
            if !cleanedNewPw.isEmpty {
                accounts[idx].password = cleanedNewPw
            }
            saveRegisteredAccounts(accounts)
        } else if !cleanedNewPw.isEmpty {
            accounts.append(StoredAccount(password: cleanedNewPw, profile: updated))
            saveRegisteredAccounts(accounts)
        }
        pushCurrentUserToSupabase(mode: .profileOnly)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func logout() {
        clearSessionCookies()
        UserDefaults.standard.removeObject(forKey: authSessionStorageKey)
        UserDefaults.standard.removeObject(forKey: userProfileStorageKey)
        sessionId = ""
        sessionCookieToken = ""
        sessionCreatedAt = nil
        isLoggedIn = false
        userName = ""
        userTier = "Standard"
        currentUser = UserAccountProfile(
            fullName: "",
            email: "",
            phone: "",
            address: "",
            gimbalSerial: "TF-G31-PRO",
            memberSince: ""
        )
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
        pushCurrentUserToSupabase(mode: .modulesOnly)
    }

    func setTier(_ tier: String) {
        userTier = tier
        if tier == "Free Starter" || tier == "Basic Creator" {
            modules = [false, false, false, false, false, false, false]
        } else if tier == "Creator Pro" || tier == "Pro Cinema" {
            modules = [true, true, true, true, true, false, false]
        } else {
            modules = [true, true, true, true, true, true, true]
        }
        persistState()
        pushCurrentUserToSupabase(mode: .modulesOnly)
    }

    func updateDeviceTelemetry(deviceName: String? = nil, battery: Int? = nil, firmware: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let dev = deviceName?.trimmingCharacters(in: .whitespacesAndNewlines), !dev.isEmpty {
                self.deviceName = dev
            }
            if let bat = battery {
                self.deviceBattery = bat
            }
            if let fw = firmware?.trimmingCharacters(in: .whitespacesAndNewlines), !fw.isEmpty {
                self.deviceFirmware = fw
            }
            self.persistState()
            if self.isLoggedIn && !self.currentUser.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.pushCurrentUserToSupabase(mode: .telemetryOnly)
            }
        }
    }

    func syncWithCloud() {
        persistState()
        let cleanedEmail = currentUser.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let request = makeSupabaseRequest(
            endpoint: "/users",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "last_active.desc")
            ],
            method: "GET"
        ) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.isSyncing = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard error == nil,
                  let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let data = data,
                  let rows = try? JSONDecoder().decode([SupabaseUserRow].self, from: data) else {
                DispatchQueue.main.async {
                    self.isSyncing = false
                    self.isOnline = false
                }
                return
            }

            DispatchQueue.main.async {
                let realRows = rows.filter { row in
                    let rowId = row.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let rowEmail = (row.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return !Self.legacyFakeDemoIds.contains(rowId) && !Self.legacyFakeDemoEmails.contains(rowEmail)
                }
                self.cloudUsersCount = realRows.count
                self.mergeCloudRowsIntoLocalAccounts(realRows)

                var matchedCurrent = false
                if self.isLoggedIn && !cleanedEmail.isEmpty && self.activePushCount == 0 {
                    if let matchedRow = realRows.first(where: { ($0.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanedEmail }) {
                        matchedCurrent = true
                        self.applyCloudRowToCurrentState(matchedRow)
                    } else {
                        self.pushCurrentUserToSupabase(mode: .full)
                    }
                } else if !cleanedEmail.isEmpty && realRows.contains(where: { ($0.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanedEmail }) {
                    matchedCurrent = true
                }

                if matchedCurrent {
                    self.persistState()
                }
                self.isSyncing = (self.activePushCount > 0)
                self.isOnline = true
                self.lastSyncTime = self.formattedSyncTimestamp()
            }
        }.resume()
    }

    // MARK: - Private Supabase REST Sync Helpers

    private func makeSupabaseRequest(
        endpoint: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        prefer: String? = nil,
        bodyData: Data? = nil
    ) -> URLRequest? {
        guard var components = URLComponents(string: "\(supabaseRestURL)\(endpoint)") else {
            return nil
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 12
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer = prefer {
            req.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        req.httpBody = bodyData
        return req
    }

    private func makeStableCloudId(for email: String) -> String {
        let lower = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower == "thuynguyen2dk4@gmail.com" {
            return "thuy-nguyen"
        }
        let sanitized = lower.unicodeScalars.map { ch -> Character in
            CharacterSet.alphanumerics.contains(ch) ? Character(ch) : "-"
        }
        return "usr-" + String(sanitized)
    }

    private func normalizedModules(_ raw: [Bool]?, fallback: [Bool]) -> [Bool] {
        guard let raw = raw, !raw.isEmpty else {
            return fallback.count == 7 ? fallback : [false, false, false, false, false, false, false]
        }
        var out: [Bool] = []
        for idx in 0..<7 {
            if idx < raw.count {
                out.append(raw[idx])
            } else if idx < fallback.count {
                out.append(fallback[idx])
            } else {
                out.append(false)
            }
        }
        return out
    }

    private func applyCloudRowToCurrentState(_ row: SupabaseUserRow) {
        let resolvedName = (row.name?.isEmpty == false) ? row.name! : currentUser.fullName
        let resolvedEmail = (row.email?.isEmpty == false) ? row.email!.lowercased() : currentUser.email
        let resolvedPhone = row.phone ?? currentUser.phone
        let resolvedSerial = (row.serial?.isEmpty == false) ? row.serial!.uppercased() : currentUser.gimbalSerial
        let resolvedMember = (row.member_since?.isEmpty == false) ? row.member_since! : currentUser.memberSince

        currentUser = UserAccountProfile(
            fullName: resolvedName,
            email: resolvedEmail,
            phone: resolvedPhone,
            address: currentUser.address,
            gimbalSerial: resolvedSerial,
            memberSince: resolvedMember
        )
        userName = resolvedName
        if let tier = row.tier, !tier.isEmpty {
            userTier = tier
        }
        if let dev = row.device, !dev.isEmpty {
            deviceName = dev
        }
        if let bat = row.battery {
            deviceBattery = bat
        }
        if let fw = row.firmware, !fw.isEmpty {
            deviceFirmware = fw
        }
        if let cloudMods = row.modules, cloudMods.count == 7 {
            modules = cloudMods
        }
    }

    private func mergeCloudRowsIntoLocalAccounts(_ rows: [SupabaseUserRow]) {
        var accounts = loadRegisteredAccounts()
        for row in rows {
            let rowId = row.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !Self.legacyFakeDemoIds.contains(rowId),
                  let rawEmail = row.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !rawEmail.isEmpty,
                  !Self.legacyFakeDemoEmails.contains(rawEmail) else { continue }
            let existingIdx = accounts.firstIndex(where: { $0.profile.email.lowercased() == rawEmail })
            let existingProfile = existingIdx != nil ? accounts[existingIdx!].profile : nil
            let existingPassword = existingIdx != nil ? accounts[existingIdx!].password : "oauth_cloud_\(UUID().uuidString)"

            let mergedProfile = UserAccountProfile(
                fullName: (row.name?.isEmpty == false) ? row.name! : (existingProfile?.fullName ?? rawEmail),
                email: rawEmail,
                phone: row.phone ?? existingProfile?.phone ?? "",
                address: existingProfile?.address ?? currentUser.address,
                gimbalSerial: (row.serial?.isEmpty == false) ? row.serial!.uppercased() : (existingProfile?.gimbalSerial ?? "TF-G31-PRO"),
                memberSince: (row.member_since?.isEmpty == false) ? row.member_since! : (existingProfile?.memberSince ?? "11/2025")
            )

            if let idx = existingIdx {
                accounts[idx].profile = mergedProfile
            } else {
                accounts.append(StoredAccount(password: existingPassword, profile: mergedProfile))
            }
        }
        saveRegisteredAccounts(accounts)
    }

    private func syncUserRecordAfterLogin(for profile: UserAccountProfile) {
        let emailLower = profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !emailLower.isEmpty,
              let req = makeSupabaseRequest(
                endpoint: "/users",
                queryItems: [
                    URLQueryItem(name: "email", value: "eq.\(emailLower)"),
                    URLQueryItem(name: "select", value: "*")
                ],
                method: "GET"
              ) else {
            return
        }

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self = self else { return }
            guard error == nil,
                  let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let data = data,
                  let rows = try? JSONDecoder().decode([SupabaseUserRow].self, from: data) else {
                DispatchQueue.main.async {
                    self.isOnline = false
                }
                return
            }

            DispatchQueue.main.async {
                if let matched = rows.first {
                    self.applyCloudRowToCurrentState(matched)
                    self.persistState()
                    self.isOnline = true
                    self.lastSyncTime = self.formattedSyncTimestamp()
                    self.pushCurrentUserToSupabase(mode: .telemetryOnly)
                } else {
                    self.pushCurrentUserToSupabase(mode: .full)
                }
            }
        }.resume()
    }

    private func pushCurrentUserToSupabase(mode: SyncPayloadMode) {
        let profileSnapshot = currentUser
        let emailLower = profileSnapshot.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !emailLower.isEmpty else { return }

        let tierSnapshot = userTier
        let deviceSnapshot = deviceName.isEmpty ? "Smart Gimbal S1 Titanium" : deviceName
        let batterySnapshot = deviceBattery
        let firmwareSnapshot = deviceFirmware.isEmpty ? "v2.4.1" : deviceFirmware
        let modulesSnapshot = normalizedModules(modules, fallback: modules)
        let nowIso = ISO8601DateFormatter().string(from: Date())
        let isAdminEmail = ["thuynguyen2dk4@gmail.com", "thuy.nguyen@tflow.tech"].contains(emailLower)

        guard let lookupReq = makeSupabaseRequest(
            endpoint: "/users",
            queryItems: [
                URLQueryItem(name: "email", value: "eq.\(emailLower)"),
                URLQueryItem(name: "select", value: "id")
            ],
            method: "GET"
        ) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activePushCount += 1
            self.isSyncing = true
        }

        supabaseWriteQueue.async { [weak self] in
            guard let self = self else { return }
            let lookupSem = DispatchSemaphore(value: 0)
            var existingRows: [SupabaseUserRow] = []
            var lookupFailed = false

            URLSession.shared.dataTask(with: lookupReq) { data, _, error in
                defer { lookupSem.signal() }
                if error != nil {
                    lookupFailed = true
                    return
                }
                if let data = data {
                    existingRows = (try? JSONDecoder().decode([SupabaseUserRow].self, from: data)) ?? []
                }
            }.resume()

            _ = lookupSem.wait(timeout: .now() + 15)

            if lookupFailed {
                DispatchQueue.main.async {
                    self.activePushCount = max(0, self.activePushCount - 1)
                    self.isSyncing = (self.activePushCount > 0)
                    self.isOnline = false
                }
                return
            }

            let cloudId = existingRows.first?.id
            let encoder = JSONEncoder()
            var writeReq: URLRequest?

            if let cloudId = cloudId, !cloudId.isEmpty {
                let patchData: Data?
                switch mode {
                case .profileOnly:
                    patchData = try? encoder.encode(SupabaseProfilePatch(
                        name: profileSnapshot.fullName,
                        email: emailLower,
                        phone: profileSnapshot.phone,
                        serial: profileSnapshot.gimbalSerial,
                        last_active: nowIso
                    ))
                case .modulesOnly:
                    patchData = try? encoder.encode(SupabaseModulesPatch(
                        tier: tierSnapshot,
                        tier_badge: "\(tierSnapshot) Tier",
                        modules: modulesSnapshot,
                        last_active: nowIso
                    ))
                case .telemetryOnly:
                    patchData = try? encoder.encode(SupabaseTelemetryPatch(
                        device: deviceSnapshot,
                        battery: batterySnapshot,
                        firmware: firmwareSnapshot,
                        last_active: nowIso
                    ))
                case .full:
                    patchData = try? encoder.encode(SupabaseFullPayload(
                        id: cloudId,
                        name: profileSnapshot.fullName,
                        email: emailLower,
                        phone: profileSnapshot.phone,
                        device: deviceSnapshot,
                        tier: tierSnapshot,
                        tier_badge: isAdminEmail ? "Master Admin" : "\(tierSnapshot) Tier",
                        member_since: profileSnapshot.memberSince.isEmpty ? "11/2025" : profileSnapshot.memberSince,
                        serial: profileSnapshot.gimbalSerial,
                        warranty_days: 365,
                        battery: batterySnapshot,
                        firmware: firmwareSnapshot,
                        status: "Hoạt động",
                        modules: modulesSnapshot,
                        is_admin: isAdminEmail,
                        last_active: nowIso
                    ))
                }
                writeReq = self.makeSupabaseRequest(
                    endpoint: "/users",
                    queryItems: [URLQueryItem(name: "id", value: "eq.\(cloudId)")],
                    method: "PATCH",
                    prefer: "return=representation",
                    bodyData: patchData
                )
            } else {
                let insertPayload = SupabaseFullPayload(
                    id: self.makeStableCloudId(for: emailLower),
                    name: profileSnapshot.fullName,
                    email: emailLower,
                    phone: profileSnapshot.phone,
                    device: deviceSnapshot,
                    tier: tierSnapshot,
                    tier_badge: isAdminEmail ? "Master Admin" : "\(tierSnapshot) Tier",
                    member_since: profileSnapshot.memberSince.isEmpty ? "11/2025" : profileSnapshot.memberSince,
                    serial: profileSnapshot.gimbalSerial,
                    warranty_days: 365,
                    battery: batterySnapshot,
                    firmware: firmwareSnapshot,
                    status: "Hoạt động",
                    modules: modulesSnapshot,
                    is_admin: isAdminEmail,
                    last_active: nowIso
                )
                let insertData = try? encoder.encode(insertPayload)
                writeReq = self.makeSupabaseRequest(
                    endpoint: "/users",
                    queryItems: [URLQueryItem(name: "on_conflict", value: "id")],
                    method: "POST",
                    prefer: "resolution=merge-duplicates,return=representation",
                    bodyData: insertData
                )
            }

            guard let finalReq = writeReq else {
                DispatchQueue.main.async {
                    self.activePushCount = max(0, self.activePushCount - 1)
                    self.isSyncing = (self.activePushCount > 0)
                }
                return
            }

            let writeSem = DispatchSemaphore(value: 0)
            var writeSuccess = false

            URLSession.shared.dataTask(with: finalReq) { _, writeResp, writeErr in
                defer { writeSem.signal() }
                if writeErr == nil, let http = writeResp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    writeSuccess = true
                }
            }.resume()

            _ = writeSem.wait(timeout: .now() + 15)

            DispatchQueue.main.async {
                self.activePushCount = max(0, self.activePushCount - 1)
                self.isSyncing = (self.activePushCount > 0)
                if writeSuccess {
                    self.isOnline = true
                    self.lastSyncTime = self.formattedSyncTimestamp()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    self.isOnline = false
                }
            }
        }
    }

    private func formattedSyncTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
