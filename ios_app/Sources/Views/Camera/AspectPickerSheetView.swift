//
//  AspectPickerSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 11. ASPECT RATIO PICKER SHEET VIEW
// =====================================================================

struct AspectPickerSheetView: View {
    @Binding var selectedRatio: String
    @Environment(\.dismiss) var dismiss

    let ratios = [
        ("16:9", "Chuẩn Video / TV"),
        ("9:16", "Story / TikTok"),
        ("2.39:1", "Cinemascope Điện Ảnh"),
        ("4:3", "Classic Academy"),
        ("1:1", "Square Vuông")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("TỈ LỆ KHUNG HÌNH ĐIỆN ẢNH")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 18)

            HStack(spacing: 10) {
                ForEach(ratios, id: \.0) { item in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedRatio = item.0
                        dismiss()
                    }) {
                        VStack(spacing: 6) {
                            Text(item.0)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                            Text(item.1)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedRatio == item.0 ? Color.white : Color.white.opacity(0.1))
                        .foregroundColor(selectedRatio == item.0 ? Color.black : Color.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.14).ignoresSafeArea())
    }
}
