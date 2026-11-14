//
//  TelemetryMetersView.swift
//  SmartGimbalPro
//
//  Các thanh đo kỹ thuật Apple HIG (Figma Node 96:3): Biểu đồ ánh sáng Histogram gọn,
//  thước âm thanh Stereo Audio VU và thẻ đo góc Roll/Pitch/Pan.
//

import SwiftUI

struct MiniRGBHistogramView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let curvePoints: [CGFloat] = [
        0.05, 0.14, 0.28, 0.44, 0.56, 0.42, 0.72, 0.88, 0.64, 0.78, 0.92, 0.54, 0.28, 0.08
    ]

    var body: some View {
        let isLight = colorScheme == .light
        let strokeGold = isLight
            ? Color(red: 0.73, green: 0.53, blue: 0.0)
            : Color(red: 1.0, green: 0.84, blue: 0.04)

        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // Filled luminance curve
                Path { path in
                    guard curvePoints.count > 1 else { return }
                    let stepX = w / CGFloat(curvePoints.count - 1)
                    path.move(to: CGPoint(x: 0, y: h))
                    for (idx, val) in curvePoints.enumerated() {
                        let x = CGFloat(idx) * stepX
                        let y = h - (val * (h - 4)) - 2
                        if idx == 0 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            let prevX = CGFloat(idx - 1) * stepX
                            let prevY = h - (curvePoints[idx - 1] * (h - 4)) - 2
                            let midX = (prevX + x) * 0.5
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: midX, y: prevY),
                                control2: CGPoint(x: midX, y: y)
                            )
                        }
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            (isLight ? Color.black : Color.white).opacity(0.32),
                            (isLight ? Color.black : Color.white).opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Accent highlight waveform line
                Path { path in
                    guard curvePoints.count > 1 else { return }
                    let stepX = w / CGFloat(curvePoints.count - 1)
                    for (idx, val) in curvePoints.enumerated() {
                        let x = CGFloat(idx) * stepX
                        let y = h - (val * (h - 4)) - 2
                        if idx == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            let prevX = CGFloat(idx - 1) * stepX
                            let prevY = h - (curvePoints[idx - 1] * (h - 4)) - 2
                            let midX = (prevX + x) * 0.5
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: midX, y: prevY),
                                control2: CGPoint(x: midX, y: y)
                            )
                        }
                    }
                }
                .stroke(strokeGold, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 4)

            // Discreet corner label + RGB dots
            VStack {
                HStack(spacing: 3) {
                    Text("HISTO")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundColor(isLight ? Color.black.opacity(0.55) : Color.white.opacity(0.65))
                    Spacer()
                    HStack(spacing: 2) {
                        Circle().fill(Color.red.opacity(0.85)).frame(width: 3, height: 3)
                        Circle().fill(Color.green.opacity(0.85)).frame(width: 3, height: 3)
                        Circle().fill(Color.blue.opacity(0.85)).frame(width: 3, height: 3)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.top, 3)
                Spacer()
            }
        }
        .frame(width: 82, height: 42)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isLight ? Color.white.opacity(0.45) : Color.black.opacity(0.28))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.14), lineWidth: 0.6)
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
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isLight ? Color.white.opacity(0.50) : Color.black.opacity(0.32))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.16), lineWidth: 0.6)
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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isLight ? Color.white : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.04))
            }
            Slider(value: $value, in: 0.3...1.0)
                .tint(Color(red: 1.0, green: 0.84, blue: 0.04))
        }
    }
}
