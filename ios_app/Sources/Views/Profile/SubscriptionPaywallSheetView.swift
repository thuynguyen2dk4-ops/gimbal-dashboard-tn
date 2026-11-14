//
//  SubscriptionPaywallSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Bảng chọn 3 gói bản quyền Studio (15_Subscription_Paywall_3Tiers).
//

import SwiftUI

struct SubscriptionPaywallSheetView: View {
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    TierCard(
                        name: "Free Starter",
                        price: "0₫",
                        desc: "1080p • Pan Follow • Cơ bản",
                        activeTier: store.userTier
                    ) {
                        store.setTier("Free Starter")
                        dismiss()
                    }

                    TierCard(
                        name: "Creator Pro",
                        price: "299.000₫ / tháng",
                        desc: "4K 60fps • Apple Log • AI Vision • 3D LUT",
                        activeTier: store.userTier
                    ) {
                        store.setTier("Creator Pro")
                        dismiss()
                    }

                    TierCard(
                        name: "VIP LIFETIME",
                        price: "Trọn Đời Phần Cứng",
                        desc: "Toàn bộ 7 module • Multi-Cam • FOC Tuning",
                        activeTier: store.userTier
                    ) {
                        store.setTier("VIP LIFETIME")
                        dismiss()
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Gói Bản Quyền T-Flow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

struct TierCard: View {
    let name: String
    let price: String
    let desc: String
    let activeTier: String
    let onSelect: () -> Void

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    var isSelected: Bool { activeTier == name }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(price)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(goldAccent)
                    if isSelected {
                        Text("ĐANG DÙNG")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(15)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(UIColor.secondarySystemGroupedBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? goldAccent : Color.clear, lineWidth: 1.8)
            )
        }
        .buttonStyle(.plain)
    }
}
