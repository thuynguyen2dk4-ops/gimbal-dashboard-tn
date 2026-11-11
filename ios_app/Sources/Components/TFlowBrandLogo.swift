//
//  TFlowBrandLogo.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

// MARK: - =====================================================================
// 1. OFFICIAL T-FLOW BRAND LOGO & VECTOR GEOMETRY
// =====================================================================

struct TFlowBrandLogo: View {
    var size: CGFloat = 28
    var strokeColor: Color = .white
    var bgColor: Color = .black
    var showText: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.26)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.26)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

                Canvas { context, sz in
                    let scale = sz.width / 100.0
                    var path = Path()

                    // Fluid wave top bar (T-Flow Wave)
                    path.move(to: CGPoint(x: 16 * scale, y: 34 * scale))
                    path.addCurve(
                        to: CGPoint(x: 50 * scale, y: 34 * scale),
                        control1: CGPoint(x: 26 * scale, y: 21 * scale),
                        control2: CGPoint(x: 39 * scale, y: 21 * scale)
                    )
                    path.addCurve(
                        to: CGPoint(x: 84 * scale, y: 34 * scale),
                        control1: CGPoint(x: 61 * scale, y: 47 * scale),
                        control2: CGPoint(x: 74 * scale, y: 47 * scale)
                    )

                    // Vertical stem
                    path.move(to: CGPoint(x: 50 * scale, y: 34 * scale))
                    path.addLine(to: CGPoint(x: 50 * scale, y: 82 * scale))

                    context.stroke(
                        path,
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: 12 * scale, lineCap: .round, lineJoin: .round)
                    )
                }
                .padding(size * 0.16)
            }
            .frame(width: size, height: size)

            if showText {
                Text("t-flow")
                    .font(.system(size: size * 0.72, weight: .bold, design: .rounded))
                    .foregroundColor(strokeColor)
                    .tracking(-0.5)
            }
        }
    }
}
