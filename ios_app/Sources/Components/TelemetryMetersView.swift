//
//  TelemetryMetersView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

// MARK: - =====================================================================
// 10. MINI RGB HISTOGRAM & STEREO AUDIO VU METER
// =====================================================================

struct MiniRGBHistogramView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("RGB HISTOGRAM")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<18, id: \.self) { idx in
                    let h = 4.0 + Double(sin(Double(idx) * 0.4) * 12.0 + 12.0)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.green.opacity(0.8), Color.blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: CGFloat(h))
                }
            }
            .frame(height: 28)
            .padding(6)
            .background(.ultraThinMaterial)
            .cornerRadius(6)
        }
    }
}

struct MiniStereoAudioMeterView: View {
    let levelL: Double
    let levelR: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("AUDIO VU L/R")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 3) {
                // Channel L
                HStack(spacing: 2) {
                    Text("L").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15)).frame(width: 52, height: 4)
                        Capsule()
                            .fill(levelL > 0.85 ? Color.red : (levelL > 0.65 ? Color.yellow : Color.green))
                            .frame(width: max(4, 52 * CGFloat(levelL)), height: 4)
                    }
                }

                // Channel R
                HStack(spacing: 2) {
                    Text("R").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15)).frame(width: 52, height: 4)
                        Capsule()
                            .fill(levelR > 0.85 ? Color.red : (levelR > 0.65 ? Color.yellow : Color.green))
                            .frame(width: max(4, 52 * CGFloat(levelR)), height: 4)
                    }
                }
            }
            .padding(6)
            .background(.ultraThinMaterial)
            .cornerRadius(6)
        }
    }
}


struct AxisAngleCard: View {
    let axis: String
    let angle: String
    let status: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(axis)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.6))

            Text(angle)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)

            Text(status)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }
}

struct TorqueSliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                Spacer()
                Text("\(Int(value * 100))%").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
            }
            Slider(value: $value, in: 0.3...1.0)
                .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
        }
    }
}
