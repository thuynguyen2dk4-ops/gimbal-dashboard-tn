//
//  SubscriptionPaywallSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

struct SubscriptionPaywallSheetView: View {
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("CẤP ĐỘ GÓI BẢN QUYỀN T-FLOW")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 20)

            VStack(spacing: 12) {
                TierCard(name: "Free Starter", price: "0₫", desc: "Quay cơ bản 1080p, chế độ Pan Follow", activeTier: store.userTier) {
                    store.setTier("Free Starter")
                    dismiss()
                }
                TierCard(name: "Creator Pro", price: "299.000₫ / tháng", desc: "4K 60fps, Apple Log, AI Vision, 3D LUT, Waypoints", activeTier: store.userTier) {
                    store.setTier("Creator Pro")
                    dismiss()
                }
                TierCard(name: "VIP LIFETIME", price: "Trọn Đời Đi Kèm Phần Cứng", desc: "Toàn bộ 7 module không giới hạn, FOC Micro-tuning", activeTier: store.userTier) {
                    store.setTier("VIP LIFETIME")
                    dismiss()
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea())
    }
}

struct TierCard: View {
    let name: String
    let price: String
    let desc: String
    let activeTier: String
    let onSelect: () -> Void

    var isSelected: Bool { activeTier == name }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(desc).font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                    if isSelected {
                        Text("ĐANG DÙNG").font(.system(size: 9, weight: .black)).foregroundColor(.green)
                    }
                }
            }
            .padding(14)
            .background(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color(red: 0.98, green: 0.72, blue: 0.10) : Color.clear, lineWidth: 1.5))
        }
    }
}
