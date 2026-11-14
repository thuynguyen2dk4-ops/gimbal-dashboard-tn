//
//  AspectPickerSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Bộ chọn tỷ lệ khung hình theo chuẩn Apple HIG (08_Modal_Aspect_Ratio_Picker).
//

import SwiftUI

struct AspectPickerSheetView: View {
    @Binding var selectedRatio: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)

    private struct AspectOption: Identifiable {
        let id: String
        let title: String
        let tag: String
        let previewW: CGFloat
        let previewH: CGFloat
    }

    private let options: [AspectOption] = [
        AspectOption(id: "16:9", title: "16:9 Tiêu Chuẩn Ngang", tag: "YouTube • TV", previewW: 36, previewH: 20),
        AspectOption(id: "9:16", title: "9:16 Khung Dọc Social", tag: "TikTok • Reels", previewW: 16, previewH: 28),
        AspectOption(id: "2.39:1", title: "2.39:1 Điện Ảnh Anamorphic", tag: "Cinema Wide", previewW: 40, previewH: 16),
        AspectOption(id: "4:3", title: "4:3 Open Gate Studio", tag: "Cảm biến đầy đủ", previewW: 30, previewH: 22),
        AspectOption(id: "1:1", title: "1:1 Vuông Cân Đối", tag: "Instagram", previewW: 24, previewH: 24)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(options) { item in
                        let isSelected = selectedRatio == item.id
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedRatio = item.id
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                // Visual frame silhouette preview
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(UIColor.tertiarySystemFill))
                                        .frame(width: 48, height: 34)
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(isSelected ? goldAccent : appleBlue, lineWidth: 1.8)
                                        .frame(width: item.previewW, height: item.previewH)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text(item.tag)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(goldAccent)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        isSelected
                                            ? goldAccent.opacity(colorScheme == .light ? 0.14 : 0.18)
                                            : Color(UIColor.secondarySystemGroupedBackground)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? goldAccent : Color.clear, lineWidth: 1.6)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tỷ Lệ Khung Hình")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }
}
