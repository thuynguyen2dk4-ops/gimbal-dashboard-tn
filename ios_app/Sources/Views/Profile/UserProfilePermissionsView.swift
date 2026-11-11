//
//  UserProfilePermissionsView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 17. TAB 4: USER PROFILE & PERMISSIONS VIEW (SCREEN 35 & 42)
// =====================================================================

struct UserProfilePermissionsView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @State private var showPaywallSheet: Bool = false
    @State private var selectedModuleIndex: Int? = nil

    let moduleTitles = [
        ("AI Vision Optical Tracking", "camera.metering.spot", "Bám nét khuôn mặt & vật thể 60fps"),
        ("Apple Log & ProRes 4K/60fps", "film.stack", "Không gian màu 10-bit Rec.2020"),
        ("Motionlapse Waypoint 5-Point", "point.topleft.down.curvedto.point.bottomright.up", "Lập trình đường bay gimbal 5 điểm"),
        ("Multi-Cam Director Studio", "rectangle.split.2x2", "Đồng bộ đa góc máy qua Wi-Fi/BLE"),
        ("3D LUT Real-time Preview", "slider.horizontal.3", "Áp màu trực tiếp Rec.709 & Teal Orange"),
        ("FOC Motor Micro-Tuning", "waveform.path.ecg", "Xung PWM 20kHz & Lọc Notch 245Hz"),
        ("500Hz Gyro Raw Telemetry", "location.north.circle", "Xuất dữ liệu góc quay IMU thời gian thực")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // TITANIUM VIP MEMBERSHIP CARD
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            HStack(spacing: 10) {
                                TFlowBrandLogo(size: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.userName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(store.userTier)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                }
                            }
                            Spacer()
                            Button(action: {
                                showPaywallSheet = true
                            }) {
                                Text("ĐỔI GÓI")
                                    .font(.system(size: 10, weight: .black))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.18))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }

                        Divider().background(Color.white.opacity(0.12))

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("THIẾT BỊ ĐĂNG KÝ").font(.system(size: 9.5, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text(store.deviceName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: {
                                store.syncWithCloud()
                            }) {
                                HStack(spacing: 5) {
                                    Circle().fill(store.isOnline ? Color.green : Color.red).frame(width: 6, height: 6)
                                    Text(store.isSyncing ? "Đang đồng bộ..." : "Supabase Live")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(store.isOnline ? .green : .red)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.15, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.16), lineWidth: 1))

                    // 7-MODULE INSET GROUPED LIST
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("TRẠNG THÁI 7 MODULE ĐỒNG BỘ TỪ WEB ADMIN CMS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("Cập nhật: \(store.lastSyncTime)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(0..<moduleTitles.count, id: \.self) { idx in
                                let item = moduleTitles[idx]
                                let isEnabled = store.modules.indices.contains(idx) ? store.modules[idx] : true

                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedModuleIndex = idx
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: item.1)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("\(idx + 1). \(item.0)")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white)
                                            Text(item.2)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        Text(isEnabled ? "ĐÃ MỞ KHÓA" : "ĐÃ KHÓA")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(isEnabled ? .green : .red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background((isEnabled ? Color.green : Color.red).opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 16)
                                }

                                if idx < moduleTitles.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }

                    // SYSTEM INFO & LOGOUT
                    VStack(spacing: 12) {
                        HStack {
                            Text("Phiên bản ứng dụng")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("v2.4.1 (Build 241 Pro)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Hồ Sơ & Phân Quyền")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywallSheet) {
                SubscriptionPaywallSheetView(store: store)
            }
            .sheet(item: Binding<ModuleDetailItem?>(
                get: {
                    if let idx = selectedModuleIndex, idx < moduleTitles.count {
                        let t = moduleTitles[idx]
                        return ModuleDetailItem(index: idx, title: t.0, icon: t.1, desc: t.2)
                    }
                    return nil
                },
                set: { _ in selectedModuleIndex = nil }
            )) { detail in
                ModuleDetailInspectorSheet(detail: detail, store: store)
            }
        }
    }
}
