//
//  QuickSettingsSheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

// MARK: - =====================================================================
// 12. QUICK SETTINGS SHEET VIEW (SCREEN 04)
// =====================================================================

struct QuickSettingsSheetView: View {
    @ObservedObject var camera: CameraService
    @State private var gridEnabled: Bool = true
    @State private var zebraEnabled: Bool = false
    @State private var peakingEnabled: Bool = false
    @State private var antiFlicker: String = "50Hz"

    var body: some View {
        VStack(spacing: 18) {
            Text("TRÌNH ĐƠN CÀI ĐẶT NHANH")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 18)

            VStack(spacing: 12) {
                Toggle("Lưới Bố Cục 3x3 (Rule of Thirds)", isOn: $gridEnabled)
                Toggle("Zebra Stripes Cảnh Báo Phơi Sáng 95%", isOn: $zebraEnabled)
                Toggle("Focus Peaking Hỗ Trợ Lấy Nét Cyan", isOn: $peakingEnabled)

                HStack {
                    Text("Khử Nhấp Nháy (Anti-Flicker)")
                    Spacer()
                    Picker("", selection: $antiFlicker) {
                        Text("50Hz (EU/VN)").tag("50Hz")
                        Text("60Hz (US)").tag("60Hz")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.14).ignoresSafeArea())
    }
}
