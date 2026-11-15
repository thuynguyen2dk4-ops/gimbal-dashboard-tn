//
//  AutoCalibrationModalView.swift
//  SmartGimbalPro
//
//  Figma Node 96:3 — 31_calibration: Hiệu chỉnh cảm biến 6 mặt & Tự cân bằng CoG FOC 20kHz.
//

import SwiftUI
import UIKit

struct AutoCalibrationModalView: View {
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A

    private var clampedProgress: Double {
        min(1.0, max(0.0, ble.calibrationProgress))
    }

    private var surfaceBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }

    private var cardBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }

    private var borderStroke: Color {
        Color(UIColor.separator).opacity(0.35)
    }

    private var headlineText: String {
        if clampedProgress >= 1.0 {
            return "Hiệu chỉnh hoàn tất!"
        } else if ble.isCalibrating {
            return "Đang cân bằng trục Tilt..."
        } else {
            return "Sẵn sàng hiệu chuẩn 6 mặt"
        }
    }

    private var subtitleText: String {
        if !ble.calibrationStepText.isEmpty {
            return ble.calibrationStepText
        }
        return "Vui lòng không di chuyển hoặc chạm vào thiết bị"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                surfaceBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        gaugeSection
                        checklistSection
                        actionFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Hiệu chỉnh Gimbal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") {
                        ble.isCalibrating = false
                        ble.showCalibrationModal = false
                        dismiss()
                    }
                    .foregroundColor(Color(UIColor.systemBlue))
                }
            }
        }
    }

    private var gaugeSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color(UIColor.tertiarySystemFill), lineWidth: 9)

                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        clampedProgress >= 1.0 ? Color(UIColor.systemGreen) : accentYellow,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: clampedProgress)

                VStack(spacing: 2) {
                    Text("\(Int(clampedProgress * 100))%")
                        .font(.system(size: 30, weight: .heavy, design: .monospaced))
                        .foregroundColor(.primary)

                    Text("TIẾN ĐỘ")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140, height: 140)
            .padding(.top, 6)

            Text(headlineText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(clampedProgress >= 1.0 ? Color(UIColor.systemGreen) : .primary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            Text(subtitleText)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUY TRÌNH HIỆU CHỈNH 6 MẶT")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            VStack(spacing: 0) {
                calibrationStepRow(
                    icon: "checkmark",
                    iconBg: Color(UIColor.systemGreen),
                    title: "Bước 1: Đặt trên mặt phẳng cố định",
                    subtitle: stepState(minActive: 0.01, minDone: 0.34) == .completed
                        ? "Đã xác nhận độ nghiêng 0.0°"
                        : "Giữ máy đứng yên trên mặt bàn phẳng",
                    state: stepState(minActive: 0.01, minDone: 0.34)
                )
                Divider().padding(.leading, 56)

                calibrationStepRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconBg: Color(UIColor.systemOrange),
                    title: "Bước 2: Căn chỉnh IMU 3 trục",
                    subtitle: stepState(minActive: 0.34, minDone: 0.78) == .completed
                        ? "Đã cân bằng con quay hồi chuyển 20kHz"
                        : "Đang hiệu chuẩn con quay hồi chuyển",
                    state: stepState(minActive: 0.34, minDone: 0.78)
                )
                Divider().padding(.leading, 56)

                calibrationStepRow(
                    icon: "info.circle",
                    iconBg: Color(UIColor.systemGray),
                    title: "Bước 3: Lưu thông số vào bộ nhớ Gimbal",
                    subtitle: stepState(minActive: 0.78, minDone: 1.0) == .completed
                        ? "Đã lưu góc Zero Roll ±0.01° qua BLE 5.3"
                        : "Đang chờ bước 2 hoàn thành",
                    state: stepState(minActive: 0.78, minDone: 1.0)
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderStroke, lineWidth: 0.5)
            )
        }
    }

    private enum StepState {
        case pending
        case active
        case completed
    }

    private func stepState(minActive: Double, minDone: Double) -> StepState {
        if clampedProgress >= minDone { return .completed }
        if ble.isCalibrating && clampedProgress >= minActive { return .active }
        return .pending
    }

    private func calibrationStepRow(
        icon: String,
        iconBg: Color,
        title: String,
        subtitle: String,
        state: StepState
    ) -> some View {
        let resolvedBg: Color = {
            switch state {
            case .completed: return Color(UIColor.systemGreen)
            case .active: return Color(UIColor.systemOrange)
            case .pending: return iconBg == Color(UIColor.systemGreen) ? iconBg.opacity(0.65) : Color(UIColor.systemGray)
            }
        }()

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(resolvedBg)
                    .frame(width: 28, height: 28)

                Image(systemName: state == .completed ? "checkmark" : icon)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if state == .active {
                ProgressView()
                    .scaleEffect(0.85)
                    .tint(accentYellow)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var actionFooter: some View {
        VStack(spacing: 10) {
            if clampedProgress >= 1.0 {
                Button {
                    ble.showCalibrationModal = false
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Hoàn Tất")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(UIColor.systemGreen))
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    ble.startCoGCalibration()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: ble.isCalibrating ? "gyroscope" : "scope")
                        Text(ble.isCalibrating ? "Đang hiệu chuẩn IMU..." : "Bắt đầu hiệu chuẩn 6 mặt")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(ble.isCalibrating ? accentYellow.opacity(0.6) : accentYellow)
                    )
                }
                .buttonStyle(.plain)
                .disabled(ble.isCalibrating)
            }
        }
        .padding(.top, 4)
    }
}
