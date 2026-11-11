//
//  CameraStudioNativeView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 8. CAMERA STUDIO NATIVE VIEW (SCREEN 01 & 02 - BLACKMAGIC / HALIDE HUD)
// =====================================================================

struct CameraStudioNativeView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService

    @State private var isAiActive: Bool = true
    @State private var showProHud: Bool = false
    @State private var showAspectPicker: Bool = false
    @State private var showProControls: Bool = false
    @State private var showQuickMenu: Bool = false
    @State private var showGallerySheet: Bool = false
    @State private var selectedCamMode: String = "VIDEO 4K/60"

    // Tap to focus reticle
    @State private var focusPoint: CGPoint? = nil
    @State private var showFocusRing: Bool = false

    let gimbalModes = ["PF", "FPV", "LOCK", "360°"]
    let camModes = ["TIMELAPSE", "SLOW-MO", "VIDEO 4K/60", "PHOTO", "PORTRAIT", "PRO CINEMA"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Live AVFoundation Video Layer
                NativeCameraPreviewRepresentable()
                    .ignoresSafeArea()
                    .onTapGesture { location in
                        focusPoint = location
                        showFocusRing = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showFocusRing = false
                        }
                    }

                // 2. Shutter Flash Overlay
                if camera.shutterFlash {
                    Color.white
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                // 3. Cinematic Aspect Ratio Letterbox / Pillarbox Mask
                AspectLetterboxMaskView(ratio: camera.selectedAspectRatio, screenSize: geo.size)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                // 4. Tap-To-Focus Yellow Ring
                if showFocusRing, let fp = focusPoint {
                    Circle()
                        .stroke(Color(red: 0.98, green: 0.72, blue: 0.10), lineWidth: 1.5)
                        .frame(width: 64, height: 64)
                        .position(fp)
                        .transition(.scale.combined(with: .opacity))
                }

                // 5. Minimalist Rule of Thirds Grid (Subtle 12% Opacity)
                RuleOfThirdsGridView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                // 6. AI Vision Target Reticle (Screen 04)
                if store.isOnline && store.isAiVisionAllowed && isAiActive, let face = camera.detectedFaceRect {
                    let bx = face.minX * geo.size.width
                    let by = face.minY * geo.size.height
                    let bw = face.width * geo.size.width
                    let bh = face.height * geo.size.height

                    ZStack {
                        CinematicReticleShape()
                            .stroke(Color.white.opacity(0.85), lineWidth: 1.8)
                            .frame(width: max(bw, 70), height: max(bh, 70))
                            .shadow(color: Color.black.opacity(0.6), radius: 4)

                        Circle()
                            .fill(Color(red: 0.98, green: 0.72, blue: 0.10))
                            .frame(width: 4, height: 4)

                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("AI LOCK 60FPS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .offset(y: -(bh / 2 + 18))
                    }
                    .position(x: bx + bw / 2, y: by + bh / 2)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: face)
                    .onAppear {
                        let dx = Double(face.midX - 0.5)
                        let dy = Double(face.midY - 0.5)
                        ble.sendTrackingError(dx: dx, dy: dy)
                    }
                }

                // 7. Pro Cinema HUD Overlay (RGB Histogram & Audio VU Meter)
                if showProHud {
                    VStack {
                        HStack(alignment: .top) {
                            // RGB Histogram
                            MiniRGBHistogramView()

                            Spacer()

                            // Stereo VU Audio Meter
                            MiniStereoAudioMeterView(levelL: camera.audioLevelL, levelR: camera.audioLevelR)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 56)

                        // Exposure readouts strip
                        HStack(spacing: 12) {
                            Text("f/1.8")
                            Text(camera.shutterSpeed)
                            Text("ISO \(camera.iso)")
                            Text("\(camera.wbKelvin)K")
                            Text(String(format: "%+.1f EV", camera.ev))
                            Text(camera.activeLut)
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, 4)

                        Spacer()
                    }
                    .transition(.opacity)
                }

                // 8. Recording Live Indicator Banner
                if camera.isRecording {
                    VStack {
                        HStack(spacing: 6) {
                            Circle().fill(Color.red).frame(width: 8, height: 8)
                            Text("REC \(camera.recordingDuration)")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("• 4K PRORES HQ")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(.top, 64)

                        Spacer()
                    }
                }

                // 9. Floating Gimbal HUD Toast
                if let msg = ble.hudToastMessage {
                    VStack {
                        Spacer()
                        Text(msg)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .padding(.bottom, 175)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // 10. Ergonomic Viewfinder HUD Bars
                VStack(spacing: 0) {
                    // TOP BAR
                    HStack(spacing: 8) {
                        // S1 Pro Logo & Battery
                        Button(action: {
                            ble.showToast("Gimbal T-Flow S1 Pro • Pin \(ble.batteryLevel)% • BLE 5.3 Đồng Bộ")
                        }) {
                            HStack(spacing: 6) {
                                TFlowBrandLogo(size: 18)
                                Text("S1 PRO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Circle().fill(Color.green).frame(width: 5, height: 5)
                                Text("\(ble.batteryLevel)%")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }

                        Spacer()

                        // Aspect Ratio Picker Button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showAspectPicker.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "aspectratio")
                                    .font(.system(size: 11, weight: .bold))
                                Text(camera.selectedAspectRatio)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }

                        // Resolution / FPS Toggle
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if camera.selectedResolution == "4K • 60" {
                                camera.selectedResolution = "1080 • 120"
                            } else if camera.selectedResolution == "1080 • 120" {
                                camera.selectedResolution = "4K • 30"
                            } else {
                                camera.selectedResolution = "4K • 60"
                            }
                            ble.showToast("Độ phân giải: \(camera.selectedResolution)")
                        }) {
                            Text(camera.selectedResolution)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }

                        // Pro HUD Toggle
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showProHud.toggle()
                            }
                        }) {
                            Text("PRO")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(showProHud ? Color.black : Color.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(showProHud ? Color.white : Color.white.opacity(0.18))
                                .clipShape(Capsule())
                        }

                        // Quick Settings (3 dots)
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showQuickMenu.toggle()
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer()

                    // BOTTOM CLUSTER (Ergonomic Thumb Access)
                    VStack(spacing: 12) {
                        // Gimbal Mode Switcher (PF | FPV | LOCK | 360°)
                        HStack(spacing: 4) {
                            ForEach(gimbalModes, id: \.self) { mode in
                                Button(action: {
                                    ble.setGimbalModeWithHaptic(mode)
                                }) {
                                    Text(mode)
                                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(ble.gimbalMode == mode ? Color.white : Color.clear)
                                        .foregroundColor(ble.gimbalMode == mode ? .black : .white.opacity(0.8))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                        // Camera Mode Carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(camModes, id: \.self) { m in
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedCamMode = m
                                    }) {
                                        Text(m)
                                            .font(.system(size: 12, weight: selectedCamMode == m ? .bold : .medium))
                                            .foregroundColor(selectedCamMode == m ? Color(red: 0.98, green: 0.72, blue: 0.10) : .white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Shutter & Actions Bar
                        HStack(spacing: 36) {
                            // Left: Media Gallery Thumbnail Button
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showGallerySheet = true
                            }) {
                                ZStack {
                                    if let thumb = camera.latestThumbnail {
                                        Image(uiImage: thumb)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 46, height: 46)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 46, height: 46)
                                            .overlay(Image(systemName: "photo.on.rectangle.angled").foregroundColor(.white))
                                    }
                                }
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                            }

                            // Center: Large 72px Shutter/REC Button
                            Button(action: {
                                if selectedCamMode.contains("PHOTO") || selectedCamMode.contains("PORTRAIT") {
                                    camera.capturePhoto()
                                } else {
                                    camera.toggleRecording()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3.5)
                                        .frame(width: 72, height: 72)

                                    if camera.isRecording {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.red)
                                            .frame(width: 28, height: 28)
                                    } else {
                                        Circle()
                                            .fill(selectedCamMode.contains("PHOTO") ? Color.white : Color.red)
                                            .frame(width: 58, height: 58)
                                    }
                                }
                            }

                            // Right: Flip Camera Button
                            Button(action: {
                                camera.switchCamera()
                            }) {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 46, height: 46)
                                    .overlay(
                                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                                            .font(.system(size: 19, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 16)
                }
            }
            .sheet(isPresented: $showAspectPicker) {
                AspectPickerSheetView(selectedRatio: $camera.selectedAspectRatio)
                    .presentationDetents([.fraction(0.35)])
            }
            .sheet(isPresented: $showQuickMenu) {
                QuickSettingsSheetView(camera: camera)
                    .presentationDetents([.fraction(0.45)])
            }
            .sheet(isPresented: $showGallerySheet) {
                MediaGallerySheetView(camera: camera)
            }
        }
    }
}
