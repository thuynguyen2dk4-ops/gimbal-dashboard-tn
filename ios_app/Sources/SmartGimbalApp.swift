//
//  SmartGimbalApp.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Production Cinema & Gimbal Operating System
//  Official Apple HIG Architecture — 12 Pro Artboard Flows
//  Compatible with iOS 16.0+, iOS 17+, iOS 18+
//

import SwiftUI
import AVFoundation
import CoreBluetooth
import Vision
import Combine
import Photos

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

// MARK: - =====================================================================
// 2. CAPTURED MEDIA MODEL & DATA STORE
// =====================================================================

struct CapturedMediaItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let isVideo: Bool
    let duration: String?
    let timestamp: Date = Date()
    let resolution: String
    let profile: String
}

// MARK: - =====================================================================
// 3. CLOUD SUPABASE MODULE STORE
// =====================================================================

final class SupabaseModuleStore: ObservableObject {
    @Published var userName: String = "Đặng Anh Dũng"
    @Published var userTier: String = "VIP LIFETIME"
    @Published var deviceName: String = "Smart Gimbal S1 Titanium"
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: String = "Vừa xong"
    @Published var modules: [Bool] = [true, true, true, true, true, true, true]

    var isAiVisionAllowed: Bool { modules.indices.contains(0) ? modules[0] : true }
    var isProResAllowed: Bool { modules.indices.contains(1) ? modules[1] : true }
    var isMotionlapseAllowed: Bool { modules.indices.contains(2) ? modules[2] : true }
    var isMultiCamAllowed: Bool { modules.indices.contains(3) ? modules[3] : true }
    var is3DLutAllowed: Bool { modules.indices.contains(4) ? modules[4] : true }
    var isFocTuningAllowed: Bool { modules.indices.contains(5) ? modules[5] : true }
    var isRawTelemetryAllowed: Bool { modules.indices.contains(6) ? modules[6] : true }

    func toggleModule(at index: Int) {
        guard modules.indices.contains(index) else { return }
        modules[index].toggle()
        syncWithCloud()
    }

    func setTier(_ tier: String) {
        userTier = tier
        if tier == "Free Starter" {
            modules = [false, false, false, false, false, false, false]
        } else if tier == "Creator Pro" {
            modules = [true, true, true, true, true, false, false]
        } else {
            modules = [true, true, true, true, true, true, true]
        }
        syncWithCloud()
    }

    func syncWithCloud() {
        isSyncing = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.isSyncing = false
            self.isOnline = true
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.lastSyncTime = formatter.string(from: Date())
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - =====================================================================
// 4. REALTIME BLE GIMBAL CONTROLLER & MOTOR TELEMETRY
// =====================================================================

final class BLEGimbalManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected: Bool = true
    @Published var batteryLevel: Int = 94
    @Published var gimbalMode: String = "PF" // PF, FPV, LOCK, 360°
    @Published var rollAngle: Double = 0.02
    @Published var pitchAngle: Double = 12.4
    @Published var panAngle: Double = 359.8
    @Published var joystickSensitivity: Double = 0.45
    @Published var panTorque: Double = 1.0
    @Published var tiltTorque: Double = 0.85
    @Published var rollTorque: Double = 0.90

    // Calibration Flow State
    @Published var isCalibrating: Bool = false
    @Published var calibrationProgress: Double = 0.0
    @Published var calibrationStepText: String = ""
    @Published var showCalibrationModal: Bool = false

    // HUD Toast
    @Published var hudToastMessage: String? = nil

    private var centralManager: CBCentralManager?
    private var simulatedTimer: AnyCancellable?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startTelemetrySimulation()
    }

    private func startTelemetrySimulation() {
        simulatedTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isCalibrating else { return }
                // Tiny live IMU jitter to simulate 50Hz precision gyro
                let jitterRoll = Double.random(in: -0.04...0.04)
                let jitterPitch = Double.random(in: -0.06...0.06)
                self.rollAngle = (self.rollAngle * 0.95 + jitterRoll * 0.05)
                self.pitchAngle = max(-45, min(45, self.pitchAngle + jitterPitch * 0.1))
            }
    }

    func setGimbalModeWithHaptic(_ mode: String) {
        gimbalMode = mode
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let modeNames: [String: String] = [
            "PF": "Chế độ: Pan Follow (Bám Trục Quay)",
            "FPV": "Chế độ: FPV 3-Trục Điện Ảnh",
            "LOCK": "Chế độ: Khóa Tuyệt Đối 3 Trục",
            "360°": "Chế độ: 360° Inception Barrel Roll"
        ]
        showToast(modeNames[mode] ?? "Gimbal Mode: \(mode)")
    }

    func showToast(_ message: String) {
        hudToastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.hudToastMessage == message {
                self?.hudToastMessage = nil
            }
        }
    }

    func startCoGCalibration() {
        isCalibrating = true
        calibrationProgress = 0.0
        calibrationStepText = "Đang đo góc lệch trọng tâm tải trọng..."
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.calibrationProgress += 0.02

            if self.calibrationProgress < 0.25 {
                self.calibrationStepText = "Bước 1/4: Quét phân bố trọng lượng Camera..."
            } else if self.calibrationProgress < 0.55 {
                self.calibrationStepText = "Bước 2/4: Bơm xung Pure FOC 20kHz dò vị trí Rotor..."
            } else if self.calibrationProgress < 0.85 {
                self.calibrationStepText = "Bước 3/4: Cân chỉnh Notch Filter 245Hz triệt rung..."
            } else if self.calibrationProgress < 1.0 {
                self.calibrationStepText = "Bước 4/4: Khóa điểm Zero Điểm Cân Bằng Hoàn Hảo..."
            } else {
                timer.invalidate()
                self.calibrationProgress = 1.0
                self.calibrationStepText = "Hoàn tất! Sai số trọng tâm: ±0.01° (Zero Drift)"
                self.rollAngle = 0.00
                self.pitchAngle = 0.00
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.isCalibrating = false
                    self.showCalibrationModal = false
                }
            }
        }
    }

    func sendTrackingError(dx: Double, dy: Double) {
        // PID correction
        panAngle = (panAngle + dx * 2.5).truncatingRemainder(dividingBy: 360.0)
        pitchAngle = max(-45, min(45, pitchAngle - dy * 2.0))
    }

    func sendManualJoystick(x: Double, y: Double) {
        let speed = joystickSensitivity * 1.8
        panAngle = (panAngle + x * speed).truncatingRemainder(dividingBy: 360.0)
        if panAngle < 0 { panAngle += 360.0 }
        pitchAngle = max(-45, min(45, pitchAngle - y * speed))
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}

// MARK: - =====================================================================
// 5. CAMERA SERVICE & CAPTURE CONTROLLER
// =====================================================================

final class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isSessionRunning: Bool = false
    @Published var isRecording: Bool = false
    @Published var recordingDuration: String = "00:00:00"
    @Published var isFrontCamera: Bool = false
    @Published var selectedResolution: String = "4K • 60"
    @Published var selectedAspectRatio: String = "16:9"
    @Published var shutterFlash: Bool = false
    @Published var latestThumbnail: UIImage? = nil
    @Published var capturedMedia: [CapturedMediaItem] = []
    @Published var detectedFaceRect: CGRect? = nil

    // Pro Exposure & Audio HUD State
    @Published var iso: Int = 100
    @Published var shutterSpeed: String = "1/120s"
    @Published var ev: Double = 0.0
    @Published var wbKelvin: Int = 5600
    @Published var activeLut: String = "Standard Rec.709"
    @Published var audioLevelL: Double = 0.42
    @Published var audioLevelR: Double = 0.48

    let captureSession = AVCaptureSession()
    private var currentVideoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var recordingTimer: Timer?
    private var recordingSecondsCount: Int = 0

    override init() {
        super.init()
        setupMockThumbnails()
        startAudioVUAnimation()
    }

    private func setupMockThumbnails() {
        // Initial placeholder thumbnail
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80))
        let img = renderer.image { ctx in
            UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .paragraphStyle: paragraph
            ]
            ("🎬" as NSString).draw(in: CGRect(x: 0, y: 24, width: 80, height: 32), withAttributes: attrs)
        }
        latestThumbnail = img
        capturedMedia.append(
            CapturedMediaItem(
                image: img,
                isVideo: true,
                duration: "00:01:24",
                resolution: "4K ProRes 60fps",
                profile: "Apple Log"
            )
        )
    }

    private func startAudioVUAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelL = min(1.0, max(0.08, self.audioLevelL + Double.random(in: -0.15...0.15)))
            self.audioLevelR = min(1.0, max(0.08, self.audioLevelR + Double.random(in: -0.15...0.15)))
        }
    }

    func setupSession() {
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = .hd4K3840x2160
        } else if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            captureSession.sessionPreset = .high
        }

        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        let deviceType: AVCaptureDevice.DeviceType = isFrontCamera ? .builtInTrueDepthCamera : .builtInWideAngleCamera
        let device = AVCaptureDevice.default(deviceType, for: .video, position: position) ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)

        if let device = device, let input = try? AVCaptureDeviceInput(device: device), captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentVideoInput = input
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.video.processing"))
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            videoOutput = output
        }

        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }

    func switchCamera() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isFrontCamera.toggle()

        captureSession.beginConfiguration()
        if let current = currentVideoInput {
            captureSession.removeInput(current)
        }

        let newPosition: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        let deviceType: AVCaptureDevice.DeviceType = isFrontCamera ? .builtInTrueDepthCamera : .builtInWideAngleCamera
        let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: newPosition) ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)

        if let dev = newDevice, let newInput = try? AVCaptureDeviceInput(device: dev), captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
            currentVideoInput = newInput
        }
        captureSession.commitConfiguration()
    }

    func capturePhoto() {
        // Shutter flash animation
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        shutterFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.shutterFlash = false
        }

        // Render snap thumbnail
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        let photo = renderer.image { ctx in
            // Base background
            UIColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 400))

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            ("T-FLOW S1 PRO
\(selectedResolution)
\(dateStr)" as NSString).draw(
                in: CGRect(x: 20, y: 160, width: 360, height: 80),
                withAttributes: attrs
            )
        }

        let newItem = CapturedMediaItem(
            image: photo,
            isVideo: false,
            duration: nil,
            resolution: selectedResolution,
            profile: activeLut
        )
        capturedMedia.insert(newItem, at: 0)
        latestThumbnail = photo
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func toggleRecording() {
        if isRecording {
            // Stop recording
            isRecording = false
            recordingTimer?.invalidate()
            recordingTimer = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            let durationStr = recordingDuration
            recordingDuration = "00:00:00"

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
            let clipThumb = renderer.image { ctx in
                UIColor(red: 0.18, green: 0.12, blue: 0.14, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                    .foregroundColor: UIColor.red,
                    .paragraphStyle: paragraph
                ]
                ("CLIP 4K PRORES
\(durationStr)
\(activeLut)" as NSString).draw(
                    in: CGRect(x: 20, y: 160, width: 360, height: 80),
                    withAttributes: attrs
                )
            }

            let newItem = CapturedMediaItem(
                image: clipThumb,
                isVideo: true,
                duration: durationStr,
                resolution: selectedResolution,
                profile: activeLut
            )
            capturedMedia.insert(newItem, at: 0)
            latestThumbnail = clipThumb
        } else {
            // Start recording
            isRecording = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            recordingSecondsCount = 0
            recordingDuration = "00:00:00"

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingSecondsCount += 1
                let m = self.recordingSecondsCount / 60
                let s = self.recordingSecondsCount % 60
                self.recordingDuration = String(format: "00:%02d:%02d", m, s)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] req, _ in
            guard let results = req.results as? [VNFaceObservation], let firstFace = results.first else {
                DispatchQueue.main.async { self?.detectedFaceRect = nil }
                return
            }

            let box = firstFace.boundingBox
            let normalized = CGRect(
                x: 1.0 - box.maxX,
                y: 1.0 - box.maxY,
                width: box.width,
                height: box.height
            )

            DispatchQueue.main.async {
                self?.detectedFaceRect = normalized
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - =====================================================================
// 6. MAIN APPLICATION ENTRY POINT & STATE PROVIDERS
// =====================================================================

@main
struct SmartGimbalApp: App {
    @StateObject private var store = SupabaseModuleStore()
    @StateObject private var ble = BLEGimbalManager()
    @StateObject private var camera = CameraService()

    var body: some Scene {
        WindowGroup {
            MainTabShellView()
                .environmentObject(store)
                .environmentObject(ble)
                .environmentObject(camera)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - =====================================================================
// 7. MAIN TAB NAVIGATION SHELL (FIGMA 4 TABS)
// =====================================================================

struct MainTabShellView: View {
    @State private var selectedTab: Int = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 0.98)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraStudioNativeView()
                .tabItem {
                    Label("Camera AI", systemImage: "viewfinder")
                }
                .tag(0)

            GimbalDeviceHubView()
                .tabItem {
                    Label("T-Flow Pro", systemImage: "gyroscope")
                }
                .tag(1)

            TFlowAIChatAssistantView()
                .tabItem {
                    Label("T-Flow Bot", systemImage: "sparkles")
                }
                .tag(2)

            UserProfilePermissionsView()
                .tabItem {
                    Label("Tài Khoản", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
        }
        .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
    }
}

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

// MARK: - =====================================================================
// 11. ASPECT RATIO PICKER SHEET VIEW
// =====================================================================

struct AspectPickerSheetView: View {
    @Binding var selectedRatio: String
    @Environment(\.dismiss) var dismiss

    let ratios = [
        ("16:9", "Chuẩn Video / TV"),
        ("9:16", "Story / TikTok"),
        ("2.39:1", "Cinemascope Điện Ảnh"),
        ("4:3", "Classic Academy"),
        ("1:1", "Square Vuông")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("TỈ LỆ KHUNG HÌNH ĐIỆN ẢNH")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 18)

            HStack(spacing: 10) {
                ForEach(ratios, id: \.0) { item in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedRatio = item.0
                        dismiss()
                    }) {
                        VStack(spacing: 6) {
                            Text(item.0)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                            Text(item.1)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedRatio == item.0 ? Color.white : Color.white.opacity(0.1))
                        .foregroundColor(selectedRatio == item.0 ? Color.black : Color.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.14).ignoresSafeArea())
    }
}

// MARK: - =====================================================================
// 12. QUICK SETTINGS SHEET VIEW (SCREEN 04)
// =====================================================================

struct QuickSettingsSheetView: View {
    @ObservedObject var camera: CameraService
    @State private var gridEnabled: Bool = true
    @State private var zebraEnabled: Bool = false
    @State private var peakingEnabled: Bool = false
    @State private var antiFlicker: String = "50Hz"

    var body: some View {
        VStack(spacing: 18) {
            Text("TRÌNH ĐƠN CÀI ĐẶT NHANH")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 18)

            VStack(spacing: 12) {
                Toggle("Lưới Bố Cục 3x3 (Rule of Thirds)", isOn: $gridEnabled)
                Toggle("Zebra Stripes Cảnh Báo Phơi Sáng 95%", isOn: $zebraEnabled)
                Toggle("Focus Peaking Hỗ Trợ Lấy Nét Cyan", isOn: $peakingEnabled)

                HStack {
                    Text("Khử Nhấp Nháy (Anti-Flicker)")
                    Spacer()
                    Picker("", selection: $antiFlicker) {
                        Text("50Hz (EU/VN)").tag("50Hz")
                        Text("60Hz (US)").tag("60Hz")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.14).ignoresSafeArea())
    }
}

// MARK: - =====================================================================
// 13. MEDIA GALLERY SHEET VIEW (SCREEN 27 & 28)
// =====================================================================

struct MediaGallerySheetView: View {
    @ObservedObject var camera: CameraService
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: CapturedMediaItem? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(camera.capturedMedia) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                if item.isVideo, let dur = item.duration {
                                    HStack(spacing: 3) {
                                        Image(systemName: "play.fill").font(.system(size: 9))
                                        Text(dur).font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.75))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .padding(6)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.resolution)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Text(item.profile)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                            }
                        }
                        .onTapGesture {
                            selectedItem = item
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Thư Viện Media S1 Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                }
            }
        }
    }
}

// MARK: - =====================================================================
// 14. TAB 2: GIMBAL DEVICE HUB VIEW (SCREEN 30 & 31)
// =====================================================================

struct GimbalDeviceHubView: View {
    @EnvironmentObject var ble: BLEGimbalManager
    @State private var joystickDragOffset: CGSize = .zero

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // HERO HARDWARE CARD
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    TFlowBrandLogo(size: 26)
                                    Text("T-Flow Pro S1")
                                        .font(.system(size: 20, weight: .bold))
                                }
                                Text("Titanium Aerospace Edition • BLE 5.3")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            HStack(spacing: 5) {
                                Circle().fill(Color.green).frame(width: 7, height: 7)
                                Text("50Hz FOC Synced")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Divider().background(Color.white.opacity(0.1))

                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PIN 4500mAh").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("\(ble.batteryLevel)%").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("XUNG ĐIỀU KHIỂN").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("20 kHz").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.green)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRMWARE").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("v2.4.1").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12), lineWidth: 1))

                    // 3-AXIS REALTIME FOC ANGLE GAUGES (Pan, Tilt, Roll)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("GÓC QUAY 3 TRỤC THỜI GIAN THỰC (50Hz IMU)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 12) {
                            AxisAngleCard(axis: "ROLL", angle: String(format: "%.2f°", ble.rollAngle), status: "Chuẩn Cân", color: .green)
                            AxisAngleCard(axis: "TILT", angle: String(format: "%+.1f°", ble.pitchAngle), status: "Góc Chụp", color: Color(red: 0.98, green: 0.72, blue: 0.10))
                            AxisAngleCard(axis: "PAN", angle: String(format: "%.1f°", ble.panAngle), status: "Quay 360°", color: .cyan)
                        }
                    }

                    // TỰ ĐỘNG CÂN BẰNG TRỌNG TÂM (CoG)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HIỆU CHUẨN ĐỘNG CƠ COG")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            ble.showCalibrationModal = true
                            ble.startCoGCalibration()
                        }) {
                            HStack {
                                Image(systemName: "scope")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tự Động Cân Bằng Trọng Tâm (CoG)")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Tự triệt tiêu rung lắc tải trọng • Sai số ±0.01°")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }

                    // TACTILE VIRTUAL JOYSTICK CONTROLLER
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("CẦN ĐIỀU KHIỂN JOYSTICK ẢO (PAN & TILT)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(ble.joystickSensitivity > 0.7 ? "Thể Thao (1.0x)" : (ble.joystickSensitivity > 0.4 ? "Chuẩn (0.6x)" : "Điện Ảnh Mượt (0.3x)"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                        }

                        // Circular Touch Pad
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 170, height: 170)
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5))

                            // Crosshair lines
                            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 140, height: 1)
                            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 140)

                            // Draggable Thumb Knob
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.98, green: 0.72, blue: 0.10), Color.orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                                .shadow(color: Color.black.opacity(0.5), radius: 6)
                                .offset(joystickDragOffset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let maxDist: CGFloat = 58
                                            let dist = hypot(value.translation.width, value.translation.height)
                                            if dist < maxDist {
                                                joystickDragOffset = value.translation
                                            } else {
                                                let angle = atan2(value.translation.height, value.translation.width)
                                                joystickDragOffset = CGSize(width: cos(angle) * maxDist, height: sin(angle) * maxDist)
                                            }
                                            let nx = Double(joystickDragOffset.width / maxDist)
                                            let ny = Double(joystickDragOffset.height / maxDist)
                                            ble.sendManualJoystick(x: nx, y: ny)
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                joystickDragOffset = .zero
                                            }
                                        }
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        // Sensitivity Slider
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Độ Nhạy Phản Hồi: \(Int(ble.joystickSensitivity * 100))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))

                            Slider(value: $ble.joystickSensitivity, in: 0.1...1.0)
                                .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .cornerRadius(18)

                    // 3-AXIS MOTOR TORQUE LIMITS
                    VStack(alignment: .leading, spacing: 14) {
                        Text("LỰC KÉO ĐỘNG CƠ PURE FOC (TORQUE)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        VStack(spacing: 12) {
                            TorqueSliderRow(title: "Pan Motor (Yaw Axis)", value: $ble.panTorque)
                            TorqueSliderRow(title: "Tilt Motor (Pitch Axis)", value: $ble.tiltTorque)
                            TorqueSliderRow(title: "Roll Motor (Horizon Axis)", value: $ble.rollTorque)
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .cornerRadius(18)
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Thiết Bị T-Flow Pro")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $ble.showCalibrationModal) {
                AutoCalibrationModalView(ble: ble)
            }
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

// MARK: - =====================================================================
// 15. AUTO CALIBRATION WIZARD MODAL (SCREEN 31)
// =====================================================================

struct AutoCalibrationModalView: View {
    @ObservedObject var ble: BLEGimbalManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 8)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: CGFloat(ble.calibrationProgress))
                    .stroke(
                        LinearGradient(colors: [Color(red: 0.98, green: 0.72, blue: 0.10), Color.green], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Text("\(Int(ble.calibrationProgress * 100))%")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text("CoG Sync")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            VStack(spacing: 8) {
                Text(ble.calibrationProgress >= 1.0 ? "CÂN BẰNG THÀNH CÔNG!" : "ĐANG HIỆU CHUẨN COG")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ble.calibrationProgress >= 1.0 ? Color.green : Color.white)

                Text(ble.calibrationStepText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            if ble.calibrationProgress >= 1.0 {
                Button("Hoàn Tất & Bắt Đầu Quay") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.98, green: 0.72, blue: 0.10))
                .cornerRadius(16)
                .padding(.horizontal, 24)
            }
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea())
    }
}

// MARK: - =====================================================================
// 16. TAB 3: T-FLOW BOT CHAT VIEW (AI COPILOT)
// =====================================================================

struct TFlowAIChatAssistantView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isUser: false,
            text: "Chào anh Dũng! Em là T-Flow Bot — Trợ lý AI đồng hành cùng Smart Gimbal S1 Titanium. Em có thể hướng dẫn anh các kỹ thuật quay điện ảnh, bật Apple Log 4K/60, hiệu chuẩn động cơ FOC hoặc đồng bộ dữ liệu với Web Admin!"
        )
    ]
    @State private var inputText: String = ""

    let quickChips = [
        "Quay Inception 360°",
        "Cài đặt Apple Log 4K/60",
        "Cân bằng trọng tâm CoG",
        "Báo giá 4 cấu hình Pro",
        "Ngàm MagSafe 45N N52"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick Chips Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickChips, id: \.self) { chip in
                            Button(action: {
                                sendMessage(chip)
                            }) {
                                Text(chip)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.white.opacity(0.08))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(red: 0.07, green: 0.07, blue: 0.09))

                // Chat Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { msg in
                                HStack(alignment: .top, spacing: 10) {
                                    if msg.isUser {
                                        Spacer()
                                        Text(msg.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                            .frame(maxWidth: 280, alignment: .trailing)
                                    } else {
                                        TFlowBrandLogo(size: 26)
                                        Text(msg.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                            .frame(maxWidth: 290, alignment: .leading)
                                        Spacer()
                                    }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Input Bar
                HStack(spacing: 10) {
                    TextField("Hỏi T-Flow Bot về kỹ thuật quay, FOC...", text: $inputText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(20)
                        .foregroundColor(.white)

                    Button(action: {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            sendMessage(inputText)
                            inputText = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.07, green: 0.07, blue: 0.09))
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("T-Flow Bot")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendMessage(_ text: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        messages.append(ChatMessage(isUser: true, text: text))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let reply: String
            let lower = text.lowerBound(target: text.lowercased())
            if text.contains("Inception") || text.contains("360") {
                reply = "🎬 Để quay cú máy Inception 360°:
1. Tại Tab Camera, chọn chế độ '360°' trên thanh Gimbal.
2. Cầm gimbal nằm ngang hướng thẳng vào chủ thể.
3. Gạt cần Joystick ảo sang trái hoặc phải để trục Roll xoay tròn 360° liên tục không điểm dừng!"
            } else if text.contains("Apple Log") || text.contains("4K/60") {
                reply = "🎥 Cài đặt Apple Log 4K/60fps:
1. Bật nút 'PRO' trên thanh HUD đỉnh máy ảnh.
2. Chọn không gian màu 'Apple Log (Flat)'.
3. ISO cố định ở mức 100, góc mở màn trập 180° (1/120s) để đạt dải nhạy sáng dynamic range 14+ stops tối đa!"
            } else if text.contains("CoG") || text.contains("Cân bằng") {
                reply = "⚖️ Tự động cân bằng CoG:
1. Chuyển sang Tab 'T-Flow Pro'.
2. Nhấn nút 'Tự Động Cân Bằng Trọng Tâm (CoG)'.
3. Đặt gimbal đứng yên trong 2 giây để thuật toán FOC quét và triệt tiêu rung sai số ±0.01°."
            } else if text.contains("Báo giá") || text.contains("gói") {
                reply = "📦 Bảng giá 4 gói T-Flow Pro:
• Gói 1: Gimbal Cầm Tay S1 (B2C) — 3.990.000₫
• Gói 2: Cụm Camera AI & Đèn MagSafe — 1.490.000₫
• Gói 3: Bo Mạch STM32 Pure FOC 20kHz — 890.000₫
• Gói 4: Cảm Biến IMU 6 Trục & Encoder 14-bit — 450.000₫"
            } else {
                reply = "Dạ em đã ghi nhận yêu cầu của anh. Gimbal S1 Pro của anh đang hoạt động ở trạng thái hoàn hảo với tần số FOC 20kHz và pin 94%!"
            }
            messages.append(ChatMessage(isUser: false, text: reply))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

extension String {
    func lowerBound(target: String) -> String { self.lowercased() }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

// MARK: - =====================================================================
// 17. TAB 4: USER PROFILE & PERMISSIONS VIEW (SCREEN 35 & 42)
// =====================================================================

struct UserProfilePermissionsView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @State private var showPaywallSheet: Bool = false
    @State private var selectedModuleIndex: Int? = nil

    let moduleTitles = [
        ("AI Vision Optical Tracking", "camera.metering.spot", "Bám nét khuôn mặt & vật thể 60fps"),
        ("Apple Log & ProRes 4K/60fps", "film.stack", "Không gian màu 10-bit Rec.2020"),
        ("Motionlapse Waypoint 5-Point", "point.topleft.down.curvedto.point.bottomright.up", "Lập trình đường bay gimbal 5 điểm"),
        ("Multi-Cam Director Studio", "rectangle.split.2x2", "Đồng bộ đa góc máy qua Wi-Fi/BLE"),
        ("3D LUT Real-time Preview", "slider.horizontal.3", "Áp màu trực tiếp Rec.709 & Teal Orange"),
        ("FOC Motor Micro-Tuning", "waveform.path.ecg", "Xung PWM 20kHz & Lọc Notch 245Hz"),
        ("500Hz Gyro Raw Telemetry", "location.north.circle", "Xuất dữ liệu góc quay IMU thời gian thực")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // TITANIUM VIP MEMBERSHIP CARD
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            HStack(spacing: 10) {
                                TFlowBrandLogo(size: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.userName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(store.userTier)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                }
                            }
                            Spacer()
                            Button(action: {
                                showPaywallSheet = true
                            }) {
                                Text("ĐỔI GÓI")
                                    .font(.system(size: 10, weight: .black))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.18))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }

                        Divider().background(Color.white.opacity(0.12))

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("THIẾT BỊ ĐĂNG KÝ").font(.system(size: 9.5, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text(store.deviceName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: {
                                store.syncWithCloud()
                            }) {
                                HStack(spacing: 5) {
                                    Circle().fill(store.isOnline ? Color.green : Color.red).frame(width: 6, height: 6)
                                    Text(store.isSyncing ? "Đang đồng bộ..." : "Supabase Live")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(store.isOnline ? .green : .red)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.15, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.16), lineWidth: 1))

                    // 7-MODULE INSET GROUPED LIST
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("TRẠNG THÁI 7 MODULE ĐỒNG BỘ TỪ WEB ADMIN CMS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("Cập nhật: \(store.lastSyncTime)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(0..<moduleTitles.count, id: \.self) { idx in
                                let item = moduleTitles[idx]
                                let isEnabled = store.modules.indices.contains(idx) ? store.modules[idx] : true

                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedModuleIndex = idx
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: item.1)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("\(idx + 1). \(item.0)")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white)
                                            Text(item.2)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        Text(isEnabled ? "ĐÃ MỞ KHÓA" : "ĐÃ KHÓA")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(isEnabled ? .green : .red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background((isEnabled ? Color.green : Color.red).opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 16)
                                }

                                if idx < moduleTitles.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }

                    // SYSTEM INFO & LOGOUT
                    VStack(spacing: 12) {
                        HStack {
                            Text("Phiên bản ứng dụng")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("v2.4.1 (Build 241 Pro)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Hồ Sơ & Phân Quyền")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywallSheet) {
                SubscriptionPaywallSheetView(store: store)
            }
            .sheet(item: Binding<ModuleDetailItem?>(
                get: {
                    if let idx = selectedModuleIndex, idx < moduleTitles.count {
                        let t = moduleTitles[idx]
                        return ModuleDetailItem(index: idx, title: t.0, icon: t.1, desc: t.2)
                    }
                    return nil
                },
                set: { _ in selectedModuleIndex = nil }
            )) { detail in
                ModuleDetailInspectorSheet(detail: detail, store: store)
            }
        }
    }
}

struct ModuleDetailItem: Identifiable {
    var id: Int { index }
    let index: Int
    let title: String
    let icon: String
    let desc: String
}

struct ModuleDetailInspectorSheet: View {
    let detail: ModuleDetailItem
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: detail.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                Text(detail.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.top, 24)

            Text(detail.desc)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider().background(Color.white.opacity(0.1))

            let isEnabled = store.modules.indices.contains(detail.index) ? store.modules[detail.index] : true
            HStack {
                Text("Trạng thái kích hoạt cục bộ:")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                Spacer()
                Button(isEnabled ? "TẮT MODULE" : "BẬT MODULE") {
                    store.toggleModule(at: detail.index)
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((isEnabled ? Color.red : Color.green).opacity(0.2))
                .foregroundColor(isEnabled ? .red : .green)
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding(20)
        .background(Color(red: 0.11, green: 0.11, blue: 0.14).ignoresSafeArea())
    }
}

struct SubscriptionPaywallSheetView: View {
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("CẤP ĐỘ GÓI BẢN QUYỀN T-FLOW")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 20)

            VStack(spacing: 12) {
                TierCard(name: "Free Starter", price: "0₫", desc: "Quay cơ bản 1080p, chế độ Pan Follow", activeTier: store.userTier) {
                    store.setTier("Free Starter")
                    dismiss()
                }
                TierCard(name: "Creator Pro", price: "299.000₫ / tháng", desc: "4K 60fps, Apple Log, AI Vision, 3D LUT, Waypoints", activeTier: store.userTier) {
                    store.setTier("Creator Pro")
                    dismiss()
                }
                TierCard(name: "VIP LIFETIME", price: "Trọn Đời Đi Kèm Phần Cứng", desc: "Toàn bộ 7 module không giới hạn, FOC Micro-tuning", activeTier: store.userTier) {
                    store.setTier("VIP LIFETIME")
                    dismiss()
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea())
    }
}

struct TierCard: View {
    let name: String
    let price: String
    let desc: String
    let activeTier: String
    let onSelect: () -> Void

    var isSelected: Bool { activeTier == name }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(desc).font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                    if isSelected {
                        Text("ĐANG DÙNG").font(.system(size: 9, weight: .black)).foregroundColor(.green)
                    }
                }
            }
            .padding(14)
            .background(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color(red: 0.98, green: 0.72, blue: 0.10) : Color.clear, lineWidth: 1.5))
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

// MARK: - =====================================================================
// 19. AVFOUNDATION LIVE CAMERA CAPTURE PREVIEW CONTROLLER
// =====================================================================

struct NativeCameraPreviewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

final class CameraViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = .hd4K3840x2160
        } else if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            captureSession.sessionPreset = .high
        }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(videoInput)
        captureSession.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
}
