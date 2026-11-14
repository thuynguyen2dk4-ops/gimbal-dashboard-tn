//
//  AutoCalibrationModalView.swift
//  SmartGimbalPro
//
//  Figma Node 96:3 — 31_calibration: Hiệu chỉnh cảm biến 6 mặt & Tự cân bằng CoG FOC 20kHz.
//

import SwiftUI

struct AutoCalibrationModalView: View {
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A

    private var clampedProgress: Double {
        min(1.0, max(0.0, ble.calibrationProgress))
    }

    private var surfaceBackground: Color {
        colorScheme == .light ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color.black
    }

    private var cardBackground: Color {
        colorScheme == .light ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.12)
    }

    private var borderStroke: Color {
        colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.10)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                surfaceBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        gaugeSection
                        checklistSection
                        actionFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
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
                    .foregroundColor(accentYellow)
                }
            }
        }
    }

    private var gaugeSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(
                        colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12),
                        lineWidth: 11
                    )

                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                accentYellow,
                                clampedProgress >= 1.0 ? Color.green : Color.orange
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: clampedProgress)

                VStack(spacing: 4) {
                    Text("\(Int(clampedProgress * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Tiến độ")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 148, height: 148)
            .padding(.top, 4)

            Text(
                ble.calibrationStepText.isEmpty
                    ? "Đặt Smart Gimbal S1 trên mặt phẳng ổn định trước khi bắt đầu."
                    : ble.calibrationStepText
            )
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(clampedProgress >= 1.0 ? .green : .secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .frame(minHeight: 36)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderStroke, lineWidth: 1)
        )
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUY TRÌNH HIỆU CHỈNH 6 MẶT")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                calibrationStepRow(
                    number: "1",
                    title: "Bước 1: Đặt trên mặt phẳng cố định",
                    subtitle: "Giữ máy đứng yên, không chạm vào trục Roll/Tilt",
                    state: stepState(minActive: 0.01, minDone: 0.34)
                )
                Divider().padding(.leading, 48)

                calibrationStepRow(
                    number: "2",
                    title: "Bước 2: Căn chỉnh IMU 3 trục",
                    subtitle: "Đo bù lệch trọng tâm & triệt rung Notch 245Hz",
                    state: stepState(minActive: 0.34, minDone: 0.78)
                )
                Divider().padding(.leading, 48)

                calibrationStepRow(
                    number: "3",
                    title: "Bước 3: Lưu thông số vào bộ nhớ Gimbal",
                    subtitle: "Khóa điểm Zero góc Roll ±0.01° qua BLE 5.3",
                    state: stepState(minActive: 0.78, minDone: 1.0)
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderStroke, lineWidth: 1)
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
        number: String,
        title: String,
        subtitle: String,
        state: StepState
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        state == .completed
                            ? Color.green.opacity(0.18)
                            : (state == .active ? accentYellow.opacity(0.22) : Color.secondary.opacity(0.14))
                    )
                    .frame(width: 28, height: 28)

                if state == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text(number)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(state == .active ? accentYellow : .secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if state == .active {
                ProgressView()
                    .scaleEffect(0.85)
                    .tint(accentYellow)
            } else if state == .completed {
                Text("Xong")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.green))
                }
            } else {
                Button {
                    ble.startCoGCalibration()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: ble.isCalibrating ? "gyroscope" : "scope")
                        Text(ble.isCalibrating ? "Đang hiệu chuẩn IMU..." : "Bắt đầu hiệu chuẩn")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(ble.isCalibrating ? accentYellow.opacity(0.6) : accentYellow))
                }
                .disabled(ble.isCalibrating)
            }
        }
        .padding(.top, 4)
    }
}
