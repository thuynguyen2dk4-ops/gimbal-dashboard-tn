//
//  AspectPickerSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Bộ chọn tỷ lệ khung hình chuẩn Apple HIG (Figma Node 96:3 — 05_aspect_ratio).
//

import SwiftUI
import UIKit

struct AspectRatioOption: Identifiable {
    let id: String
    let title: String
    let tag: String
    let previewW: CGFloat
    let previewH: CGFloat

    static let allOptions: [AspectRatioOption] = [
        AspectRatioOption(id: "9:16", title: "9:16 Khung Dọc Toàn Màn", tag: "Mặc định • TikTok & Reels", previewW: 13, previewH: 23),
        AspectRatioOption(id: "3:4", title: "3:4 Chân Dung Feed", tag: "Dọc • Instagram Feed", previewW: 15, previewH: 20),
        AspectRatioOption(id: "1:1", title: "1:1 Vuông Cân Đối", tag: "Vuông • Square", previewW: 18, previewH: 18),
        AspectRatioOption(id: "4:3", title: "4:3 Open Gate Studio", tag: "Cảm biến đầy đủ", previewW: 21, previewH: 16),
        AspectRatioOption(id: "16:9", title: "16:9 Tiêu Chuẩn Ngang", tag: "YouTube • TV HD/4K", previewW: 24, previewH: 13.5),
        AspectRatioOption(id: "2.39:1", title: "2.39:1 Điện Ảnh CinemaScope", tag: "Anamorphic Widescreen", previewW: 26, previewH: 11)
    ]
}

// MARK: - Inline Frosted Aspect Bar (Figma 05_aspect_ratio .arbar)

struct AspectRatioPickerBar: View {
    let selectedRatio: String
    var onSelect: (String) -> Void
    var onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isLight = colorScheme == .light
        let activeColor = isLight
            ? Color(red: 0.73, green: 0.53, blue: 0.0)
            : Color(red: 1.0, green: 0.84, blue: 0.04)

        HStack(spacing: 2) {
            ForEach(AspectRatioOption.allOptions) { item in
                let isSelected = (selectedRatio == item.id)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelect(item.id)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                .stroke(isSelected ? activeColor : (isLight ? Color.black.opacity(0.62) : Color.white.opacity(0.75)), lineWidth: 1.6)
                                .frame(width: item.previewW, height: item.previewH)
                        }
                        .frame(height: 24)

                        Text(item.id)
                            .font(.system(size: 10.5, weight: isSelected ? .bold : .semibold, design: .monospaced))
                            .foregroundColor(isSelected ? activeColor : (isLight ? Color.black.opacity(0.68) : Color.white.opacity(0.80)))
                    }
                    .frame(width: 52, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(
                                isSelected
                                    ? (isLight ? Color.white.opacity(0.92) : Color.white.opacity(0.14))
                                    : Color.clear
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isLight ? Color.black.opacity(0.6) : Color.white.opacity(0.75))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(isLight ? Color.white.opacity(0.55) : Color.black.opacity(0.32))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.16), lineWidth: 0.6)
        )
        .shadow(color: Color.black.opacity(isLight ? 0.10 : 0.28), radius: 14, y: 4)
    }
}

// MARK: - Sheet Picker Fallback

struct AspectPickerSheetView: View {
    @Binding var selectedRatio: String
    var onSelect: ((String) -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let goldAccent = Color(red: 1.0, green: 0.84, blue: 0.04)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(AspectRatioOption.allOptions) { item in
                        let isSelected = selectedRatio == item.id
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedRatio = item.id
                            onSelect?(item.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(UIColor.tertiarySystemFill))
                                        .frame(width: 48, height: 34)
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .stroke(isSelected ? goldAccent : appleBlue, lineWidth: 1.8)
                                        .frame(width: item.previewW * 1.15, height: item.previewH * 1.15)
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
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        isSelected
                                            ? goldAccent.opacity(colorScheme == .light ? 0.14 : 0.18)
                                            : Color(UIColor.secondarySystemGroupedBackground)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                ToolbarItem(placement: .topBarLeading) {
                    if selectedRatio != "9:16" {
                        Button("Đặt lại 9:16") {
                            selectedRatio = "9:16"
                            onSelect?("9:16")
                            dismiss()
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(goldAccent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(appleBlue)
                }
            }
        }
    }
}
