//
//  CameraStudioNativeView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Hỗ trợ 2 chế độ: Cơ Bản (Basic 99% trong suốt) & Chuyên Nghiệp (Pro Cinema HUD),
//  Chủ đề Tối / Sáng / Tự động, và Chế độ Ngang 90° Landscape Preview.
//

import SwiftUI
import AVFoundation

struct CameraStudioNativeView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.colorScheme) private var colorScheme

    @State private var isAiActive: Bool = true
    @State private var showAspectPicker: Bool = false
    @State private var showQuickSettings: Bool = false
    @State private var showProManualSheet: Bool = false
    @State private var showGallery: Bool = false
    @State private var showOnboardingSheet: Bool = false
    @State private var showPaywallSheet: Bool = false

    @State private var controlsHidden: Bool = false
    @State private var autoHideWorkItem: DispatchWorkItem? = nil

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)

    private var isLightTheme: Bool { colorScheme == .light }

    private var hudSurfaceColor: Color {
        isLightTheme ? Color.white.opacity(0.86) : Color.black.opacity(0.58)
    }

    private var hudDockBackdrop: Color {
        isLightTheme
            ? Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.92)
            : Color(red: 0.04, green: 0.05, blue: 0.07).opacity(0.78)
    }

    private var hudPrimaryInk: Color {
        isLightTheme ? Color(red: 0.06, green: 0.09, blue: 0.16) : .white
    }

    private var hudSecondaryInk: Color {
        isLightTheme ? Color(red: 0.35, green: 0.42, blue: 0.52) : .white.opacity(0.70)
    }

    private var hudBorderColor: Color {
        isLightTheme ? Color.black.opacity(0.10) : Color.white.opacity(0.16)
    }

    private var isPhotoLikeMode: Bool {
        camera.selectedMode == "PHOTO" || camera.selectedMode == "PORTRAIT"
    }

    private var activeZoomOptions: [String] {
        camera.isProMode ? [".5", "1x", "2", "5"] : [".5", "1x"]
    }

    private var activeShootModes: [String] {
        camera.isProMode
            ? ["SLO-MO", "VIDEO", "PHOTO", "PRO CINEMA", "PORTRAIT", "TIMELAPSE"]
            : ["VIDEO", "PHOTO"]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                viewfinderBackdropLayer(size: geo.size)
                viewfinderOverlayLayer(size: geo.size)

                // HUD Chrome (Portrait vs 90° Landscape Preview)
                Group {
                    if camera.isLandscapeMode {
                        landscapeHudLayout(size: geo.size)
                    } else {
                        portraitHudLayout(size: geo.size)
                    }
                }
                .allowsHitTesting(!camera.touchLockEnabled)

                // Floating Touch Lock Pill & BLE Toast (Always interactive above hit-block)
                VStack(spacing: 8) {
                    if camera.touchLockEnabled {
                        touchLockUnlockBanner
                            .padding(.top, camera.isLandscapeMode ? 14 : 62)
                    }
                    if let toast = ble.hudToastMessage {
                        Text(toast)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(hudPrimaryInk)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(hudSurfaceColor))
                            .overlay(Capsule().stroke(goldAccent.opacity(0.65), lineWidth: 1))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.2), value: ble.hudToastMessage)
                .animation(.easeInOut(duration: 0.2), value: camera.touchLockEnabled)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                revealControlsAndBumpTimer()
            }
        }
        .onAppear {
            camera.setupSession()
            enforceModulePermissions()
        }
        .onChange(of: store.modules) { _ in
            enforceModulePermissions()
        }
        .onChange(of: camera.isRecording) { recording in
            if recording {
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
            guard store.isOnline, store.isAiVisionAllowed, isAiActive, let face = newFace else { return }
            let dx = Double(face.midX - 0.5)
            let dy = Double(face.midY - 0.5)
            ble.sendTrackingError(dx: dx, dy: dy)
        }
        .sheet(isPresented: $showAspectPicker) {
            AspectPickerSheetView(selectedRatio: $camera.selectedAspectRatio)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showQuickSettings) {
            QuickSettingsSheetView(camera: camera, store: store)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showProManualSheet) {
            ProManualControlsSheetView(camera: camera, store: store)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showGallery) {
            MediaGallerySheetView(camera: camera)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingWelcomeSheetView(
                ble: ble,
                store: store,
                onOpenPaywall: {
                    showOnboardingSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showPaywallSheet = true
                    }
                }
            )
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

    // MARK: - Viewfinder Layers

    @ViewBuilder
    private func viewfinderBackdropLayer(size: CGSize) -> some View {
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

            AspectLetterboxMaskView(ratio: camera.selectedAspectRatio, screenSize: size)

            if camera.shutterFlash {
                Color.white.opacity(0.65).ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private func viewfinderOverlayLayer(size: CGSize) -> some View {
        ZStack {
            if camera.isProMode && camera.gridEnabled {
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

            // Corner Viewfinder Marks (Subtle in Basic, sharper in Pro)
            CinematicReticleShape()
                .stroke(
                    camera.isProMode ? Color.white.opacity(0.32) : Color.white.opacity(0.18),
                    lineWidth: 1.5
                )
                .frame(
                    width: camera.isLandscapeMode ? min(size.width * 0.62, 260) : min(size.width * 0.76, 290),
                    height: camera.isLandscapeMode ? 160 : 210
                )
                .allowsHitTesting(false)

            // Pro Horizon Balance Level (0.0°)
            if camera.isProMode && camera.showHorizonLevel {
                horizonLevelIndicator
                    .allowsHitTesting(false)
            }

            // Live Face Tracking Frame or Pro AI Reticle
            if isAiActive && store.isAiVisionAllowed {
                if let face = camera.detectedFaceRect {
                    let boxW = max(92, face.width * size.width)
                    let boxH = max(110, face.height * size.height)
                    let centerX = face.midX * size.width
                    let centerY = face.midY * size.height

                    ZStack(alignment: .topLeading) {
                        CinematicReticleShape()
                            .stroke(goldAccent, lineWidth: 2.2)
                            .frame(width: boxW, height: boxH)

                        Text(camera.isProMode ? "AF-C • 60 FPS" : "AI TRACK")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(goldAccent)
                            .cornerRadius(4)
                            .offset(y: -18)
                    }
                    .position(x: centerX, y: centerY)
                    .allowsHitTesting(false)
                } else if camera.isProMode {
                    // Pro AF-C • 60 FPS Standby Frame
                    VStack(spacing: 4) {
                        Text("AF-C • 60 FPS")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(goldAccent)
                            .cornerRadius(5)
                    }
                    .offset(y: -88)
                    .allowsHitTesting(false)
                }
            }
        }
    }

    private var horizonLevelIndicator: some View {
        let isLevel = abs(ble.rollAngle) < 1.5
        let tintColor = isLevel ? Color.green : goldAccent
        return HStack(spacing: 8) {
            Rectangle()
                .fill(tintColor.opacity(0.85))
                .frame(width: 36, height: 1.5)
            Text(String(format: "%.1f°", ble.rollAngle))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(tintColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .overlay(Capsule().stroke(tintColor.opacity(0.6), lineWidth: 1))
            Rectangle()
                .fill(tintColor.opacity(0.85))
                .frame(width: 36, height: 1.5)
        }
        .rotationEffect(.degrees(ble.rollAngle))
    }

    // MARK: - Portrait HUD Layout

    private func portraitHudLayout(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Group {
                if camera.isProMode {
                    proTopBar
                } else {
                    basicTopBar
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .opacity(controlsHidden ? 0.08 : 1.0)

            Spacer()

            if camera.isProMode {
                proTelemetryRow
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                    .opacity(controlsHidden ? 0.0 : 1.0)
            }

            portraitBottomDock
        }
    }

    // MARK: - Basic Top Bar (Zero Technical Numbers, 3 Items)

    private var basicTopBar: some View {
        HStack {
            // Left: Flash circular button
            Button {
                camera.toggleFlash()
            } label: {
                Image(systemName: camera.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(camera.isFlashEnabled ? goldAccent : hudPrimaryInk)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(hudSurfaceColor))
                    .overlay(Circle().stroke(hudBorderColor, lineWidth: 1))
            }

            Spacer()

            // Center: Discreet Gimbal status pill (Tap -> Onboarding / BLE Pairing)
            Button {
                showOnboardingSheet = true
            } label: {
                HStack(spacing: 7) {
                    Circle()
                        .fill(ble.isConnected ? Color.green : goldAccent)
                        .frame(width: 7, height: 7)
                    Text("Gimbal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(hudPrimaryInk)
                    if camera.isRecording {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                        Text(camera.recordingDuration)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(hudSurfaceColor))
                .overlay(Capsule().stroke(hudBorderColor, lineWidth: 1))
            }

            Spacer()

            // Right: Gear circular button -> Customizer Sheet
            Button {
                showQuickSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(hudPrimaryInk)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(hudSurfaceColor))
                    .overlay(Circle().stroke(hudBorderColor, lineWidth: 1))
            }
        }
    }

    // MARK: - Pro Top Bar (Compact Frosted Cinema HUD Pill)

    private var proTopBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                // Gimbal mode pill -> Onboarding / BLE Pairing
                Button {
                    showOnboardingSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ble.isConnected ? Color.green : goldAccent)
                            .frame(width: 7, height: 7)
                        Text(ble.gimbalMode)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(hudPrimaryInk)
                    }
                }

                Divider().frame(height: 14)

                // Aspect ratio quick trigger
                Button {
                    showAspectPicker = true
                } label: {
                    Text(camera.selectedAspectRatio)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(hudPrimaryInk)
                }

                Divider().frame(height: 14)

                // Resolution & Log badge
                Button {
                    if store.isProResAllowed {
                        camera.selectedResolution = camera.selectedResolution.contains("4K")
                            ? "1080 • 60"
                            : "4K • 60"
                    } else {
                        showPaywallSheet = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(camera.selectedResolution.replacingOccurrences(of: " • ", with: " "))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(hudPrimaryInk)
                        if store.isProResAllowed {
                            Text("LOG")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(goldAccent)
                                .cornerRadius(3)
                        }
                    }
                }

                if camera.showExposureReadout {
                    Divider().frame(height: 14)

                    Button {
                        showProManualSheet = true
                    } label: {
                        Text("\(camera.shutterSpeed) ISO \(camera.iso)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(appleBlue)
                            .lineLimit(1)
                    }
                }

                if camera.isRecording {
                    Divider().frame(height: 14)
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                        Text(camera.recordingDuration)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(hudSurfaceColor))
            .overlay(Capsule().stroke(hudBorderColor, lineWidth: 1))

            Spacer(minLength: 4)

            // Right Gear -> UI Customizer
            Button {
                showQuickSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(hudPrimaryInk)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(hudSurfaceColor))
                    .overlay(Circle().stroke(hudBorderColor, lineWidth: 1))
            }
        }
    }

    // MARK: - Pro Telemetry Overlay Row (Histogram + Audio VU)

    private var proTelemetryRow: some View {
        HStack(alignment: .bottom) {
            if camera.showHistogram {
                MiniRGBHistogramView()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Button {
                    if store.isAiVisionAllowed {
                        isAiActive.toggle()
                    } else {
                        showPaywallSheet = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isAiActive && store.isAiVisionAllowed ? "viewfinder.circle.fill" : "viewfinder.circle")
                            .font(.system(size: 11, weight: .bold))
                        Text(isAiActive && store.isAiVisionAllowed ? "AI ON" : "AI OFF")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                    }
                    .foregroundColor(isAiActive && store.isAiVisionAllowed ? .black : hudPrimaryInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(isAiActive && store.isAiVisionAllowed ? goldAccent : hudSurfaceColor))
                    .overlay(Capsule().stroke(hudBorderColor, lineWidth: 1))
                }

                MiniStereoAudioMeterView(levelL: camera.audioLevelL, levelR: camera.audioLevelR)
            }
        }
    }

    // MARK: - Portrait Bottom Dock

    private var portraitBottomDock: some View {
        VStack(spacing: 12) {
            if camera.isProMode && !controlsHidden {
                gimbalModeBar
            }

            zoomPillBar(options: activeZoomOptions)
                .opacity(controlsHidden ? 0.0 : 1.0)

            modeSelectorBar(modes: activeShootModes)
                .opacity(controlsHidden ? 0.0 : 1.0)

            // Main Action Row
            HStack(spacing: 0) {
                galleryButton

                Spacer()

                if camera.isProMode {
                    landscapeToggleButton
                    Spacer()
                }

                shutterButton

                Spacer()

                if camera.isProMode {
                    aspectQuickButton
                    Spacer()
                }

                flipCameraButton
            }
            .padding(.horizontal, 22)
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(hudDockBackdrop)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - 90° Landscape HUD Preview Layout

    private func landscapeHudLayout(size: CGSize) -> some View {
        HStack(spacing: 12) {
            // Left Rail: Status + Exit 90° + Pro Telemetry
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Button {
                        camera.toggleFlash()
                    } label: {
                        Image(systemName: camera.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(camera.isFlashEnabled ? goldAccent : hudPrimaryInk)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(hudSurfaceColor))
                    }

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
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(hudSurfaceColor))
                        .overlay(Capsule().stroke(hudBorderColor, lineWidth: 1))
                    }
                }

                Button {
                    showOnboardingSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ble.isConnected ? Color.green : goldAccent)
                            .frame(width: 7, height: 7)
                        Text(camera.isProMode ? "\(ble.gimbalMode) • \(camera.selectedAspectRatio)" : "Gimbal")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(hudPrimaryInk)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(hudSurfaceColor))
                    .overlay(Capsule().stroke(hudBorderColor, lineWidth: 1))
                }

                if camera.isProMode {
                    if camera.showExposureReadout {
                        Button {
                            showProManualSheet = true
                        } label: {
                            Text("\(camera.shutterSpeed)\nISO \(camera.iso)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(appleBlue)
                                .multilineTextAlignment(.leading)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(hudSurfaceColor))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(hudBorderColor, lineWidth: 1))
                        }
                    }
                    if camera.showHistogram {
                        MiniRGBHistogramView()
                    }
                }

                Spacer()

                if camera.isProMode {
                    MiniStereoAudioMeterView(levelL: camera.audioLevelL, levelR: camera.audioLevelR)
                }
            }
            .padding(.vertical, 16)
            .padding(.leading, 14)

            Spacer()

            // Right Rail: Gear, Vertical Zoom, Vertical Shutter, Flip, Gallery
            VStack(spacing: 12) {
                Button {
                    showQuickSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(hudPrimaryInk)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(hudSurfaceColor))
                        .overlay(Circle().stroke(hudBorderColor, lineWidth: 1))
                }

                VStack(spacing: 4) {
                    ForEach(activeZoomOptions, id: \.self) { label in
                        Button {
                            camera.setZoom(label)
                        } label: {
                            Text(label)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(camera.zoomFactor == label ? .black : hudPrimaryInk)
                                .frame(width: 30, height: 24)
                                .background(
                                    Capsule().fill(camera.zoomFactor == label ? goldAccent : Color.clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(Capsule().fill(hudSurfaceColor))
                .overlay(Capsule().stroke(hudBorderColor, lineWidth: 1))

                Spacer()

                shutterButton

                Spacer()

                HStack(spacing: 10) {
                    galleryButton
                    flipCameraButton
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(goldAccent.opacity(0.25), lineWidth: 1)
                .padding(4)
        )
    }

    // MARK: - Shared Controls

    private var touchLockUnlockBanner: some View {
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
    }

    private var gimbalModeBar: some View {
        HStack(spacing: 6) {
            ForEach(["PF", "FPV", "LOCK", "360°"], id: \.self) { mode in
                let isSelected = ble.gimbalMode == mode
                Button {
                    ble.setGimbalModeWithHaptic(mode)
                } label: {
                    Text(mode)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(isSelected ? .black : hudSecondaryInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(isSelected ? goldAccent : hudSurfaceColor.opacity(0.65))
                        )
                        .overlay(
                            Capsule().stroke(isSelected ? Color.clear : hudBorderColor, lineWidth: 1)
                        )
                }
            }
        }
    }

    private func zoomPillBar(options: [String]) -> some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { label in
                let isActive = camera.zoomFactor == label
                Button {
                    camera.setZoom(label)
                } label: {
                    Text(label)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? .black : hudPrimaryInk)
                        .frame(width: 34, height: 26)
                        .background(
                            Circle().fill(isActive ? goldAccent : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(hudSurfaceColor))
        .overlay(Capsule().stroke(hudBorderColor, lineWidth: 1))
    }

    private func modeSelectorBar(modes: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(modes, id: \.self) { mode in
                    let isSelected = camera.selectedMode == mode
                    let isLocked = isModeLocked(mode)
                    Button {
                        if isLocked {
                            showPaywallSheet = true
                        } else {
                            camera.selectedMode = mode
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                            }
                            Text(mode)
                                .font(.system(size: 11, weight: isSelected ? .black : .semibold))
                        }
                        .foregroundColor(isSelected ? goldAccent : hudSecondaryInk)
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 28)
    }

    private var galleryButton: some View {
        Button {
            showGallery = true
        } label: {
            Group {
                if let thumb = camera.latestThumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hudPrimaryInk)
                }
            }
            .frame(width: 44, height: 44)
            .background(RoundedRectangle(cornerRadius: 12).fill(hudSurfaceColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(hudBorderColor, lineWidth: 1.2))
        }
    }

    private var landscapeToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                camera.isLandscapeMode.toggle()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "rotate.right")
                    .font(.system(size: 14, weight: .semibold))
                Text("90°")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .foregroundColor(camera.isLandscapeMode ? goldAccent : hudPrimaryInk)
            .frame(width: 38, height: 38)
            .background(Circle().fill(hudSurfaceColor))
            .overlay(Circle().stroke(hudBorderColor, lineWidth: 1))
        }
    }

    private var aspectQuickButton: some View {
        Button {
            showAspectPicker = true
        } label: {
            Text(camera.selectedAspectRatio)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(hudPrimaryInk)
                .frame(width: 42, height: 34)
                .background(RoundedRectangle(cornerRadius: 10).fill(hudSurfaceColor))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(hudBorderColor, lineWidth: 1))
        }
    }

    private var flipCameraButton: some View {
        Button {
            camera.switchCamera()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(hudPrimaryInk)
                .frame(width: 44, height: 44)
                .background(Circle().fill(hudSurfaceColor))
                .overlay(Circle().stroke(hudBorderColor, lineWidth: 1))
        }
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
                    .stroke(hudPrimaryInk, lineWidth: 3.5)
                    .frame(width: 72, height: 72)

                if isPhotoLikeMode {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: camera.isRecording ? 8 : 30)
                        .fill(Color.red)
                        .frame(
                            width: camera.isRecording ? 30 : 58,
                            height: camera.isRecording ? 30 : 58
                        )
                        .animation(.easeInOut(duration: 0.2), value: camera.isRecording)
                }
            }
        }
    }

    // MARK: - Helpers & Permission Enforcement

    private func isModeLocked(_ mode: String) -> Bool {
        if mode == "PRO CINEMA" && !store.isProResAllowed { return true }
        if mode == "TIMELAPSE" && !store.isMotionlapseAllowed { return true }
        return false
    }

    private func enforceModulePermissions() {
        if camera.selectedResolution.contains("4K") && !store.isProResAllowed {
            camera.selectedResolution = "1080 • 60"
        }
        if camera.selectedMode == "PRO CINEMA" && !store.isProResAllowed {
            camera.selectedMode = "PHOTO"
        }
        if camera.activeLut == "Apple Log (Flat)" && (!store.isProResAllowed || !store.is3DLutAllowed) {
            camera.activeLut = "Standard Rec.709"
        }
        if camera.selectedMode == "TIMELAPSE" && !store.isMotionlapseAllowed {
            camera.selectedMode = "VIDEO"
        }
        if !store.isAiVisionAllowed {
            isAiActive = false
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

// MARK: - Onboarding & BLE Pairing Welcome Sheet (01_Onboarding_Welcome_SignIn)

struct OnboardingWelcomeSheetView: View {
    @ObservedObject var ble: BLEGimbalManager
    @ObservedObject var store: SupabaseModuleStore
    var onOpenPaywall: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)

    var body: some View {
        let isLight = colorScheme == .light
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Hero Brand Mark
                    VStack(spacing: 10) {
                        TFlowBrandLogo(
                            size: 62,
                            strokeColor: isLight ? .black : .white,
                            bgColor: isLight ? Color.white : Color.black,
                            showText: false
                        )
                        Text("T-Flow Pro S1 Studio")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.primary)
                        Text("BLE 5.3 • AI 60fps • MagSafe 45N")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Quick Visual Highlight Badges
                    HStack(spacing: 8) {
                        badgePill(icon: "scope", text: "AI Vision")
                        badgePill(icon: "film", text: "Apple Log")
                        badgePill(icon: "gyroscope", text: "CoG Auto")
                    }

                    // BLE Pairing Status Card
                    VStack(spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(ble.isConnected ? Color.green : goldAccent)
                                    .frame(width: 9, height: 9)
                                Text(store.deviceName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Text(ble.isConnected ? "Pin \(ble.batteryLevel)%" : "Chờ ghép đôi")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(ble.isConnected ? .green : goldAccent)
                        }

                        Button {
                            ble.isConnected = true
                            ble.showCalibrationModal = true
                            ble.startCoGCalibration()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "wave.3.right.circle.fill")
                                Text(ble.isConnected ? "Cân bằng lại CoG" : "Quét & Kết Nối BLE")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(appleBlue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground)))

                    // Quick Sign-In & Tier Section
                    VStack(spacing: 10) {
                        Button {
                            store.syncWithCloud()
                            ble.showToast("Đã đồng bộ Apple ID")
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                Text("Tiếp tục với Apple ID")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(isLight ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isLight ? Color.black : Color.white)
                            .cornerRadius(12)
                        }

                        Button {
                            onOpenPaywall()
                        } label: {
                            HStack {
                                Text("Gói hiện tại: \(store.userTier)")
                                    .font(.system(size: 12, weight: .bold))
                                Spacer()
                                Text("Nâng cấp")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(goldAccent)
                            }
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemGroupedBackground)))
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Kết Nối & Tài Khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }

    private func badgePill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(goldAccent)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(UIColor.secondarySystemGroupedBackground)))
    }
}
