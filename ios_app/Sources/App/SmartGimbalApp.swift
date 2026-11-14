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

    private var resolvedColorScheme: ColorScheme? {
        switch camera.uiThemeMode {
        case "light": return .light
        case "auto": return nil
        default: return .dark
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabShellView()
                .environmentObject(store)
                .environmentObject(ble)
                .environmentObject(camera)
                .preferredColorScheme(resolvedColorScheme)
        }
    }
}
