//
//  GimbalModels.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import Foundation
import UIKit

// MARK: - =====================================================================
// 2. CAPTURED MEDIA MODEL & DATA STORE
// =====================================================================

struct CapturedMediaItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let isVideo: Bool
    let duration: String?
    let timestamp: Date = Date()
    let resolution: String
    let profile: String
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
