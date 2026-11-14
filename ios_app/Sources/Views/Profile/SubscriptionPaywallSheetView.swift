//
//  SubscriptionPaywallSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Figma Node 96:3 — 36_paywall_dark / 36_paywall_light (Apple HIG).
//

import SwiftUI
import UIKit

enum PaywallPlanTier: String, CaseIterable, Identifiable {
    case monthly
    case yearly
    case lifetime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "1 Tháng"
        case .yearly: return "1 Năm"
        case .lifetime: return "Trọn đời"
        }
    }

    var shortPrice: String {
        switch self {
        case .monthly: return "149K"
        case .yearly: return "899K"
        case .lifetime: return "1.999K"
        }
    }

    var subPrice: String {
        switch self {
        case .monthly: return "đ / tháng"
        case .yearly: return "75K đ / tháng"
        case .lifetime: return "Một lần duy nhất"
        }
    }

    var badgeText: String? {
        self == .yearly ? "Tiết kiệm 50%" : nil
    }

    var renewalNote: String {
        switch self {
        case .monthly:
            return "Sau đó 149.000 đ/tháng. Huỷ bất kỳ lúc nào trong Cài đặt App Store."
        case .yearly:
            return "Sau đó 899.000 đ/năm. Huỷ bất kỳ lúc nào trong Cài đặt App Store."
        case .lifetime:
            return "Thanh toán 1 lần 1.999.000 đ — Mở khoá trọn đời toàn bộ 7 mô-đun Pro."
        }
    }

    var storeTierName: String {
        switch self {
        case .monthly: return "Creator Pro"
        case .yearly: return "Creator Pro Năm"
        case .lifetime: return "VIP LIFETIME"
        }
    }
}

struct SubscriptionPaywallSheetView: View {
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPlan: PaywallPlanTier = .yearly
    @State private var feedbackMessage: String? = nil

    private var accentGold: Color {
        colorScheme == .light
            ? Color(red: 0.90, green: 0.65, blue: 0.00)
            : Color(red: 1.00, green: 0.84, blue: 0.04)
    }

    private let proBenefits: [String] = [
        "Quay không giới hạn độ phân giải 4K 120fps & ProRes Log",
        "Thuật toán bám nét AI DeepTrack 3.0 nhận diện khuôn mặt",
        "48 bộ màu Cinematic LUT độc quyền từ đạo diễn Hollywood",
        "Điều khiển chuyển động Motion Timelapse đa điểm mượt mà",
        "Lưu trữ đám mây 2TB không nén"
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroHeader
                    benefitsCard
                    plansRow
                    ctaSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color(UIColor.tertiarySystemFill)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Đóng")
                }
            }
            .onAppear {
                if store.userTier == "Creator Pro" {
                    selectedPlan = .monthly
                } else if store.userTier == "VIP LIFETIME" {
                    selectedPlan = .lifetime
                } else {
                    selectedPlan = .yearly
                }
            }
        }
    }

    private var heroHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentGold.opacity(0.18))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(accentGold.opacity(0.42), lineWidth: 1.5)
                    )
                Image(systemName: "crown.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(accentGold)
            }

            Text("Khai phóng toàn bộ sức mạnh điện ảnh")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Nâng tầm thước phim với công nghệ chuyên nghiệp")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(proBenefits, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Text("✓")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(accentGold)
                    Text(item)
                        .font(.system(size: 13.5))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 0.5)
        )
    }

    private var plansRow: some View {
        HStack(spacing: 8) {
            ForEach(PaywallPlanTier.allCases) { plan in
                let isSelected = selectedPlan == plan
                let isCurrentActive = store.userTier == plan.storeTierName

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedPlan = plan
                } label: {
                    ZStack(alignment: .top) {
                        VStack(spacing: 4) {
                            Text(plan.title)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .padding(.top, plan.badgeText != nil ? 4 : 0)

                            Text(plan.shortPrice)
                                .font(.system(size: 17, weight: isSelected ? .heavy : .bold))
                                .foregroundColor(isSelected ? accentGold : .primary)

                            Text(plan.subPrice)
                                .font(.system(size: 10.5))
                                .foregroundColor(isSelected ? .secondary : Color(UIColor.tertiaryLabel))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            if isCurrentActive {
                                Text("Đang dùng")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(Color(UIColor.systemGreen))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(UIColor.systemGreen).opacity(0.15)))
                                    .padding(.top, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 90)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? accentGold : Color(UIColor.separator).opacity(0.55), lineWidth: isSelected ? 2 : 1)
                        )
                        .shadow(color: isSelected ? accentGold.opacity(0.22) : .clear, radius: 10, y: 4)

                        if let badge = plan.badgeText {
                            Text(badge.uppercased())
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(accentGold))
                                .offset(y: -10)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private var ctaSection: some View {
        VStack(spacing: 10) {
            if let feedback = feedbackMessage {
                Text(feedback)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemGreen))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(UIColor.systemGreen).opacity(0.14)))
            }

            Button {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                store.setTier(selectedPlan.storeTierName)
                dismiss()
            } label: {
                Text("Bắt đầu dùng thử miễn phí 7 ngày")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accentGold)
                    )
                    .shadow(color: accentGold.opacity(0.32), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            Text(selectedPlan.renewalNote)
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            HStack(spacing: 16) {
                Button("Khôi phục mua hàng") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    store.setTier("VIP LIFETIME")
                    selectedPlan = .lifetime
                    feedbackMessage = "✓ Đã khôi phục bản quyền VIP LIFETIME"
                }
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(Color(UIColor.systemBlue))

                if store.userTier != "Free Starter" {
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Button("Dùng Free Starter") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        store.setTier("Free Starter")
                        feedbackMessage = "Đã chuyển về gói Free Starter"
                    }
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                }
            }
            .padding(.top, 2)
        }
    }
}
