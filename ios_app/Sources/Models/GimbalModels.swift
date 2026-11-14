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
    var gimbalSerial: String
    var memberSince: String

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
