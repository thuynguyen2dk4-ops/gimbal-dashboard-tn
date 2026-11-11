//
//  SupabaseModuleStore.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import Combine
import UIKit

// MARK: - =====================================================================
// 3. CLOUD SUPABASE MODULE STORE
// =====================================================================

final class SupabaseModuleStore: ObservableObject {
    @Published var userName: String = "Thủy Nguyễn (Founder)"
    @Published var userTier: String = "VIP LIFETIME"
    @Published var deviceName: String = "Smart Gimbal S1 Titanium"
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: String = "Vừa xong"
    @Published var modules: [Bool] = [true, true, true, true, true, true, true]

    private let tierStorageKey = "tflow_user_tier_v1"
    private let modulesStorageKey = "tflow_user_modules_v1"

    init() {
        loadPersistedState()
    }

    private func loadPersistedState() {
        let defaults = UserDefaults.standard
        if let savedTier = defaults.string(forKey: tierStorageKey), !savedTier.isEmpty {
            userTier = savedTier
        }
        if let savedModules = defaults.array(forKey: modulesStorageKey) as? [Bool], savedModules.count == 7 {
            modules = savedModules
        }
    }

    private func persistState() {
        let defaults = UserDefaults.standard
        defaults.set(userTier, forKey: tierStorageKey)
        defaults.set(modules, forKey: modulesStorageKey)
    }

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
