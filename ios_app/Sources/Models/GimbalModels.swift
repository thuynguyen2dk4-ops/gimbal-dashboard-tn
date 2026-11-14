//
//  GimbalModels.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import Foundation
import UIKit

// MARK: - =====================================================================
// 2. CAPTURED MEDIA, AI TARGET & USER PROFILE MODELS
// =====================================================================

struct CapturedMediaItem: Identifiable {
    var id: UUID = UUID()
    let image: UIImage
    let isVideo: Bool
    let duration: String?
    var timestamp: Date = Date()
    let resolution: String
    let profile: String
    var fileName: String = ""
    var fileSizeBytes: Int64 = 0
    var videoURL: URL? = nil
    var localIdentifier: String? = nil
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

struct ModuleDetailItem: Identifiable {
    var id: Int { index }
    let index: Int
    let title: String
    let icon: String
    let desc: String
}

enum AITargetMode: String, CaseIterable, Identifiable {
    case human = "Người"
    case pet = "Thú cưng"
    case object = "Vật thể"

    var id: String { rawValue }
}

struct UserAccountProfile: Codable, Equatable {
    var fullName: String
    var email: String
    var phone: String
    var address: String
    var city: String = ""
    var district: String = ""
    var shippingNotes: String = ""
    var jobTitle: String = ""
    var cameraSetup: String = ""
    var avatarUrl: String = ""
    var authProvider: String = "email"
    var passwordHash: String = ""
    var gimbalSerial: String
    var warrantyDays: Int = 0
    var memberSince: String

    init(
        fullName: String,
        email: String,
        phone: String,
        address: String,
        city: String = "",
        district: String = "",
        shippingNotes: String = "",
        jobTitle: String = "",
        cameraSetup: String = "",
        avatarUrl: String = "",
        authProvider: String = "email",
        passwordHash: String = "",
        gimbalSerial: String,
        warrantyDays: Int = 0,
        memberSince: String
    ) {
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.address = address
        self.city = city
        self.district = district
        self.shippingNotes = shippingNotes
        self.jobTitle = jobTitle
        self.cameraSetup = cameraSetup
        self.avatarUrl = avatarUrl
        self.authProvider = authProvider
        self.passwordHash = passwordHash
        self.gimbalSerial = gimbalSerial
        self.warrantyDays = warrantyDays
        self.memberSince = memberSince
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        city = try c.decodeIfPresent(String.self, forKey: .city) ?? ""
        district = try c.decodeIfPresent(String.self, forKey: .district) ?? ""
        shippingNotes = try c.decodeIfPresent(String.self, forKey: .shippingNotes) ?? ""
        jobTitle = try c.decodeIfPresent(String.self, forKey: .jobTitle) ?? ""
        cameraSetup = try c.decodeIfPresent(String.self, forKey: .cameraSetup) ?? ""
        avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl) ?? ""
        authProvider = try c.decodeIfPresent(String.self, forKey: .authProvider) ?? "email"
        passwordHash = try c.decodeIfPresent(String.self, forKey: .passwordHash) ?? ""
        gimbalSerial = try c.decodeIfPresent(String.self, forKey: .gimbalSerial) ?? ""
        warrantyDays = try c.decodeIfPresent(Int.self, forKey: .warrantyDays) ?? 0
        memberSince = try c.decodeIfPresent(String.self, forKey: .memberSince) ?? ""
    }

    var avatarInitials: String {
        let parts = fullName
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        if parts.count >= 2, let first = parts.first?.first, let last = parts.last?.first {
            return String([first, last]).uppercased()
        }
        if let first = parts.first?.prefix(2) {
            return String(first).uppercased()
        }
        return "TF"
    }
}
