//
//  ModuleDetailInspectorSheet.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Chi tiết kích hoạt từng Mô-đun Cloud (đồng bộ theme Sáng/Tối Apple HIG).
//

import SwiftUI
import UIKit

struct ModuleDetailInspectorSheet: View {
    let detail: ModuleDetailItem
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
    }

    private var isEnabled: Bool {
        store.modules.indices.contains(detail.index) ? store.modules[detail.index] : true
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accentGold.opacity(0.16))
                            .frame(width: 48, height: 48)
                        Image(systemName: detail.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(accentGold)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(detail.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        Text(detail.desc)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trạng thái kích hoạt")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(isEnabled ? "Đang hoạt động • Đồng bộ \(store.userTier)" : "Đang tạm tắt cho tài khoản này")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            store.toggleModule(at: detail.index)
                        } label: {
                            Text(isEnabled ? "Tắt mô-đun" : "Bật mô-đun")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isEnabled ? Color(UIColor.systemRed) : Color(UIColor.systemGreen))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill((isEnabled ? Color(UIColor.systemRed) : Color(UIColor.systemGreen)).opacity(0.16))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Đồng bộ Supabase Cloud")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(store.isOnline ? Color(UIColor.systemGreen) : Color.gray)
                                .frame(width: 7, height: 7)
                            Text(store.isOnline ? "Trực tuyến • \(store.lastSyncTime)" : "Ngoại tuyến")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                Spacer()
            }
            .padding(16)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Chi tiết mô-đun")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
