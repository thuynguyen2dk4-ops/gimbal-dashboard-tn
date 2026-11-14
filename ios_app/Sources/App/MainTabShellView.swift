//
//  MainTabShellView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 7. MAIN TAB NAVIGATION SHELL (FIGMA 4 TABS)
// =====================================================================

struct MainTabShellView: View {
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 0

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
        TabView(selection: $selectedTab) {
            CameraStudioNativeView()
                .tabItem {
                    Label("Camera AI", systemImage: "viewfinder")
                }
                .tag(0)

            GimbalDeviceHubView()
                .tabItem {
                    Label("T-Flow Pro", systemImage: "gyroscope")
                }
                .tag(1)

            TFlowAIChatAssistantView()
                .tabItem {
                    Label("T-Flow Bot", systemImage: "sparkles")
                }
                .tag(2)

            UserProfilePermissionsView()
                .tabItem {
                    Label("Tài Khoản", systemImage: "person.crop.circle.fill")
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
    }
}
