//
//  SmartGimbalApp.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

// MARK: - =====================================================================
// 6. MAIN APPLICATION ENTRY POINT & STATE PROVIDERS
// =====================================================================

@main
struct SmartGimbalApp: App {
    @StateObject private var store = SupabaseModuleStore()
    @StateObject private var ble = BLEGimbalManager()
    @StateObject private var camera = CameraService()

    var body: some Scene {
        WindowGroup {
            MainTabShellView()
                .environmentObject(store)
                .environmentObject(ble)
                .environmentObject(camera)
                .preferredColorScheme(.dark)
        }
    }
}
