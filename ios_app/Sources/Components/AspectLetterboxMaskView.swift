//
//  AspectLetterboxMaskView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

// MARK: - =====================================================================
// 9. CINEMATIC ASPECT RATIO LETTERBOX / PILLARBOX MASK
// =====================================================================

struct AspectLetterboxMaskView: View {
    let ratio: String
    let screenSize: CGSize

    var body: some View {
        GeometryReader { _ in
            if ratio == "2.39:1" {
                // 2.39:1 Cinemascope Widescreen Letterbox Bars
                let barHeight = screenSize.height * 0.16
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black.opacity(0.88))
                        .frame(height: barHeight)
                        .overlay(
                            VStack {
                                Spacer()
                                Rectangle().fill(Color(red: 0.98, green: 0.72, blue: 0.10).opacity(0.4)).frame(height: 1)
                            }
                        )

                    Spacer()

                    Rectangle()
                        .fill(Color.black.opacity(0.88))
                        .frame(height: barHeight)
                        .overlay(
                            VStack {
                                Rectangle().fill(Color(red: 0.98, green: 0.72, blue: 0.10).opacity(0.4)).frame(height: 1)
                                Spacer()
                            }
                        )
                }
            } else if ratio == "4:3" {
                // 4:3 Classical Frame Letterbox Bars
                let barHeight = screenSize.height * 0.11
                VStack(spacing: 0) {
                    Rectangle().fill(Color.black.opacity(0.85)).frame(height: barHeight)
                    Spacer()
                    Rectangle().fill(Color.black.opacity(0.85)).frame(height: barHeight)
                }
            } else if ratio == "1:1" {
                // 1:1 Square Frame Letterbox Bars
                let barHeight = (screenSize.height - screenSize.width) / 2
                VStack(spacing: 0) {
                    Rectangle().fill(Color.black.opacity(0.88)).frame(height: max(0, barHeight))
                    Spacer()
                    Rectangle().fill(Color.black.opacity(0.88)).frame(height: max(0, barHeight))
                }
            }
        }
    }
}


// MARK: - =====================================================================
// 18. UI SHAPES & HELPERS
// =====================================================================

struct CinematicReticleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arm: CGFloat = min(rect.width, rect.height) * 0.28

        // Top Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        // Top Right
        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        // Bottom Left
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.maxY))

        // Bottom Right
        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))

        return path
    }
}

struct RuleOfThirdsGridView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height

                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))

                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: h))

                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))

                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
            }
            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
        }
    }
}
