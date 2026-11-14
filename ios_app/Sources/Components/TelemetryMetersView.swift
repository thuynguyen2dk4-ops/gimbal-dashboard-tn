//
//  TelemetryMetersView.swift
//  SmartGimbalPro
//
//  Các thanh đo kỹ thuật chuyên nghiệp: Biểu đồ ánh sáng RGB Histogram,
//  thước âm thanh Stereo Audio VU và các thẻ đo góc Roll/Pitch/Pan.
//

import SwiftUI

struct MiniRGBHistogramView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let bins: [Double] = [
        0.24, 0.38, 0.56, 0.72, 0.85, 0.92, 0.88, 0.76, 0.62,
        0.54, 0.68, 0.82, 0.78, 0.64, 0.48, 0.36, 0.25, 0.18
    ]

    var body: some View {
        let isLight = colorScheme == .light
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("HISTO")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(isLight ? Color(red: 0.15, green: 0.23, blue: 0.34) : .white.opacity(0.75))
                Spacer(minLength: 4)
                HStack(spacing: 2) {
                    Circle().fill(Color.red.opacity(0.9)).frame(width: 4, height: 4)
                    Circle().fill(Color.green.opacity(0.9)).frame(width: 4, height: 4)
                    Circle().fill(Color.blue.opacity(0.9)).frame(width: 4, height: 4)
                }
            }

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(bins.enumerated()), id: \.offset) { idx, ratio in
                    let h = max(4.0, ratio * 24.0)
                    let topColor: Color = idx < 6
                        ? Color(red: 0.94, green: 0.27, blue: 0.27)
                        : (idx < 12 ? Color(red: 0.20, green: 0.83, blue: 0.60) : Color(red: 0.38, green: 0.65, blue: 0.98))
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [topColor.opacity(0.92), Color.white.opacity(isLight ? 0.35 : 0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: CGFloat(h))
                }
            }
            .frame(height: 26, alignment: .bottom)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 108)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isLight ? Color.white.opacity(0.84) : Color.black.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

struct MiniStereoAudioMeterView: View {
    @Environment(\.colorScheme) private var colorScheme
    let levelL: Double
    let levelR: Double

    var body: some View {
        let isLight = colorScheme == .light
        VStack(alignment: .trailing, spacing: 4) {
            Text("AUDIO VU L/R")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(isLight ? Color(red: 0.15, green: 0.23, blue: 0.34) : .white.opacity(0.75))

            VStack(spacing: 3) {
                channelRow(label: "L", level: levelL, isLight: isLight)
                channelRow(label: "R", level: levelR, isLight: isLight)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isLight ? Color.white.opacity(0.84) : Color.black.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func channelRow(label: String, level: Double, isLight: Bool) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(isLight ? .secondary : .white.opacity(0.6))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.16))
                    .frame(width: 54, height: 4)
                Capsule()
                    .fill(level > 0.85 ? Color.red : (level > 0.65 ? Color.yellow : Color.green))
                    .frame(width: max(4, 54 * CGFloat(min(1.0, max(0.0, level)))), height: 4)
            }
        }
    }
}

struct AxisAngleCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let axis: String
    let angle: String
    let status: String
    let color: Color

    var body: some View {
        let isLight = colorScheme == .light
        VStack(spacing: 6) {
            Text(axis)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isLight ? .secondary : .white.opacity(0.65))

            Text(angle)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)

            Text(status)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isLight ? .secondary : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isLight ? Color.white : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isLight ? Color.black.opacity(0.07) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct TorqueSliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
            }
            Slider(value: $value, in: 0.3...1.0)
                .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
        }
    }
}
