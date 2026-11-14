//
//  MainTabShellView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 7. MAIN TAB NAVIGATION SHELL (FIGMA NODE 96:3 — 4 TABS + AUTH GATE)
// =====================================================================

struct MainTabShellView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 0.96)
                : UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 0.98)
        }
        appearance.shadowColor = UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor.black.withAlphaComponent(0.08)
                : UIColor.white.withAlphaComponent(0.08)
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        Group {
            if !store.isLoggedIn && !store.isGuestMode {
                AuthSignInGateView()
            } else {
                TabView(selection: $store.activeMainTab) {
                    CameraStudioNativeView()
                        .tabItem {
                            Label("Quay", systemImage: "camera.fill")
                        }
                        .tag(0)

                    MediaGallerySheetView(camera: camera, isEmbeddedTab: true)
                        .tabItem {
                            Label("Thư viện", systemImage: "photo.on.rectangle.angled")
                        }
                        .tag(1)

                    GimbalDeviceHubView()
                        .tabItem {
                            Label("Thiết bị", systemImage: "cpu")
                        }
                        .tag(2)

                    UserProfilePermissionsView()
                        .tabItem {
                            Label("Hồ sơ", systemImage: "person.crop.circle.fill")
                        }
                        .tag(3)
                }
                .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
                .toolbarBackground(
                    colorScheme == .light
                        ? Color(red: 0.97, green: 0.98, blue: 0.99).opacity(0.96)
                        : Color(red: 0.05, green: 0.05, blue: 0.07).opacity(0.98),
                    for: .tabBar
                )
                .toolbarBackground(.visible, for: .tabBar)
                .sheet(isPresented: $store.showPairingModal) {
                    BLEPairingScanSheetView()
                }
                .sheet(isPresented: $store.showPermissionsModal) {
                    SystemPermissionsSheetView()
                }
                .sheet(isPresented: $store.showSignInSheet) {
                    AuthSignInGateView()
                }
                .sheet(isPresented: $store.showAiCopilotSheet) {
                    TFlowAIChatAssistantView()
                }
            }
        }
    }
}
