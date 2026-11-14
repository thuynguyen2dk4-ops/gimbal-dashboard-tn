//
//  UserProfilePermissionsView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Hồ sơ VIP Studio & Ma trận 7 Module (14_Profile_VIP_Studio).
//

import SwiftUI

struct UserProfilePermissionsView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @State private var selectedModule: ModuleDetailItem? = nil
    @State private var showPaywall: Bool = false

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)

    private let moduleCatalog: [(title: String, icon: String, desc: String)] = [
        ("AI Vision Tracking", "viewfinder", "Khóa nét khuôn mặt 60fps"),
        ("4K 60fps Apple Log", "film.fill", "Quay màu phẳng Cinema 10-bit"),
        ("Motionlapse Waypoint", "timelapse", "Lập trình điểm trượt tự động"),
        ("Multi-Cam Studio", "rectangle.grid.2x2.fill", "Đồng bộ 4 góc máy Wi-Fi"),
        ("Cinema 3D LUTs", "camera.filters", "Áp màu điện ảnh thời gian thực"),
        ("FOC Micro-Tuning", "slider.horizontal.3", "Chỉnh mô-men động cơ 3 trục"),
        ("Raw Sensor Telemetry", "waveform.path.ecg", "Thông số góc IMU trực tiếp")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeaderCard
                    tierUpgradeBanner
                    moduleMatrixSection
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tài Khoản Studio")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedModule) { item in
                ModuleDetailInspectorSheet(detail: item, store: store)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallSheetView(store: store)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var profileHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(goldAccent.opacity(0.18))
                    .frame(width: 54, height: 54)
                Text(String(store.userName.prefix(1)).uppercased())
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(goldAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(store.userName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text(store.userTier)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(goldAccent)
                        .clipShape(Capsule())

                    Text(store.isOnline ? "Cloud Online" : "Offline")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(store.isOnline ? .green : .secondary)
                }

                Text("Đồng bộ: \(store.lastSyncTime)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                store.syncWithCloud()
            } label: {
                if store.isSyncing {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(appleBlue)
                        .frame(width: 36, height: 36)
                        .background(appleBlue.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    private var tierUpgradeBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundColor(goldAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nâng Cấp Gói Studio")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Mở khóa 7 tính năng Pro")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Xem gói")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(appleBlue)
                    .cornerRadius(9)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }

    private var moduleMatrixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MA TRẬN 7 MODULE PHẦN MỀM")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(0..<moduleCatalog.count, id: \.self) { index in
                    let meta = moduleCatalog[index]
                    let isEnabled = store.modules.indices.contains(index) ? store.modules[index] : false

                    Button {
                        selectedModule = ModuleDetailItem(
                            index: index,
                            title: meta.title,
                            icon: meta.icon,
                            desc: meta.desc
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: meta.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(isEnabled ? goldAccent : .secondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(meta.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(meta.desc)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { store.modules.indices.contains(index) ? store.modules[index] : false },
                                set: { _ in store.toggleModule(at: index) }
                            ))
                            .labelsHidden()
                            .tint(appleBlue)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)

                    if index < moduleCatalog.count - 1 {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))
        }
    }
}
