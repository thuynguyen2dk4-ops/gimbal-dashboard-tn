//
//  AspectLetterboxMaskView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Khung tỷ lệ điện ảnh Figma Node 96:3 (05_aspect_ratio): hỗ trợ 9:16, 3:4, 4:3, 1:1, 16:9, 2.39:1 CINEMASCOPE.
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 9. CINEMATIC ASPECT RATIO LETTERBOX / PILLARBOX MASK
// =====================================================================

struct AspectLetterboxMaskView: View {
    let ratio: String
    let screenSize: CGSize
    var isLandscape: Bool = false
    var onResetToFullFrame: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    private let goldAccent = Color(red: 1.0, green: 0.84, blue: 0.04)

    private var numericRatio: CGFloat? {
        switch ratio {
        case "9:16": return nil // Full-bleed default screen
        case "3:4": return 3.0 / 4.0
        case "4:3": return 4.0 / 3.0
        case "1:1": return 1.0
        case "16:9": return 16.0 / 9.0
        case "2.39:1": return 2.39
        default: return nil
        }
    }

    private var ratioLabel: String {
        switch ratio {
        case "2.39:1": return "2.39:1 CINEMASCOPE"
        case "16:9": return "16:9 WIDESCREEN"
        case "4:3": return "4:3 OPEN GATE"
        case "3:4": return "3:4 CHÂN DUNG"
        case "1:1": return "1:1 VUÔNG"
        default: return ratio
        }
    }

    var body: some View {
        let w = max(1, screenSize.width)
        let h = max(1, screenSize.height)
        let isLight = colorScheme == .light
        let isCinema = (ratio == "2.39:1")
        let cornerColor = isCinema ? goldAccent : Color.white.opacity(0.88)
        let maskColor = isLight
            ? Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.84)
            : Color.black.opacity(0.84)

        if let baseAspect = numericRatio {
            let effectiveAspect = isLandscape ? (1.0 / baseAspect) : baseAspect
            let screenAspect = w / h
            let fitW = screenAspect > effectiveAspect ? (h * effectiveAspect) : w
            let fitH = screenAspect > effectiveAspect ? h : (w / effectiveAspect)
            let sideBarW = max(0, (w - fitW) / 2.0)
            let topBarH = max(0, (h - fitH) / 2.0)

            ZStack {
                // Dark / Frosted letterbox & pillarbox bars (Non-blocking for viewfinder gestures)
                VStack(spacing: 0) {
                    if topBarH > 1 {
                        Rectangle().fill(maskColor).frame(height: topBarH)
                    }
                    HStack(spacing: 0) {
                        if sideBarW > 1 {
                            Rectangle().fill(maskColor).frame(width: sideBarW)
                        }
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: fitW, height: fitH)
                            .overlay(
                                Rectangle()
                                    .stroke(
                                        isCinema ? goldAccent.opacity(0.45) : Color.white.opacity(0.32),
                                        lineWidth: 0.8
                                    )
                            )
                            .overlay(
                                MatteCornerBrackets(color: cornerColor)
                                    .padding(6)
                            )
                        if sideBarW > 1 {
                            Rectangle().fill(maskColor).frame(width: sideBarW)
                        }
                    }
                    if topBarH > 1 {
                        Rectangle().fill(maskColor).frame(height: topBarH)
                    }
                }
                .frame(width: w, height: h)
                .allowsHitTesting(false)

                // Interactive tag + Reset to 9:16 pill positioned along frame border
                aspectHeaderBadge(
                    w: w,
                    h: h,
                    fitW: fitW,
                    fitH: fitH,
                    topBarH: topBarH,
                    sideBarW: sideBarW,
                    isLight: isLight,
                    isCinema: isCinema
                )
            }
            .frame(width: w, height: h)
        }
    }

    @ViewBuilder
    private func aspectHeaderBadge(
        w: CGFloat,
        h: CGFloat,
        fitW: CGFloat,
        fitH: CGFloat,
        topBarH: CGFloat,
        sideBarW: CGFloat,
        isLight: Bool,
        isCinema: Bool
    ) -> some View {
        let badgeContent = HStack(spacing: 8) {
            Text(ratioLabel)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundColor(isCinema ? goldAccent : (isLight ? Color.black.opacity(0.75) : Color.white.opacity(0.88)))
                .tracking(0.4)

            if let onResetToFullFrame = onResetToFullFrame {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onResetToFullFrame()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("Đặt lại 9:16")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(goldAccent))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isLight ? Color.white.opacity(0.88) : Color.black.opacity(0.68))
        )
        .overlay(
            Capsule()
                .stroke((isCinema ? goldAccent : Color.white).opacity(0.28), lineWidth: 0.6)
        )

        if isLandscape {
            // In 90°-clockwise rotated landscape HUD, the visual top edge sits along portrait's right edge.
            let targetX = max(56, min(w - 30, w - sideBarW - 22))
            let targetY = h * 0.5
            badgeContent
                .rotationEffect(.degrees(90))
                .position(x: targetX, y: targetY)
        } else {
            // Keep safely below top bar in portrait
            let targetY = max(124, topBarH - 18)
            badgeContent
                .position(x: w * 0.5, y: targetY)
        }
    }
}

private struct MatteCornerBrackets: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let arm: CGFloat = 16

            Path { path in
                // Top-left L
                path.move(to: CGPoint(x: 0, y: arm))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: arm, y: 0))

                // Top-right L
                path.move(to: CGPoint(x: w - arm, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: arm))

                // Bottom-left L
                path.move(to: CGPoint(x: 0, y: h - arm))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: arm, y: h))

                // Bottom-right L
                path.move(to: CGPoint(x: w - arm, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w, y: h - arm))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
        }
    }
}


// MARK: - =====================================================================
// 18. UI SHAPES & HELPERS
// =====================================================================

struct CinematicReticleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arm: CGFloat = min(rect.width, rect.height) * 0.24

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
            .stroke(Color.white.opacity(0.32), lineWidth: 0.7)
        }
    }
}

struct ZebraStripesOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Canvas { context, size in
                    let spacing: CGFloat = 12
                    var x: CGFloat = -size.height
                    while x < size.width + size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + size.height * 0.45, y: size.height))
                        context.stroke(path, with: .color(Color.yellow.opacity(0.14)), lineWidth: 2)
                        x += spacing
                    }
                }
                Text("ZEBRA 95% IRE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(.top, 110)
                    .padding(.trailing, 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct FocusPeakingOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                    )
                    .foregroundColor(Color.cyan.opacity(0.55))
                    .padding(14)

                Text("PEAKING CYAN")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(.top, 110)
                    .padding(.leading, 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
