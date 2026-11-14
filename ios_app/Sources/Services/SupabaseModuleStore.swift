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
import CryptoKit
import Security

private enum KeychainHelper {
    private static let service = "com.smartgimbal.s1pro.secure"

    static func save(data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func loadData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - =====================================================================
// 3. CLOUD SUPABASE MODULE & AUTH SESSION STORE
// =====================================================================

final class SupabaseModuleStore: ObservableObject {
    // Existing Cloud & 7-Module Permissions State (Preserved)
    @Published var userName: String = ""
    @Published var userTier: String = "Free Starter"
    @Published var deviceName: String = "Chưa kết nối thiết bị"
    @Published var deviceBattery: Int = 0
    @Published var deviceFirmware: String = ""
    @Published var cloudUsersCount: Int = 0
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: String = "Chưa đồng bộ"
    @Published var modules: [Bool] = [false, false, false, false, false, false, false]

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
        gimbalSerial: "",
        warrantyDays: 0,
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
        var passwordHash: String
        var profile: UserAccountProfile
    }

    static func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
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
        var address: String?
        var city: String?
        var district: String?
        var shipping_notes: String?
        var job_title: String?
        var camera_setup: String?
        var avatar_url: String?
        var auth_provider: String?
        var password_hash: String?
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
        var address: String
        var city: String
        var district: String
        var shipping_notes: String
        var job_title: String
        var camera_setup: String
        var avatar_url: String
        var auth_provider: String
        var password_hash: String?
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
        var address: String
        var city: String
        var district: String
        var shipping_notes: String
        var job_title: String
        var camera_setup: String
        var avatar_url: String
        var auth_provider: String
        var serial: String
        var warranty_days: Int
        var password_hash: String?
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
        if let savedDevice = defaults.string(forKey: deviceNameStorageKey),
           !savedDevice.isEmpty,
           savedDevice != "Smart Gimbal S1 Titanium" {
            deviceName = savedDevice
        } else {
            defaults.removeObject(forKey: deviceNameStorageKey)
            deviceName = "Chưa kết nối thiết bị"
        }
        if defaults.object(forKey: deviceBatteryStorageKey) != nil && deviceName != "Chưa kết nối thiết bị" {
            deviceBattery = defaults.integer(forKey: deviceBatteryStorageKey)
        } else {
            defaults.removeObject(forKey: deviceBatteryStorageKey)
            deviceBattery = 0
        }
        if let savedFw = defaults.string(forKey: deviceFirmwareStorageKey),
           !savedFw.isEmpty,
           deviceName != "Chưa kết nối thiết bị" {
            deviceFirmware = savedFw
        } else {
            defaults.removeObject(forKey: deviceFirmwareStorageKey)
            deviceFirmware = ""
        }

        // Migrate any legacy UserDefaults auth session into iOS Keychain
        if let legacySession = defaults.data(forKey: authSessionStorageKey) {
            if KeychainHelper.loadData(forKey: authSessionStorageKey) == nil {
                KeychainHelper.save(data: legacySession, forKey: authSessionStorageKey)
            }
            defaults.removeObject(forKey: authSessionStorageKey)
        }

        if let sessionData = KeychainHelper.loadData(forKey: authSessionStorageKey),
           let savedSession = try? JSONDecoder().decode(PersistedSession.self, from: sessionData),
           !savedSession.sessionCookieToken.isEmpty,
           !Self.legacyFakeDemoEmails.contains(savedSession.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
            if let profileData = defaults.data(forKey: userProfileStorageKey),
               var decodedProfile = try? JSONDecoder().decode(UserAccountProfile.self, from: profileData),
               !Self.legacyFakeDemoEmails.contains(decodedProfile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
                if decodedProfile.gimbalSerial == "TF-G31-PRO" && !decodedProfile.email.isEmpty && decodedProfile.warrantyDays == 0 {
                    decodedProfile.gimbalSerial = ""
                }
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
            KeychainHelper.delete(forKey: authSessionStorageKey)
            defaults.removeObject(forKey: authSessionStorageKey)
            defaults.removeObject(forKey: userProfileStorageKey)
            clearSessionCookies()
            isLoggedIn = false
            userName = ""
            userTier = "Free Starter"
            modules = [false, false, false, false, false, false, false]
            currentUser = UserAccountProfile(
                fullName: "",
                email: "",
                phone: "",
                address: "",
                gimbalSerial: "",
                warrantyDays: 0,
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
        if let legacyData = defaults.data(forKey: registeredAccountsStorageKey) {
            if KeychainHelper.loadData(forKey: registeredAccountsStorageKey) == nil {
                KeychainHelper.save(data: legacyData, forKey: registeredAccountsStorageKey)
            }
            defaults.removeObject(forKey: registeredAccountsStorageKey)
        }
        guard let data = KeychainHelper.loadData(forKey: registeredAccountsStorageKey),
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
            KeychainHelper.save(data: data, forKey: registeredAccountsStorageKey)
        }
        UserDefaults.standard.removeObject(forKey: registeredAccountsStorageKey)
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
            KeychainHelper.save(data: data, forKey: authSessionStorageKey)
        }
        UserDefaults.standard.removeObject(forKey: authSessionStorageKey)
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

    // MARK: - Authentication Actions (Cloud + Keychain SHA-256 Synchronized)

    private func profile(from row: SupabaseUserRow, fallback: UserAccountProfile? = nil) -> UserAccountProfile {
        let emailLower = (row.email ?? fallback?.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rowSerial = (row.serial ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let fallbackSerial = (fallback?.gimbalSerial ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanSerial = !rowSerial.isEmpty ? rowSerial : (fallbackSerial == "TF-G31-PRO" ? "" : fallbackSerial)
        return UserAccountProfile(
            fullName: (row.name?.isEmpty == false) ? row.name! : (fallback?.fullName ?? ""),
            email: emailLower,
            phone: (row.phone?.isEmpty == false) ? row.phone! : (fallback?.phone ?? ""),
            address: (row.address?.isEmpty == false) ? row.address! : (fallback?.address ?? ""),
            city: (row.city?.isEmpty == false) ? row.city! : (fallback?.city ?? ""),
            district: (row.district?.isEmpty == false) ? row.district! : (fallback?.district ?? ""),
            shippingNotes: (row.shipping_notes?.isEmpty == false) ? row.shipping_notes! : (fallback?.shippingNotes ?? ""),
            jobTitle: (row.job_title?.isEmpty == false) ? row.job_title! : (fallback?.jobTitle ?? ""),
            cameraSetup: (row.camera_setup?.isEmpty == false) ? row.camera_setup! : (fallback?.cameraSetup ?? ""),
            avatarUrl: (row.avatar_url?.isEmpty == false) ? row.avatar_url! : (fallback?.avatarUrl ?? ""),
            authProvider: (row.auth_provider?.isEmpty == false) ? row.auth_provider!.lowercased() : (fallback?.authProvider ?? "email"),
            passwordHash: (row.password_hash?.isEmpty == false) ? row.password_hash!.lowercased() : (fallback?.passwordHash ?? ""),
            gimbalSerial: cleanSerial,
            warrantyDays: row.warranty_days ?? fallback?.warrantyDays ?? (cleanSerial.isEmpty ? 0 : 365),
            memberSince: (row.member_since?.isEmpty == false) ? row.member_since! : (fallback?.memberSince ?? "")
        )
    }

    func login(identifier: String, password: String, completion: @escaping (Bool, String) -> Void) {
        let idTrimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let idLower = idTrimmed.lowercased()
        let pwTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !idTrimmed.isEmpty, !pwTrimmed.isEmpty else {
            completion(false, "Vui lòng nhập Email/SĐT và mật khẩu.")
            return
        }

        let pwHash = Self.sha256Hex(pwTrimmed)
        let normalizedPhoneInput = idTrimmed.replacingOccurrences(of: " ", with: "")

        // Query Supabase cloud first so Web-created/updated accounts always work identically on iOS
        if let req = makeSupabaseRequest(
            endpoint: "/users",
            queryItems: [URLQueryItem(name: "select", value: "*")],
            method: "GET"
        ) {
            URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
                guard let self = self else { return }
                if error == nil,
                   let http = response as? HTTPURLResponse,
                   (200...299).contains(http.statusCode),
                   let data = data,
                   let rows = try? JSONDecoder().decode([SupabaseUserRow].self, from: data) {
                    let matchedRow = rows.first { row in
                        let rowEmail = (row.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        let rowPhone = (row.phone ?? "").replacingOccurrences(of: " ", with: "")
                        return !rowEmail.isEmpty && (rowEmail == idLower || (!normalizedPhoneInput.isEmpty && rowPhone == normalizedPhoneInput))
                    }

                    if let matched = matchedRow {
                        let cloudHash = (matched.password_hash ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        let provider = (matched.auth_provider ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if cloudHash.isEmpty {
                            let msg = (provider == "google" || provider == "apple")
                                ? "Tài khoản này đăng nhập qua \(provider.capitalized). Vui lòng dùng nút Tiếp tục với \(provider.capitalized)."
                                : "Tài khoản chưa thiết lập mật khẩu. Vui lòng đăng nhập qua Google/Apple hoặc đặt lại mật khẩu."
                            DispatchQueue.main.async { completion(false, msg) }
                            return
                        }
                        if cloudHash != pwHash {
                            DispatchQueue.main.async { completion(false, "Email/SĐT hoặc mật khẩu chưa chính xác.") }
                            return
                        }

                        DispatchQueue.main.async {
                            let mergedProfile = self.profile(from: matched)
                            var accounts = self.loadRegisteredAccounts()
                            accounts.removeAll { $0.profile.email.lowercased() == mergedProfile.email.lowercased() }
                            accounts.append(StoredAccount(passwordHash: pwHash, profile: mergedProfile))
                            self.saveRegisteredAccounts(accounts)
                            self.applyCloudRowToCurrentState(matched)
                            self.createAndPersistSession(for: mergedProfile)
                            self.pushCurrentUserToSupabase(mode: .telemetryOnly)
                            completion(true, "Đăng nhập thành công")
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        completion(false, "Email/SĐT hoặc mật khẩu chưa chính xác.")
                    }
                    return
                }

                // Offline fallback via local iOS Keychain
                DispatchQueue.main.async {
                    let accounts = self.loadRegisteredAccounts()
                    if let matched = accounts.first(where: { acc in
                        let accPhone = acc.profile.phone.replacingOccurrences(of: " ", with: "")
                        return (acc.profile.email.lowercased() == idLower || (!normalizedPhoneInput.isEmpty && accPhone == normalizedPhoneInput))
                            && acc.passwordHash.lowercased() == pwHash
                    }) {
                        self.createAndPersistSession(for: matched.profile)
                        self.syncUserRecordAfterLogin(for: matched.profile)
                        completion(true, "Đăng nhập thành công (Offline)")
                    } else {
                        completion(false, "Không thể xác thực tài khoản. Kiểm tra kết nối mạng hoặc thông tin đăng nhập.")
                    }
                }
            }.resume()
            return
        }

        completion(false, "Không thể tạo yêu cầu đăng nhập.")
    }

    func register(
        fullName: String,
        email: String,
        phone: String,
        password: String,
        gimbalSerial: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSerial = gimbalSerial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !cleanName.isEmpty else {
            completion(false, "Vui lòng nhập họ và tên.")
            return
        }
        guard cleanEmail.contains("@") && cleanEmail.contains("."), !Self.legacyFakeDemoEmails.contains(cleanEmail) else {
            completion(false, "Email không hợp lệ.")
            return
        }
        guard cleanPassword.count >= 6 else {
            completion(false, "Mật khẩu cần tối thiểu 6 ký tự.")
            return
        }

        let pwHash = Self.sha256Hex(cleanPassword)

        guard let checkReq = makeSupabaseRequest(
            endpoint: "/users",
            queryItems: [
                URLQueryItem(name: "email", value: "eq.\(cleanEmail)"),
                URLQueryItem(name: "select", value: "id,email")
            ],
            method: "GET"
        ) else {
            completion(false, "Không thể kết nối máy chủ đăng ký.")
            return
        }

        URLSession.shared.dataTask(with: checkReq) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Lỗi kết nối mạng: \(error.localizedDescription)")
                }
                return
            }
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let data = data,
               let existing = try? JSONDecoder().decode([SupabaseUserRow].self, from: data),
               !existing.isEmpty {
                DispatchQueue.main.async {
                    completion(false, "Email này đã được đăng ký. Vui lòng chuyển sang tab Đăng nhập.")
                }
                return
            }

            DispatchQueue.main.async {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/yyyy"
                let profile = UserAccountProfile(
                    fullName: cleanName,
                    email: cleanEmail,
                    phone: cleanPhone,
                    address: "",
                    authProvider: "email",
                    passwordHash: pwHash,
                    gimbalSerial: cleanSerial,
                    warrantyDays: cleanSerial.isEmpty ? 0 : 365,
                    memberSince: formatter.string(from: Date())
                )

                var accounts = self.loadRegisteredAccounts()
                accounts.removeAll { $0.profile.email.lowercased() == cleanEmail }
                accounts.append(StoredAccount(passwordHash: pwHash, profile: profile))
                self.saveRegisteredAccounts(accounts)

                self.userTier = "Free Starter"
                self.modules = [false, false, false, false, false, false, false]
                self.deviceName = "Chưa kết nối thiết bị"
                self.deviceBattery = 0
                self.deviceFirmware = ""

                self.createAndPersistSession(for: profile)
                self.pushCurrentUserToSupabase(mode: .full)
                completion(true, "Đăng ký tài khoản thành công")
            }
        }.resume()
    }

    func signInWithOAuthAccount(
        email: String,
        fullName: String,
        provider: String,
        avatarUrl: String = "",
        completion: @escaping (Bool, String) -> Void
    ) {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanEmail.contains("@"),
              cleanEmail.contains("."),
              !Self.legacyFakeDemoEmails.contains(cleanEmail) else {
            completion(false, "Không nhận được địa chỉ email \(provider) hợp lệ.")
            return
        }

        let cleanedInputName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let providerLower = provider.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let req = makeSupabaseRequest(
            endpoint: "/users",
            queryItems: [
                URLQueryItem(name: "email", value: "eq.\(cleanEmail)"),
                URLQueryItem(name: "select", value: "*")
            ],
            method: "GET"
        ) else {
            completion(false, "Không thể tạo kết nối đồng bộ \(provider).")
            return
        }

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self = self else { return }
            let existingCloudRow: SupabaseUserRow? = {
                guard error == nil,
                      let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      let data = data,
                      let rows = try? JSONDecoder().decode([SupabaseUserRow].self, from: data) else {
                    return nil
                }
                return rows.first
            }()

            DispatchQueue.main.async {
                var accounts = self.loadRegisteredAccounts()
                let existingIdx = accounts.firstIndex { $0.profile.email.lowercased() == cleanEmail }
                let existingProfile = existingIdx.map { accounts[$0].profile }

                let merged: UserAccountProfile
                if let cloud = existingCloudRow {
                    self.applyCloudRowToCurrentState(cloud)
                    var base = self.profile(from: cloud, fallback: existingProfile)
                    if base.fullName.isEmpty && !cleanedInputName.isEmpty {
                        base.fullName = cleanedInputName
                    }
                    if base.avatarUrl.isEmpty && !avatarUrl.isEmpty {
                        base.avatarUrl = avatarUrl
                    }
                    if base.authProvider.isEmpty || base.authProvider == "email" {
                        base.authProvider = providerLower
                    }
                    merged = base
                } else {
                    let fallbackLocalName = cleanEmail.components(separatedBy: "@").first?
                        .replacingOccurrences(of: ".", with: " ")
                        .capitalized ?? cleanEmail
                    let resolvedName = !cleanedInputName.isEmpty
                        ? cleanedInputName
                        : ((existingProfile?.fullName.isEmpty == false) ? existingProfile!.fullName : fallbackLocalName)

                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/yyyy"
                    merged = UserAccountProfile(
                        fullName: resolvedName,
                        email: cleanEmail,
                        phone: existingProfile?.phone ?? "",
                        address: existingProfile?.address ?? "",
                        city: existingProfile?.city ?? "",
                        district: existingProfile?.district ?? "",
                        shippingNotes: existingProfile?.shippingNotes ?? "",
                        jobTitle: existingProfile?.jobTitle ?? "",
                        cameraSetup: existingProfile?.cameraSetup ?? "",
                        avatarUrl: !avatarUrl.isEmpty ? avatarUrl : (existingProfile?.avatarUrl ?? ""),
                        authProvider: providerLower,
                        passwordHash: existingProfile?.passwordHash ?? "",
                        gimbalSerial: existingProfile?.gimbalSerial == "TF-G31-PRO" ? "" : (existingProfile?.gimbalSerial ?? ""),
                        warrantyDays: existingProfile?.warrantyDays ?? 0,
                        memberSince: (existingProfile?.memberSince.isEmpty == false)
                            ? existingProfile!.memberSince
                            : formatter.string(from: Date())
                    )
                    self.userTier = "Free Starter"
                    self.modules = [false, false, false, false, false, false, false]
                    self.deviceName = "Chưa kết nối thiết bị"
                    self.deviceBattery = 0
                    self.deviceFirmware = ""
                }

                let credentialHash = !merged.passwordHash.isEmpty
                    ? merged.passwordHash
                    : "oauth_\(providerLower)_\(UUID().uuidString)"

                if let idx = existingIdx {
                    accounts[idx].profile = merged
                    if !merged.passwordHash.isEmpty {
                        accounts[idx].passwordHash = merged.passwordHash
                    }
                } else {
                    accounts.append(StoredAccount(passwordHash: credentialHash, profile: merged))
                }
                self.saveRegisteredAccounts(accounts)

                self.hasCompletedOnboarding = true
                self.createAndPersistSession(for: merged)
                self.pushCurrentUserToSupabase(mode: existingCloudRow != nil ? .profileOnly : .full)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                completion(true, "Đăng nhập \(provider) thành công")
            }
        }.resume()
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
            KeychainHelper.save(data: data, forKey: authSessionStorageKey)
        }
        UserDefaults.standard.removeObject(forKey: authSessionStorageKey)
        writeSessionCookie(token: newToken)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func updatePersonalProfile(
        fullName: String,
        email: String,
        phone: String,
        address: String,
        city: String? = nil,
        district: String? = nil,
        shippingNotes: String? = nil,
        jobTitle: String? = nil,
        cameraSetup: String? = nil,
        gimbalSerial: String,
        newPassword: String? = nil
    ) {
        let cleanSerial = gimbalSerial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanedNewPw = newPassword?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let nextHash = cleanedNewPw.count >= 6 ? Self.sha256Hex(cleanedNewPw) : currentUser.passwordHash

        let updated = UserAccountProfile(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? currentUser.fullName : fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? currentUser.email : email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentUser.city,
            district: district?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentUser.district,
            shippingNotes: shippingNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentUser.shippingNotes,
            jobTitle: jobTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentUser.jobTitle,
            cameraSetup: cameraSetup?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentUser.cameraSetup,
            avatarUrl: currentUser.avatarUrl,
            authProvider: currentUser.authProvider.isEmpty ? "email" : currentUser.authProvider,
            passwordHash: nextHash,
            gimbalSerial: cleanSerial,
            warrantyDays: cleanSerial.isEmpty ? 0 : max(currentUser.warrantyDays, 365),
            memberSince: currentUser.memberSince
        )

        let oldEmail = currentUser.email.lowercased()
        currentUser = updated
        userName = updated.fullName
        persistState()

        var accounts = loadRegisteredAccounts()
        if let idx = accounts.firstIndex(where: { $0.profile.email.lowercased() == oldEmail || $0.profile.email.lowercased() == updated.email.lowercased() }) {
            accounts[idx].profile = updated
            if !nextHash.isEmpty {
                accounts[idx].passwordHash = nextHash
            }
            saveRegisteredAccounts(accounts)
        } else if !updated.email.isEmpty {
            accounts.append(StoredAccount(passwordHash: nextHash, profile: updated))
            saveRegisteredAccounts(accounts)
        }
        pushCurrentUserToSupabase(mode: .profileOnly)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func deleteCurrentAccount(completion: @escaping (Bool, String) -> Void) {
        let emailLower = currentUser.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var accounts = loadRegisteredAccounts()
        accounts.removeAll { $0.profile.email.lowercased() == emailLower }
        saveRegisteredAccounts(accounts)

        guard !emailLower.isEmpty,
              let req = makeSupabaseRequest(
                endpoint: "/users",
                queryItems: [URLQueryItem(name: "email", value: "eq.\(emailLower)")],
                method: "DELETE"
              ) else {
            DispatchQueue.main.async {
                self.logout()
                completion(true, "Đã xóa dữ liệu tài khoản cục bộ")
            }
            return
        }

        URLSession.shared.dataTask(with: req) { [weak self] _, response, error in
            DispatchQueue.main.async {
                self?.logout()
                if error == nil, let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    completion(true, "Đã xóa tài khoản hoàn toàn khỏi Cloud và thiết bị")
                } else {
                    completion(true, "Đã xóa phiên đăng nhập trên thiết bị")
                }
            }
        }.resume()
    }

    func logout() {
        clearSessionCookies()
        KeychainHelper.delete(forKey: authSessionStorageKey)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: authSessionStorageKey)
        defaults.removeObject(forKey: userProfileStorageKey)
        defaults.removeObject(forKey: tierStorageKey)
        defaults.removeObject(forKey: modulesStorageKey)
        defaults.removeObject(forKey: deviceNameStorageKey)
        defaults.removeObject(forKey: deviceBatteryStorageKey)
        defaults.removeObject(forKey: deviceFirmwareStorageKey)
        sessionId = ""
        sessionCookieToken = ""
        sessionCreatedAt = nil
        isLoggedIn = false
        userName = ""
        userTier = "Free Starter"
        modules = [false, false, false, false, false, false, false]
        deviceName = "Chưa kết nối thiết bị"
        deviceBattery = 0
        deviceFirmware = ""
        currentUser = UserAccountProfile(
            fullName: "",
            email: "",
            phone: "",
            address: "",
            gimbalSerial: "",
            warrantyDays: 0,
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
                    let rowId = (row.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
        let merged = profile(from: row, fallback: currentUser)
        currentUser = merged
        userName = merged.fullName
        if let tier = row.tier, !tier.isEmpty {
            userTier = tier
        }
        if let dev = row.device, !dev.isEmpty, dev != "Smart Gimbal S1 Titanium" {
            deviceName = dev
        }
        if let bat = row.battery {
            deviceBattery = bat
        }
        if let fw = row.firmware {
            deviceFirmware = fw
        }
        if let cloudMods = row.modules, cloudMods.count == 7 {
            modules = cloudMods
        }
    }

    private func mergeCloudRowsIntoLocalAccounts(_ rows: [SupabaseUserRow]) {
        var accounts = loadRegisteredAccounts()
        for row in rows {
            let rowId = (row.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !Self.legacyFakeDemoIds.contains(rowId),
                  let rawEmail = row.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !rawEmail.isEmpty,
                  !Self.legacyFakeDemoEmails.contains(rawEmail) else { continue }
            let existingIdx = accounts.firstIndex(where: { $0.profile.email.lowercased() == rawEmail })
            let existingProfile = existingIdx != nil ? accounts[existingIdx!].profile : nil
            let cloudHash = (row.password_hash ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let existingHash = !cloudHash.isEmpty
                ? cloudHash
                : (existingIdx != nil ? accounts[existingIdx!].passwordHash : "oauth_cloud_\(UUID().uuidString)")

            let mergedProfile = profile(from: row, fallback: existingProfile)

            if let idx = existingIdx {
                accounts[idx].profile = mergedProfile
                if !cloudHash.isEmpty {
                    accounts[idx].passwordHash = cloudHash
                }
            } else {
                accounts.append(StoredAccount(passwordHash: existingHash, profile: mergedProfile))
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

    private func finishPush(writeSuccess: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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

    private func pushCurrentUserToSupabase(mode: SyncPayloadMode) {
        let profileSnapshot = currentUser
        let emailLower = profileSnapshot.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !emailLower.isEmpty else { return }

        let tierSnapshot = userTier
        let deviceSnapshot = deviceName.isEmpty ? "Chưa kết nối thiết bị" : deviceName
        let batterySnapshot = deviceBattery
        let firmwareSnapshot = deviceFirmware
        let warrantySnapshot = profileSnapshot.gimbalSerial.isEmpty ? 0 : max(profileSnapshot.warrantyDays, 365)
        let passwordHashSnapshot: String? = profileSnapshot.passwordHash.isEmpty ? nil : profileSnapshot.passwordHash.lowercased()
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

        URLSession.shared.dataTask(with: lookupReq) { [weak self] data, _, error in
            guard let self = self else { return }
            if error != nil {
                self.finishPush(writeSuccess: false)
                return
            }

            let existingRows: [SupabaseUserRow] = data.flatMap { try? JSONDecoder().decode([SupabaseUserRow].self, from: $0) } ?? []
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
                        address: profileSnapshot.address,
                        city: profileSnapshot.city,
                        district: profileSnapshot.district,
                        shipping_notes: profileSnapshot.shippingNotes,
                        job_title: profileSnapshot.jobTitle,
                        camera_setup: profileSnapshot.cameraSetup,
                        avatar_url: profileSnapshot.avatarUrl,
                        auth_provider: profileSnapshot.authProvider.isEmpty ? "email" : profileSnapshot.authProvider,
                        serial: profileSnapshot.gimbalSerial,
                        warranty_days: warrantySnapshot,
                        password_hash: passwordHashSnapshot,
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
                    let memberSinceValue = profileSnapshot.memberSince.isEmpty ? "11/2025" : profileSnapshot.memberSince
                    patchData = try? encoder.encode(SupabaseFullPayload(
                        id: cloudId,
                        name: profileSnapshot.fullName,
                        email: emailLower,
                        phone: profileSnapshot.phone,
                        address: profileSnapshot.address,
                        city: profileSnapshot.city,
                        district: profileSnapshot.district,
                        shipping_notes: profileSnapshot.shippingNotes,
                        job_title: profileSnapshot.jobTitle,
                        camera_setup: profileSnapshot.cameraSetup,
                        avatar_url: profileSnapshot.avatarUrl,
                        auth_provider: profileSnapshot.authProvider.isEmpty ? "email" : profileSnapshot.authProvider,
                        password_hash: passwordHashSnapshot,
                        device: deviceSnapshot,
                        tier: tierSnapshot,
                        tier_badge: isAdminEmail ? "Master Admin" : "\(tierSnapshot) Tier",
                        member_since: memberSinceValue,
                        serial: profileSnapshot.gimbalSerial,
                        warranty_days: warrantySnapshot,
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
                let memberSinceValue = profileSnapshot.memberSince.isEmpty ? "11/2025" : profileSnapshot.memberSince
                let insertPayload = SupabaseFullPayload(
                    id: self.makeStableCloudId(for: emailLower),
                    name: profileSnapshot.fullName,
                    email: emailLower,
                    phone: profileSnapshot.phone,
                    address: profileSnapshot.address,
                    city: profileSnapshot.city,
                    district: profileSnapshot.district,
                    shipping_notes: profileSnapshot.shippingNotes,
                    job_title: profileSnapshot.jobTitle,
                    camera_setup: profileSnapshot.cameraSetup,
                    avatar_url: profileSnapshot.avatarUrl,
                    auth_provider: profileSnapshot.authProvider.isEmpty ? "email" : profileSnapshot.authProvider,
                    password_hash: passwordHashSnapshot,
                    device: deviceSnapshot,
                    tier: tierSnapshot,
                    tier_badge: isAdminEmail ? "Master Admin" : "\(tierSnapshot) Tier",
                    member_since: memberSinceValue,
                    serial: profileSnapshot.gimbalSerial,
                    warranty_days: warrantySnapshot,
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
                self.finishPush(writeSuccess: false)
                return
            }

            URLSession.shared.dataTask(with: finalReq) { [weak self] _, writeResp, writeErr in
                let writeSuccess = (writeErr == nil) && ((writeResp as? HTTPURLResponse).map { (200...299).contains($0.statusCode) } ?? false)
                self?.finishPush(writeSuccess: writeSuccess)
            }.resume()
        }.resume()
    }

    private func formattedSyncTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
