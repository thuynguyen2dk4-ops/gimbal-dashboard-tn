//
//  CameraStudioNativeView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Đồng bộ chuẩn Figma Node 96:3 (Apple HIG): Basic (01), Pro (02), Recording (03),
//  Quick Settings 8 ô (04), Aspect Picker (05), Gimbal Mode Dial (06),
//  AI Multi-Target Touch Lock (07), Pro Controls Ruler (09) & Motionlapse 2 điểm (10).
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraStudioNativeView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme

    // Transient HUD Overlays (Mutually exclusive overlays keep viewfinder clean)
    @State private var showQuickSettingsDropdown: Bool = false
    @State private var showAspectBar: Bool = false
    @State private var showGimbalDial: Bool = false
    @State private var showAiModeMenu: Bool = false
    @State private var showProManualOverlay: Bool = false

    // Modal Sheets
    @State private var showAdvancedHudSheet: Bool = false
    @State private var showAspectSheet: Bool = false
    @State private var showProFullSheet: Bool = false
    @State private var showPaywallSheet: Bool = false

    // Auto-hide Controls
    @State private var controlsHidden: Bool = false
    @State private var autoHideWorkItem: DispatchWorkItem? = nil

    // Interactive Motionlapse Scrub Preview
    @State private var motionlapseProgress: Double = 0.35

    private let goldAccent = Color(red: 1.0, green: 0.84, blue: 0.04)     // #FFD60A
    private let lightGoldInk = Color(red: 0.73, green: 0.53, blue: 0.0)   // #B98700
    private let recRed = Color(red: 1.0, green: 0.23, blue: 0.19)         // #FF3B30

    private var isLightTheme: Bool { colorScheme == .light }
    private var activeGoldInk: Color { isLightTheme ? lightGoldInk : goldAccent }
    private var hudPrimaryInk: Color { isLightTheme ? Color.black : Color.white }
    private var hudSecondaryInk: Color { isLightTheme ? Color.black.opacity(0.65) : Color.white.opacity(0.76) }
    private var hudHairline: Color { isLightTheme ? Color.black.opacity(0.10) : Color.white.opacity(0.16) }

    private var isPhotoLikeMode: Bool {
        camera.selectedMode == "ẢNH"
            || camera.selectedMode == "PHOTO"
            || camera.selectedMode == "PANO"
            || camera.selectedMode == "PORTRAIT"
    }

    private var activeZoomOptions: [String] {
        camera.isProMode ? [".5", "1x", "2", "5"] : [".5", "1x", "2"]
    }

    private let figmaModes: [String] = ["TIMELAPSE", "SLO-MO", "VIDEO", "ẢNH", "PANO"]

    private var hasTransientOverlayOpen: Bool {
        showQuickSettingsDropdown || showAspectBar || showGimbalDial || showAiModeMenu || showProManualOverlay
    }

    var body: some View {
        GeometryReader { geo in
            let physicalLandscape = geo.size.width > geo.size.height
            let simulatedLandscape = camera.isLandscapeMode && !physicalLandscape
            let effectiveLandscape = physicalLandscape || camera.isLandscapeMode
            let hudSize = simulatedLandscape
                ? CGSize(width: geo.size.height, height: geo.size.width)
                : geo.size

            ZStack {
                // 1. Native Camera Preview + Adaptive Scrims (Non-blocking)
                viewfinderVisualLayer(size: geo.size)
                    .allowsHitTesting(false)

                // 2. Viewfinder Tap / Drag Surface for Multi-Target AI Object Lock & HUD Reveal
                viewfinderGestureSurface(size: geo.size)

                // 3. Aspect Ratio Frame Matte (Supporting 9:16..2.39:1 + quick "Đặt lại 9:16")
                AspectLetterboxMaskView(
                    ratio: camera.selectedAspectRatio,
                    screenSize: geo.size,
                    isLandscape: camera.isLandscapeMode,
                    onResetToFullFrame: {
                        if !camera.isRecording {
                            camera.setAspectRatio("9:16")
                        }
                    }
                )

                // 4. Overlays (Grid 3x3, Zebra, Peaking, Motionlapse A-B Path, Horizon, AI Reticle)
                viewfinderOverlayLayer(size: geo.size)

                // 5. Internal Portrait / 90° Rotated Landscape HUD Chrome
                hudChrome(hudSize: hudSize, isLandscape: effectiveLandscape)
                    .frame(width: hudSize.width, height: hudSize.height)
                    .rotationEffect(.degrees(simulatedLandscape ? 90 : 0))
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                    .animation(.spring(response: 0.36, dampingFraction: 0.86), value: effectiveLandscape)
                    .allowsHitTesting(!camera.touchLockEnabled)

                // 6. Floating Touch-Lock Unlock Pill & BLE Toast (Always above hit-block)
                floatingTopBanners(isLandscape: effectiveLandscape)
                    .frame(width: hudSize.width, height: hudSize.height)
                    .rotationEffect(.degrees(simulatedLandscape ? 90 : 0))
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                    .animation(.spring(response: 0.36, dampingFraction: 0.86), value: effectiveLandscape)
            }
        }
        .onAppear {
            camera.setupSession()
            enforceModulePermissions()
        }
        .onDisappear {
            camera.stopSession()
        }
        .onChange(of: camera.lastCaptureError) { err in
            if let err = err, !err.isEmpty {
                ble.showToast(err)
            }
        }
        .onChange(of: store.modules) { _ in
            enforceModulePermissions()
        }
        .onChange(of: camera.isProMode) { isPro in
            if !isPro {
                showProManualOverlay = false
            }
        }
        .onChange(of: camera.isRecording) { recording in
            if recording {
                closeTransientOverlays()
                scheduleAutoHideIfNeeded()
            } else {
                cancelAutoHide()
            }
        }
        .onChange(of: camera.autoHideControls3s) { enabled in
            if enabled && camera.isRecording {
                scheduleAutoHideIfNeeded()
            } else {
                cancelAutoHide()
            }
        }
        .onChange(of: camera.detectedFaceRect) { newFace in
            guard store.isOnline,
                  store.isAiVisionAllowed,
                  camera.aiTrackingEnabled,
                  camera.aiTargetMode == .human,
                  camera.customObjectLockedPoint == nil,
                  let face = newFace else { return }
            let dx = Double(face.midX - 0.5)
            let dy = Double(face.midY - 0.5)
            ble.sendTrackingError(dx: dx, dy: dy)
        }
        .onChange(of: camera.customObjectLockedPoint) { newPoint in
            guard store.isOnline,
                  store.isAiVisionAllowed,
                  camera.aiTrackingEnabled,
                  let pt = newPoint else { return }
            let dx = Double(pt.x - 0.5)
            let dy = Double(pt.y - 0.5)
            ble.sendTrackingError(dx: dx, dy: dy)
        }
        .sheet(isPresented: $showAspectSheet) {
            AspectPickerSheetView(selectedRatio: $camera.selectedAspectRatio) { ratio in
                if !camera.isRecording {
                    camera.setAspectRatio(ratio)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAdvancedHudSheet) {
            QuickSettingsSheetView(camera: camera, store: store)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showProFullSheet) {
            ProManualControlsSheetView(camera: camera, store: store)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPaywallSheet) {
            SubscriptionPaywallSheetView(store: store)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $ble.showCalibrationModal) {
            AutoCalibrationModalView(ble: ble)
                .presentationDetents([.medium])
        }
    }

    // MARK: - 1. Viewfinder Visuals & Gestures

    @ViewBuilder
    private func viewfinderVisualLayer(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: isLightTheme
                    ? [Color(red: 0.87, green: 0.90, blue: 0.95), Color(red: 0.78, green: 0.83, blue: 0.90)]
                    : [Color(red: 0.05, green: 0.07, blue: 0.11), Color(red: 0.02, green: 0.02, blue: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            NativeCameraPreviewRepresentable(
                session: camera.captureSession,
                isFrontCamera: camera.isFrontCamera
            )
            .ignoresSafeArea()

            // Subtle Figma Top/Bottom Legibility Scrims
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        isLightTheme ? Color.white.opacity(0.16) : Color.black.opacity(0.42),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)

                Spacer()

                if !isLightTheme {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.28),
                            Color.black.opacity(0.62)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 260)
                }
            }
            .ignoresSafeArea()

            if camera.shutterFlash {
                Color.white.opacity(0.68).ignoresSafeArea()
            }
        }
    }

    private func viewfinderGestureSurface(size: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        revealControlsAndBumpTimer()
                        if hasTransientOverlayOpen {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                closeTransientOverlays()
                            }
                            return
                        }
                        guard !camera.touchLockEnabled else { return }
                        if store.isAiVisionAllowed {
                            let norm = normalizedPoint(from: value.location, in: size)
                            camera.lockObjectAtNormalizedPoint(norm, label: lockLabelForCurrentTarget)
                        } else {
                            showPaywallSheet = true
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard !camera.touchLockEnabled, !hasTransientOverlayOpen, store.isAiVisionAllowed else { return }
                        let norm = normalizedPoint(from: value.location, in: size)
                        camera.lockObjectAtNormalizedPoint(norm, label: lockLabelForCurrentTarget)
                    }
            )
    }

    private var lockLabelForCurrentTarget: String {
        switch camera.aiTargetMode {
        case .human: return "Người đã chọn"
        case .pet: return "Thú cưng"
        case .object: return "Vật thể đã chọn"
        }
    }

    private func normalizedPoint(from location: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(0.92, max(0.08, location.x / max(1, size.width))),
            y: min(0.84, max(0.16, location.y / max(1, size.height)))
        )
    }

    // MARK: - 2. Viewfinder Overlays (Guides, Horizon, Motionlapse Path, AI Reticle)

    @ViewBuilder
    private func viewfinderOverlayLayer(size: CGSize) -> some View {
        ZStack {
            if camera.gridEnabled {
                RuleOfThirdsGridView()
                    .allowsHitTesting(false)
            }
            if camera.zebraEnabled {
                ZebraStripesOverlayView()
                    .allowsHitTesting(false)
            }
            if camera.peakingEnabled {
                FocusPeakingOverlayView()
                    .allowsHitTesting(false)
            }

            let physicalLandscape = size.width > size.height
            let rotate90 = camera.isLandscapeMode && !physicalLandscape

            if camera.isProMode && camera.showHorizonLevel && !hasTransientOverlayOpen {
                horizonLevelIndicator
                    .rotationEffect(.degrees(rotate90 ? 90 : 0))
                    .allowsHitTesting(false)
            }

            // Motionlapse 2-Point A -> B Dashed Trajectory Overlay (10_timelapse_pano)
            if camera.selectedMode == "TIMELAPSE" && !camera.isRecording {
                motionlapsePathOverlay(size: size)
            }

            // AI Multi-Target Tracking Box (07_ai_tracking_dark)
            if camera.aiTrackingEnabled && store.isAiVisionAllowed {
                aiTrackingOverlay(size: size)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private func aiTrackingOverlay(size: CGSize) -> some View {
        let rotate90 = camera.isLandscapeMode && !(size.width > size.height)
        if let tracked = camera.trackedObjectRect {
            let boxW = max(110, tracked.width * size.width)
            let boxH = max(136, tracked.height * size.height)
            trackingReticleBox(
                center: CGPoint(x: tracked.midX * size.width, y: tracked.midY * size.height),
                size: CGSize(width: boxW, height: boxH),
                badgeText: "Đang bám • \(camera.customObjectLabel)",
                iconName: targetIconName(camera.aiTargetMode),
                rotate90: rotate90
            ) {
                camera.clearLockedObject()
            }
        } else if let lockedPt = camera.customObjectLockedPoint {
            let boxW: CGFloat = camera.aiTargetMode == .object ? 148 : 172
            let boxH: CGFloat = camera.aiTargetMode == .object ? 148 : 206
            trackingReticleBox(
                center: CGPoint(x: lockedPt.x * size.width, y: lockedPt.y * size.height),
                size: CGSize(width: boxW, height: boxH),
                badgeText: "Đang bám • \(camera.customObjectLabel)",
                iconName: targetIconName(camera.aiTargetMode),
                rotate90: rotate90
            ) {
                camera.clearLockedObject()
            }
        } else if camera.aiTargetMode == .human, let face = camera.detectedFaceRect {
            let boxW = max(110, face.width * size.width)
            let boxH = max(136, face.height * size.height)
            trackingReticleBox(
                center: CGPoint(x: face.midX * size.width, y: face.midY * size.height),
                size: CGSize(width: boxW, height: boxH),
                badgeText: "Đang bám • AI 60fps",
                iconName: "person.crop.viewfinder",
                rotate90: rotate90
            ) {
                camera.aiTrackingEnabled = false
            }
        } else if camera.aiTargetMode == .object || camera.aiTargetMode == .pet {
            Text(camera.aiTargetMode == .pet ? "Chạm hoặc kéo lên thú cưng để khóa bám" : "Chạm hoặc kéo lên vật thể để khóa bám")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(hudPrimaryInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(glassPillBackground(cornerRadius: 14))
                .position(x: size.width * 0.5, y: size.height * 0.42)
                .rotationEffect(.degrees(rotate90 ? 90 : 0))
                .allowsHitTesting(false)
        }
    }

    private func trackingReticleBox(
        center: CGPoint,
        size boxSize: CGSize,
        badgeText: String,
        iconName: String,
        rotate90: Bool,
        onClear: @escaping () -> Void
    ) -> some View {
        ZStack {
            // Soft outer frame
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(goldAccent.opacity(0.28), lineWidth: 1)
                .frame(width: boxSize.width, height: boxSize.height)
                .allowsHitTesting(false)

            // 4 Gold L-Corners
            CinematicReticleShape()
                .stroke(goldAccent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                .frame(width: boxSize.width, height: boxSize.height)
                .allowsHitTesting(false)

            // Center Aim Crosshair + Dot
            ZStack {
                Rectangle().fill(goldAccent.opacity(0.75)).frame(width: 12, height: 1.2)
                Rectangle().fill(goldAccent.opacity(0.75)).frame(width: 1.2, height: 12)
                Circle().fill(goldAccent).frame(width: 5, height: 5)
            }
            .allowsHitTesting(false)

            // Floating Top Badge + Unlock (X) Button
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: iconName)
                        .font(.system(size: 11, weight: .bold))
                    Text(badgeText)
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(goldAccent))

                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(hudPrimaryInk)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.ultraThinMaterial))
                        .overlay(Circle().stroke(hudHairline, lineWidth: 0.6))
                }
                .buttonStyle(.plain)
            }
            .rotationEffect(.degrees(rotate90 ? 90 : 0))
            .offset(
                x: rotate90 ? (boxSize.width * 0.5 + 24) : 0,
                y: rotate90 ? 0 : -(boxSize.height * 0.5 + 22)
            )
        }
        .position(center)
    }

    private func motionlapsePathOverlay(size: CGSize) -> some View {
        let ptA = CGPoint(x: camera.motionlapsePointA.x * size.width, y: camera.motionlapsePointA.y * size.height)
        let ptB = CGPoint(x: camera.motionlapsePointB.x * size.width, y: camera.motionlapsePointB.y * size.height)
        let rotate90 = camera.isLandscapeMode && !(size.width > size.height)

        return ZStack {
            if camera.motionlapseHasPointB {
                Path { path in
                    path.move(to: ptA)
                    path.addLine(to: ptB)
                }
                .stroke(goldAccent.opacity(0.85), style: StrokeStyle(lineWidth: 1.6, dash: [6, 5]))
                .allowsHitTesting(false)
            }

            motionlapseHandle(letter: "A", point: ptA, rotate90: rotate90)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            camera.motionlapsePointA = normalizedPoint(from: value.location, in: size)
                        }
                )

            if camera.motionlapseHasPointB {
                motionlapseHandle(letter: "B", point: ptB, rotate90: rotate90)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                camera.motionlapsePointB = normalizedPoint(from: value.location, in: size)
                            }
                    )
            }
        }
    }

    private func motionlapseHandle(letter: String, point: CGPoint, rotate90: Bool) -> some View {
        Text(letter)
            .font(.system(size: 11, weight: .heavy))
            .foregroundColor(goldAccent)
            .frame(width: 24, height: 24)
            .background(Circle().fill(Color.black.opacity(0.55)))
            .overlay(Circle().stroke(goldAccent, lineWidth: 1.6))
            .rotationEffect(.degrees(rotate90 ? 90 : 0))
            .position(point)
    }

    private var horizonLevelIndicator: some View {
        let isLevel = abs(ble.rollAngle) < 1.5
        let tintColor = isLevel ? Color.green : goldAccent
        return HStack(spacing: 8) {
            Rectangle()
                .fill(tintColor.opacity(0.85))
                .frame(width: 34, height: 1.5)
            Text(String(format: "%.1f°", ble.rollAngle))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(tintColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .overlay(Capsule().stroke(tintColor.opacity(0.6), lineWidth: 0.8))
            Rectangle()
                .fill(tintColor.opacity(0.85))
                .frame(width: 34, height: 1.5)
        }
        .rotationEffect(.degrees(ble.rollAngle))
    }

    // MARK: - 3. Unified HUD Chrome (Portrait & Landscape)

    @ViewBuilder
    private func hudChrome(hudSize: CGSize, isLandscape: Bool) -> some View {
        ZStack {
            if isLandscape {
                landscapeHudBody(hudSize: hudSize)
            } else {
                portraitHudBody(hudSize: hudSize)
            }

            // Dimmer + Quick Settings 8-Tile Dropdown (04_camera_menu_dropdown)
            if showQuickSettingsDropdown {
                Color.black.opacity(isLightTheme ? 0.14 : 0.30)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showQuickSettingsDropdown = false
                        }
                    }

                VStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        QuickSettingsDropdownCard(
                            camera: camera,
                            ble: ble,
                            store: store,
                            isLandscape: isLandscape,
                            onOpenAspectBar: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    showQuickSettingsDropdown = false
                                    showAspectBar = true
                                }
                            },
                            onOpenAdvancedSheet: {
                                showQuickSettingsDropdown = false
                                showAdvancedHudSheet = true
                            },
                            onClose: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    showQuickSettingsDropdown = false
                                }
                            }
                        )
                    }
                    .frame(maxWidth: isLandscape ? 540 : .infinity, maxHeight: max(220, hudSize.height - (isLandscape ? 24 : 128)))
                    .padding(.horizontal, isLandscape ? 16 : 12)
                    .padding(.top, isLandscape ? 10 : 54)
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Portrait HUD Layout (01_camera_basic & 02_camera_pro)

    private func portraitHudBody(hudSize: CGSize) -> some View {
        VStack(spacing: 0) {
            // Top Bar (Basic 3 items vs Pro Readout Bar)
            Group {
                if camera.isProMode {
                    portraitProTopSection
                } else {
                    portraitBasicTopBar
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .opacity(controlsHidden ? 0.08 : 1.0)

            Spacer(minLength: 8)

            // Contextual Transient Panel or Motionlapse Panel
            transientPanelSlot(isLandscape: false, maxHeight: min(360, hudSize.height * 0.48))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

            // Slim Direct Quick Chips (Aspect Ratio [9:16], AI Target, Copilot)
            if !controlsHidden && !camera.isRecording {
                utilityPillRow
                    .padding(.bottom, 10)
            }

            // Zoom Pill (.5, 1x, 2 [, 5])
            if !controlsHidden {
                zoomPillBar(vertical: false)
                    .padding(.bottom, 12)
            }

            // 5 Capture Modes (TIMELAPSE | SLO-MO | VIDEO | ẢNH | PANO)
            if !controlsHidden && !camera.isRecording {
                modeSelectorStrip(vertical: false)
                    .padding(.bottom, 14)
            }

            // Bottom Shutter Row (Thumbnail | Shutter | Flip/Still)
            HStack(spacing: 0) {
                galleryThumbButton
                Spacer()
                shutterButton
                Spacer()
                rightShutterActionButton
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Landscape 90° HUD Layout (01_camera_basic_land & 02_camera_pro_land)

    private func landscapeHudBody(hudSize: CGSize) -> some View {
        HStack(spacing: 10) {
            // Left Viewport & Top Readouts Area
            VStack(spacing: 8) {
                // Top Row: Flash + Portrait Return + Pro Readout / Gimbal Pill + Menu
                HStack(spacing: 8) {
                    flashCircleButton(size: 36)

                    // Quick Exit Landscape pill so portrait users can return 1-tap
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            camera.isLandscapeMode = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rotate.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Dọc")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(hudPrimaryInk)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(glassPillBackground(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    if camera.isRecording && !camera.isProMode {
                        recordingTimecodePill
                    }

                    if camera.isProMode {
                        proReadoutCapsule
                            .layoutPriority(1)
                    } else if !camera.isRecording {
                        Spacer(minLength: 4)
                        gimbalStatusPill
                        Spacer(minLength: 4)
                    } else {
                        Spacer(minLength: 4)
                    }

                    quickMenuChevronButton(size: 36)
                }

                // Pro Row 2 in Landscape: FOLLOW + BLE + Histogram
                if camera.isProMode {
                    HStack(alignment: .top, spacing: 8) {
                        gimbalModeChip
                        bleLinkChip
                        Spacer()
                        if camera.showHistogram {
                            MiniRGBHistogramView()
                        }
                    }
                }

                Spacer(minLength: 4)

                // Contextual Overlay / Motionlapse Panel in Landscape
                transientPanelSlot(isLandscape: true, maxHeight: max(180, hudSize.height - 96))

                if !controlsHidden && !camera.isRecording {
                    utilityPillRow
                }
            }
            .padding(.vertical, 12)
            .padding(.leading, 14)

            // Right Controls Columns (Zoom | Modes | ShutterBar)
            HStack(spacing: 12) {
                if !controlsHidden {
                    zoomPillBar(vertical: true)
                }

                if !controlsHidden && !camera.isRecording {
                    modeSelectorStrip(vertical: true)
                }

                VStack {
                    rightShutterActionButton
                    Spacer()
                    shutterButton
                    Spacer()
                    galleryThumbButton
                }
                .padding(.vertical, 16)
            }
            .padding(.trailing, 14)
        }
    }

    // MARK: - Top Bar Components

    private var portraitBasicTopBar: some View {
        HStack {
            HStack(spacing: 8) {
                flashCircleButton(size: 38)
                if camera.isRecording {
                    gimbalCompactBatteryPill
                }
            }

            Spacer()

            if camera.isRecording {
                recordingTimecodePill
            } else {
                gimbalStatusPill
            }

            Spacer()

            quickMenuChevronButton(size: 38)
        }
    }

    private var portraitProTopSection: some View {
        VStack(spacing: 8) {
            // Row 1: Flash, REC badge (if recording), Menu Chevron
            HStack {
                flashCircleButton(size: 38)
                Spacer()
                if camera.isRecording {
                    recordingTimecodePill
                }
                Spacer()
                quickMenuChevronButton(size: 38)
            }

            // Row 2: Full-width ProReadoutBar Capsule
            proReadoutCapsule

            // Row 3: Left Chips (FOLLOW + BLE 92%) & Right Histogram
            HStack(alignment: .top, spacing: 8) {
                gimbalModeChip
                bleLinkChip
                Spacer()
                if camera.showHistogram {
                    MiniRGBHistogramView()
                }
            }
        }
    }

    private func flashCircleButton(size: CGFloat) -> some View {
        Button {
            camera.toggleFlash()
        } label: {
            Image(systemName: camera.isFlashEnabled ? "bolt.fill" : "bolt")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(camera.isFlashEnabled ? .black : hudPrimaryInk)
                .frame(width: size, height: size)
                .background(
                    Group {
                        if camera.isFlashEnabled {
                            Circle().fill(goldAccent)
                        } else {
                            Circle().fill(.ultraThinMaterial)
                        }
                    }
                )
                .overlay(Circle().stroke(camera.isFlashEnabled ? Color.clear : hudHairline, lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }

    private func quickMenuChevronButton(size: CGFloat) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                let next = !showQuickSettingsDropdown
                closeTransientOverlays()
                showQuickSettingsDropdown = next
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundColor(showQuickSettingsDropdown ? .black : hudPrimaryInk)
                .rotationEffect(.degrees(showQuickSettingsDropdown ? 180 : 0))
                .frame(width: size, height: size)
                .background(
                    Group {
                        if showQuickSettingsDropdown {
                            Circle().fill(goldAccent)
                        } else {
                            Circle().fill(.ultraThinMaterial)
                        }
                    }
                )
                .overlay(Circle().stroke(showQuickSettingsDropdown ? Color.clear : hudHairline, lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }

    private var gimbalStatusPill: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if !ble.isConnected {
                store.showPairingModal = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    let next = !showGimbalDial
                    closeTransientOverlays()
                    showGimbalDial = next
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(ble.isConnected ? Color.green : goldAccent)
                    .frame(width: 7, height: 7)
                    .shadow(color: (ble.isConnected ? Color.green : goldAccent).opacity(0.35), radius: 3)

                Image(systemName: "gyroscope")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(hudPrimaryInk)

                Text(ble.isConnected ? "Smart Gimbal S1" : "Ghép nối Gimbal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(hudPrimaryInk)
                    .lineLimit(1)

                Rectangle()
                    .fill(hudHairline)
                    .frame(width: 0.6, height: 12)

                Image(systemName: "battery.75")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(hudPrimaryInk)

                Text("\(ble.batteryLevel)%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(hudPrimaryInk)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(glassPillBackground(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.showPairingModal = true
                }
        )
    }

    private var gimbalCompactBatteryPill: some View {
        Button {
            store.showPairingModal = true
        } label: {
            HStack(spacing: 5) {
                Circle().fill(ble.isConnected ? Color.green : goldAccent).frame(width: 6, height: 6)
                Image(systemName: "gyroscope").font(.system(size: 11, weight: .semibold))
                Text("\(ble.batteryLevel)%")
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(hudPrimaryInk)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(glassPillBackground(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    private var recordingTimecodePill: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.white).frame(width: 7, height: 7)
            Text(camera.recordingDuration)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(recRed))
    }

    private var proReadoutCapsule: some View {
        let resShort = camera.selectedResolution.replacingOccurrences(of: " • ", with: " ")
        let shutterShort = camera.shutterSpeed.replacingOccurrences(of: "s", with: "")
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                let next = !showProManualOverlay
                closeTransientOverlays()
                showProManualOverlay = next
            }
        } label: {
            HStack(spacing: 0) {
                Text(resShort)
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                spacerDivider
                HStack(spacing: 2) {
                    Text("ISO").font(.system(size: 9, weight: .bold)).foregroundColor(hudSecondaryInk)
                    Text("\(camera.iso)").font(.system(size: 11.5, weight: .bold, design: .monospaced)).foregroundColor(activeGoldInk)
                }
                spacerDivider
                Text(shutterShort)
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                spacerDivider
                Text("\(camera.wbKelvin)K")
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                spacerDivider
                Text("F1.8")
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                spacerDivider
                Text(camera.isRecording ? camera.recordingDuration : "00:04:18")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(camera.isRecording ? recRed : hudPrimaryInk)
            }
            .foregroundColor(hudPrimaryInk)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .background(glassPillBackground(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    showProFullSheet = true
                }
        )
    }

    private var spacerDivider: some View {
        Group {
            Spacer(minLength: 2)
            Rectangle()
                .fill(hudHairline)
                .frame(width: 0.6, height: 12)
            Spacer(minLength: 2)
        }
    }

    private var gimbalModeChip: some View {
        let modeText: String = {
            switch ble.gimbalMode.uppercased() {
            case "PF": return "FOLLOW"
            default: return ble.gimbalMode.uppercased()
            }
        }()

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                let next = !showGimbalDial
                closeTransientOverlays()
                showGimbalDial = next
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "gyroscope")
                    .font(.system(size: 12, weight: .bold))
                Text(modeText)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
            }
            .foregroundColor(showGimbalDial ? .black : hudPrimaryInk)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(
                Group {
                    if showGimbalDial {
                        Capsule().fill(goldAccent)
                    } else {
                        glassPillBackground(cornerRadius: 13)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var bleLinkChip: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            store.showPairingModal = true
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(ble.isConnected ? Color.green : goldAccent)
                    .frame(width: 6, height: 6)
                Text("BLE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(hudSecondaryInk)
                Text("\(ble.batteryLevel)%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(hudPrimaryInk)
            }
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(glassPillBackground(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Transient Panels Slot (Aspect Bar / Gimbal Dial / AI Selector / Pro Controls / Motionlapse)

    @ViewBuilder
    private func transientPanelSlot(isLandscape: Bool, maxHeight: CGFloat) -> some View {
        if showAspectBar && !camera.isRecording {
            ScrollView(.horizontal, showsIndicators: false) {
                AspectRatioPickerBar(
                    selectedRatio: camera.selectedAspectRatio,
                    onSelect: { ratio in
                        camera.setAspectRatio(ratio)
                    },
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showAspectBar = false
                        }
                    }
                )
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else if showGimbalDial {
            gimbalModeDialView(isLandscape: isLandscape)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else if showAiModeMenu {
            aiTargetSelectorCard
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else if showProManualOverlay {
            ScrollView(.vertical, showsIndicators: false) {
                ProManualControlsSheetView(
                    camera: camera,
                    store: store,
                    isOverlayPanel: true,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showProManualOverlay = false
                        }
                    },
                    onRequirePaywall: {
                        showProManualOverlay = false
                        showPaywallSheet = true
                    }
                )
            }
            .frame(maxWidth: isLandscape ? 330 : .infinity, maxHeight: maxHeight)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else if camera.selectedMode == "TIMELAPSE" && !camera.isRecording {
            motionlapsePanelView(isLandscape: isLandscape)
                .frame(maxWidth: isLandscape ? 480 : .infinity)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Slim Direct Utility Strip (Aspect Chip + AI Multi-Target + AI Copilot)

    private var utilityPillRow: some View {
        HStack(spacing: 8) {
            // Instant Aspect Ratio chip (Works directly in BOTH Basic & Pro)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    guard !camera.isRecording else {
                        ble.showToast("Không thể đổi tỉ lệ khung hình khi đang ghi")
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        let next = !showAspectBar
                        closeTransientOverlays()
                        showAspectBar = next
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "aspectratio")
                            .font(.system(size: 10.5, weight: .bold))
                        Text(camera.selectedAspectRatio)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(camera.selectedAspectRatio != "9:16" ? .black : hudPrimaryInk)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(
                        Group {
                            if camera.selectedAspectRatio != "9:16" {
                                Capsule().fill(goldAccent)
                            } else {
                                glassPillBackground(cornerRadius: 13)
                            }
                        }
                    )
                    .opacity(camera.isRecording ? 0.45 : 1.0)
                }
                .buttonStyle(.plain)
                .disabled(camera.isRecording)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.45)
                        .onEnded { _ in
                            if !camera.isRecording {
                                camera.setAspectRatio("9:16")
                            }
                        }
                )

            // Compact AI Target Selector pill
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if !store.isAiVisionAllowed {
                    showPaywallSheet = true
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        let next = !showAiModeMenu
                        closeTransientOverlays()
                        showAiModeMenu = next
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: targetIconName(camera.aiTargetMode))
                        .font(.system(size: 10.5, weight: .bold))
                    Text(camera.aiTrackingEnabled && store.isAiVisionAllowed ? "AI • \(camera.aiTargetMode.rawValue)" : "AI Tắt")
                        .font(.system(size: 11, weight: .bold))
                    if camera.autoGroupFraming05x {
                        Text(".5x")
                            .font(.system(size: 9.5, weight: .black, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.black.opacity(0.18)))
                    }
                }
                .foregroundColor((camera.aiTrackingEnabled && store.isAiVisionAllowed) ? .black : hudPrimaryInk)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(
                    Group {
                        if camera.aiTrackingEnabled && store.isAiVisionAllowed {
                            Capsule().fill(goldAccent)
                        } else {
                            glassPillBackground(cornerRadius: 13)
                        }
                    }
                )
            }
            .buttonStyle(.plain)

            // AI Copilot Pill (sparkles -> store.showAiCopilotSheet = true)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.showAiCopilotSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(activeGoldInk)
                    Text("Copilot")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(hudPrimaryInk)
                }
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(glassPillBackground(cornerRadius: 13))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - AI Multi-Target Selector Card (07_ai_tracking)

    private var aiTargetSelectorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AI Theo Dõi Đa Mục Tiêu")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(hudPrimaryInk)
                Spacer()
                Toggle("", isOn: $camera.aiTrackingEnabled)
                    .labelsHidden()
                    .tint(goldAccent)
            }

            HStack(spacing: 8) {
                aiModeOptionButton(mode: .human, emoji: "👤", label: "Người")
                aiModeOptionButton(mode: .pet, emoji: "🐾", label: "Thú cưng")
                aiModeOptionButton(mode: .object, emoji: "🎯", label: "Khóa vật thể")
            }

            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    camera.setAutoGroupFraming(!camera.autoGroupFraming05x)
                } label: {
                    HStack(spacing: 5) {
                        Text("👥 Auto 0.5x")
                            .font(.system(size: 11.5, weight: .bold))
                    }
                    .foregroundColor(camera.autoGroupFraming05x ? .black : hudPrimaryInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(camera.autoGroupFraming05x ? goldAccent : (isLightTheme ? Color.black.opacity(0.08) : Color.white.opacity(0.12)))
                    )
                }
                .buttonStyle(.plain)

                if camera.customObjectLockedPoint != nil {
                    Button {
                        camera.clearLockedObject()
                    } label: {
                        Text("Bỏ khóa điểm")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(hudPrimaryInk)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(isLightTheme ? Color.black.opacity(0.08) : Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Xong") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showAiModeMenu = false
                    }
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(activeGoldInk)
            }
        }
        .padding(14)
        .background(glassPillBackground(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.24), radius: 16, y: 6)
    }

    private func aiModeOptionButton(mode: AITargetMode, emoji: String, label: String) -> some View {
        let isSelected = camera.aiTargetMode == mode
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            camera.aiTargetMode = mode
            camera.aiTrackingEnabled = true
            if mode == .human {
                camera.clearLockedObject()
            }
        } label: {
            VStack(spacing: 3) {
                Text(emoji).font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10.5, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(isSelected ? .black : hudPrimaryInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? goldAccent : (isLightTheme ? Color.black.opacity(0.06) : Color.white.opacity(0.10)))
            )
        }
        .buttonStyle(.plain)
    }

    private func targetIconName(_ mode: AITargetMode) -> String {
        switch mode {
        case .human: return "person.crop.viewfinder"
        case .pet: return "pawprint.fill"
        case .object: return "scope"
        }
    }

    // MARK: - Gimbal Mode Dial (06_gimbal_mode)

    private struct GimbalDialItem: Identifiable {
        let id: String
        let badge: String
        let title: String
        let description: String
    }

    private let dialItems: [GimbalDialItem] = [
        GimbalDialItem(id: "LOCK", badge: "L", title: "Khoá", description: "Khoá 3 trục tuyệt đối, cố định góc máy"),
        GimbalDialItem(id: "Follow", badge: "F", title: "Follow", description: "Xoay mượt Pan & Tilt theo chuyển động tay"),
        GimbalDialItem(id: "PF", badge: "PF", title: "Pan Follow (PF)", description: "Khoá trục Tilt & Roll, xoay mượt theo tay"),
        GimbalDialItem(id: "FPV", badge: "FPV", title: "FPV", description: "Theo cả 3 trục điện ảnh góc nhìn thứ nhất"),
        GimbalDialItem(id: "360°", badge: "3D", title: "Inception", description: "Xoay cuộn 360° Roll hiệu ứng điện ảnh")
    ]

    private func isDialItemSelected(_ itemId: String) -> Bool {
        let current = ble.gimbalMode.uppercased()
        if itemId == "LOCK" { return current == "LOCK" }
        if itemId == "Follow" { return current == "FOLLOW" }
        if itemId == "PF" { return current == "PF" }
        if itemId == "FPV" { return current == "FPV" || current == "POV" }
        return current == itemId.uppercased()
    }

    private func gimbalModeDialView(isLandscape: Bool) -> some View {
        let activeItem = dialItems.first(where: { isDialItemSelected($0.id) }) ?? dialItems[2]

        return VStack(spacing: isLandscape ? 8 : 10) {
            HStack(spacing: 8) {
                Text("Chế độ: \(activeItem.title)")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(hudPrimaryInk)
                Spacer()
                Button {
                    showGimbalDial = false
                    store.showPairingModal = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 10.5, weight: .bold))
                        Text("BLE \(ble.batteryLevel)%")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundColor(hudPrimaryInk)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(isLightTheme ? Color.black.opacity(0.08) : Color.white.opacity(0.14)))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showGimbalDial = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(hudPrimaryInk)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(isLightTheme ? Color.black.opacity(0.08) : Color.white.opacity(0.14)))
                }
                .buttonStyle(.plain)
            }

            Text(activeItem.description)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(hudSecondaryInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 10) {
                ForEach(dialItems) { item in
                    let isSelected = isDialItemSelected(item.id)
                    Button {
                        ble.setGimbalModeWithHaptic(item.id)
                    } label: {
                        VStack(spacing: 5) {
                            Text(item.badge)
                                .font(.system(size: isSelected ? 14 : 12, weight: .bold, design: .monospaced))
                                .foregroundColor(isSelected ? .black : hudPrimaryInk)
                                .frame(width: isSelected ? 46 : 40, height: isSelected ? 46 : 40)
                                .background(
                                    Circle().fill(isSelected ? goldAccent : (isLightTheme ? Color.white.opacity(0.75) : Color.white.opacity(0.12)))
                                )
                                .overlay(
                                    Circle().stroke(isSelected ? Color.clear : hudHairline, lineWidth: 0.6)
                                )
                            Text(item.id == "PF" ? "Pan Follow" : item.title)
                                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? activeGoldInk : hudSecondaryInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Ruler tick decorative strip with gold indicator needle
            ZStack {
                HStack(spacing: 6) {
                    ForEach(0..<25, id: \.self) { _ in
                        Rectangle()
                            .fill(hudSecondaryInk.opacity(0.45))
                            .frame(width: 1, height: 6)
                    }
                }
                RoundedRectangle(cornerRadius: 1)
                    .fill(goldAccent)
                    .frame(width: 2.5, height: 14)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: isLandscape ? 520 : .infinity)
        .background(glassPillBackground(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.24), radius: 18, y: 6)
    }

    // MARK: - Motionlapse 2-Point Panel (10_timelapse_pano)

    private func motionlapsePanelView(isLandscape: Bool) -> some View {
        let elapsedSec = max(1, Int(round(Double(camera.motionlapseDurationSec) * motionlapseProgress)))
        let totalTimeStr = String(format: "%02d:%02d", camera.motionlapseDurationSec / 60, camera.motionlapseDurationSec % 60)
        let elapsedTimeStr = String(format: "%02d:%02d", elapsedSec / 60, elapsedSec % 60)

        return VStack(alignment: .leading, spacing: isLandscape ? 8 : 10) {
            HStack {
                Text("Motionlapse Quỹ Đạo 2 Điểm")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(hudPrimaryInk)
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if !camera.motionlapseHasPointB {
                        camera.motionlapseHasPointB = true
                        camera.motionlapsePointB = CGPoint(x: 0.78, y: 0.35)
                    } else {
                        camera.motionlapsePointA = CGPoint(x: 0.22, y: 0.45)
                        camera.motionlapsePointB = CGPoint(x: 0.78, y: 0.35)
                    }
                } label: {
                    Text(camera.motionlapseHasPointB ? "+ Điểm B ✓" : "+ Điểm B")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(camera.motionlapseHasPointB ? .black : hudPrimaryInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(camera.motionlapseHasPointB ? goldAccent : (isLightTheme ? Color.black.opacity(0.08) : Color.white.opacity(0.14)))
                        )
                }
                .buttonStyle(.plain)
            }

            // A -> B Timeline Scrubber
            VStack(spacing: 4) {
                Text("\(elapsedTimeStr) / \(totalTimeStr)")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(hudSecondaryInk)
                    .frame(maxWidth: .infinity, alignment: .center)

                GeometryReader { geo in
                    let w = max(40, geo.size.width)
                    let knobX = CGFloat(motionlapseProgress) * (w - 28) + 14

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(isLightTheme ? Color.black.opacity(0.10) : Color.white.opacity(0.18))
                            .frame(height: 4)
                            .padding(.horizontal, 12)

                        Capsule()
                            .fill(goldAccent)
                            .frame(width: max(8, knobX - 12), height: 4)
                            .padding(.leading, 12)

                        // Keypoint A
                        Text("A")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(goldAccent))
                            .position(x: 14, y: 14)

                        // Keypoint B
                        Text("B")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(goldAccent))
                            .position(x: w - 14, y: 14)

                        // Playhead Scrubber
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .shadow(color: Color.black.opacity(0.30), radius: 4, y: 1)
                            .position(x: knobX, y: 14)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let ratio = max(0, min(1, (value.location.x - 14) / max(1, w - 28)))
                                motionlapseProgress = Double(ratio)
                            }
                    )
                }
                .frame(height: 28)
            }

            // 3 Stat Tiles
            HStack(spacing: 8) {
                motionlapseStatTile(label: "Thời Lượng", value: "\(camera.motionlapseDurationSec)s") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    switch camera.motionlapseDurationSec {
                    case 15: camera.motionlapseDurationSec = 30
                    case 30: camera.motionlapseDurationSec = 60
                    case 60: camera.motionlapseDurationSec = 120
                    default: camera.motionlapseDurationSec = 15
                    }
                }

                motionlapseStatTile(
                    label: "Khoảng Chụp",
                    value: String(format: "%.1fs", camera.motionlapseIntervalSec)
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if camera.motionlapseIntervalSec < 1.5 {
                        camera.motionlapseIntervalSec = 2.0
                    } else if camera.motionlapseIntervalSec < 4.0 {
                        camera.motionlapseIntervalSec = 5.0
                    } else {
                        camera.motionlapseIntervalSec = 1.0
                    }
                }

                motionlapseStatTile(label: "Tổng Số Ảnh", value: "\(camera.motionlapseTotalFrames)") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .padding(14)
        .background(glassPillBackground(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.22), radius: 16, y: 6)
    }

    private func motionlapseStatTile(label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(hudSecondaryInk)
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                    .foregroundColor(hudPrimaryInk)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isLightTheme ? Color.white.opacity(0.75) : Color.white.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Zoom, Capture Modes & Shutter Bar

    @ViewBuilder
    private func zoomPillBar(vertical: Bool) -> some View {
        let stack = Group {
            if vertical {
                VStack(spacing: 4) {
                    zoomButtons
                }
            } else {
                HStack(spacing: 4) {
                    zoomButtons
                }
            }
        }
        stack
            .padding(4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(isLightTheme ? Color.white.opacity(0.45) : Color.black.opacity(0.24)))
            )
            .overlay(Capsule().stroke(hudHairline, lineWidth: 0.5))
    }

    private var zoomButtons: some View {
        ForEach(activeZoomOptions, id: \.self) { opt in
            let isActive = opt.replacingOccurrences(of: "×", with: "x")
                == camera.zoomFactor.replacingOccurrences(of: "×", with: "x")
            let displayLabel = (opt == "1x") ? "1×" : opt

            Button {
                camera.setZoom(opt)
            } label: {
                Text(displayLabel)
                    .font(.system(size: isActive ? 12.5 : 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isActive ? activeGoldInk : hudPrimaryInk)
                    .frame(width: isActive ? 36 : 30, height: isActive ? 36 : 30)
                    .background(
                        Circle().fill(isLightTheme ? Color.white.opacity(0.86) : Color.black.opacity(0.42))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func modeSelectorStrip(vertical: Bool) -> some View {
        if vertical {
            VStack(spacing: 12) {
                modeButtons
            }
            .frame(width: 78)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    modeButtons
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 26)
        }
    }

    private var modeButtons: some View {
        ForEach(figmaModes, id: \.self) { mode in
            let isSelected = (camera.selectedMode == mode) || (mode == "ẢNH" && camera.selectedMode == "PHOTO")
            let isLocked = (mode == "TIMELAPSE" && !store.isMotionlapseAllowed)

            Button {
                if isLocked {
                    showPaywallSheet = true
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        camera.selectedMode = mode
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8.5))
                    }
                    Text(mode)
                        .font(.system(size: 11.5, weight: isSelected ? .bold : .semibold))
                        .tracking(0.5)
                }
                .foregroundColor(
                    isSelected
                        ? (isLightTheme ? Color(red: 1.0, green: 0.80, blue: 0.0) : goldAccent)
                        : Color.white.opacity(0.88)
                )
                .shadow(color: Color.black.opacity(isLightTheme ? 0.65 : 0.45), radius: 2, y: 1)
                .lineLimit(1)
            }
            .buttonStyle(.plain)
        }
    }

    private var galleryThumbButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            store.activeMainTab = 1
        } label: {
            Group {
                if let thumb = camera.latestThumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 48, height: 48)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.42, green: 0.50, blue: 0.60), Color(red: 0.17, green: 0.20, blue: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Color.white.opacity(0.35), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private var rightShutterActionButton: some View {
        Button {
            if camera.isRecording {
                camera.capturePhoto()
            } else {
                camera.switchCamera()
            }
        } label: {
            if camera.isRecording {
                // Still-capture shutter button while video is recording (03_camera_recording)
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 48, height: 48)
                    Circle().fill(Color.white).frame(width: 30, height: 30)
                        .shadow(color: Color.black.opacity(0.22), radius: 2)
                }
                .overlay(Circle().stroke(hudHairline, lineWidth: 0.6))
            } else {
                Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(hudPrimaryInk)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(hudHairline, lineWidth: 0.6))
            }
        }
        .buttonStyle(.plain)
    }

    private var shutterButton: some View {
        Button {
            if isPhotoLikeMode {
                camera.capturePhoto()
            } else {
                camera.toggleRecording()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)

                if isPhotoLikeMode {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 58, height: 58)
                        .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.6))
                } else {
                    RoundedRectangle(cornerRadius: camera.isRecording ? 7 : 29, style: .continuous)
                        .fill(recRed)
                        .frame(
                            width: camera.isRecording ? 28 : 58,
                            height: camera.isRecording ? 28 : 58
                        )
                        .animation(.easeInOut(duration: 0.2), value: camera.isRecording)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Banners (Touch Lock + BLE Toast)

    private func floatingTopBanners(isLandscape: Bool) -> some View {
        VStack(spacing: 8) {
            if camera.touchLockEnabled {
                Button {
                    camera.touchLockEnabled = false
                    ble.showToast("Đã mở khóa cảm ứng")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Touch Lock • Chạm để mở")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(goldAccent))
                    .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)
                }
                .padding(.top, isLandscape ? 14 : 62)
            }

            if let toast = ble.hudToastMessage {
                Text(toast)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(hudPrimaryInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(glassPillBackground(cornerRadius: 16))
                    .overlay(Capsule().stroke(goldAccent.opacity(0.65), lineWidth: 0.8))
                    .padding(.top, camera.touchLockEnabled ? 0 : (isLandscape ? 12 : 44))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: ble.hudToastMessage)
        .animation(.easeInOut(duration: 0.2), value: camera.touchLockEnabled)
    }

    // MARK: - Styling & State Helpers

    private func glassPillBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isLightTheme ? Color.white.opacity(0.55) : Color.black.opacity(0.32))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(hudHairline, lineWidth: 0.6)
            )
    }

    private func closeTransientOverlays() {
        showQuickSettingsDropdown = false
        showAspectBar = false
        showGimbalDial = false
        showAiModeMenu = false
        showProManualOverlay = false
    }

    private func enforceModulePermissions() {
        if camera.selectedResolution.contains("4K") && !store.isProResAllowed {
            camera.selectedResolution = "1080 • 60"
        }
        if camera.activeLut == "Apple Log (Flat)" && (!store.isProResAllowed || !store.is3DLutAllowed) {
            camera.activeLut = "Standard Rec.709"
        }
        if camera.selectedMode == "TIMELAPSE" && !store.isMotionlapseAllowed {
            camera.selectedMode = "VIDEO"
        }
        if !store.isAiVisionAllowed {
            camera.aiTrackingEnabled = false
        }
    }

    private func revealControlsAndBumpTimer() {
        withAnimation(.easeIn(duration: 0.2)) {
            controlsHidden = false
        }
        if camera.isRecording && camera.autoHideControls3s {
            scheduleAutoHideIfNeeded()
        }
    }

    private func scheduleAutoHideIfNeeded() {
        autoHideWorkItem?.cancel()
        guard camera.autoHideControls3s, camera.isRecording else { return }
        let work = DispatchWorkItem {
            if camera.isRecording && camera.autoHideControls3s {
                withAnimation(.easeOut(duration: 0.35)) {
                    controlsHidden = true
                }
            }
        }
        autoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    private func cancelAutoHide() {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
        withAnimation(.easeIn(duration: 0.2)) {
            controlsHidden = false
        }
    }
}
