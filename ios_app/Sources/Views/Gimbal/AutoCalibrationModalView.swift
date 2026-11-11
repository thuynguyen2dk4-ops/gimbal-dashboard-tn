//
//  AutoCalibrationModalView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

// MARK: - =====================================================================
// 15. AUTO CALIBRATION WIZARD MODAL (SCREEN 31)
// =====================================================================

struct AutoCalibrationModalView: View {
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 8)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: CGFloat(ble.calibrationProgress))
                    .stroke(
                        LinearGradient(colors: [Color(red: 0.98, green: 0.72, blue: 0.10), Color.green], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Text("\(Int(ble.calibrationProgress * 100))%")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text("CoG Sync")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            VStack(spacing: 8) {
                Text(ble.calibrationProgress >= 1.0 ? "CÂN BẰNG THÀNH CÔNG!" : "ĐANG HIỆU CHUẨN COG")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ble.calibrationProgress >= 1.0 ? Color.green : Color.white)

                Text(ble.calibrationStepText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            if ble.calibrationProgress >= 1.0 {
                Button("Hoàn Tất & Bắt Đầu Quay") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.98, green: 0.72, blue: 0.10))
                .cornerRadius(16)
                .padding(.horizontal, 24)
            }
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea())
    }
}
