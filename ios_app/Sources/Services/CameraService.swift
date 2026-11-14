//
//  CameraService.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import AVFoundation
import Vision
import Photos
import Combine
import UIKit

// MARK: - =====================================================================
// 5. CAMERA SERVICE & CAPTURE CONTROLLER
// =====================================================================

final class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isSessionRunning: Bool = false
    @Published var isRecording: Bool = false
    @Published var recordingDuration: String = "00:00:00"
    @Published var isFrontCamera: Bool = false
    @Published var selectedResolution: String = "4K • 60"
    @Published var selectedAspectRatio: String = "9:16"
    @Published var shutterFlash: Bool = false
    @Published var latestThumbnail: UIImage? = nil
    @Published var capturedMedia: [CapturedMediaItem] = []
    @Published var detectedFaceRect: CGRect? = nil

    // Camera Mode, Flash & Zoom State
    @Published var selectedMode: String = "VIDEO"
    @Published var zoomFactor: String = "1x"
    @Published var isFlashEnabled: Bool = false

    // Customizable Figma UI States (Node 96:3)
    @Published var isProMode: Bool = false {
        didSet {
            if oldValue && !isProMode {
                selectedAspectRatio = "9:16"
            }
            persistUiPreferences()
        }
    }
    @Published var uiThemeMode: String = "dark" {
        didSet { persistUiPreferences() }
    }
    @Published var showExposureReadout: Bool = true {
        didSet { persistUiPreferences() }
    }
    @Published var showHorizonLevel: Bool = true {
        didSet { persistUiPreferences() }
    }
    @Published var showHistogram: Bool = true {
        didSet { persistUiPreferences() }
    }
    @Published var autoHideControls3s: Bool = true {
        didSet { persistUiPreferences() }
    }
    @Published var touchLockEnabled: Bool = false {
        didSet { persistUiPreferences() }
    }
    @Published var isLandscapeMode: Bool = false

    // AI Multi-Target, Gesture & Timelapse State
    @Published var aiTrackingEnabled: Bool = true
    @Published var aiTargetMode: AITargetMode = .human
    @Published var customObjectLockedPoint: CGPoint? = nil
    @Published var customObjectLabel: String = "Vật thể đã chọn"
    @Published var autoGroupFraming05x: Bool = false
    @Published var gestureControlEnabled: Bool = true
    @Published var selfTimerSeconds: Int = 0
    @Published var micMode: String = "Stereo"
    @Published var isManualExposure: Bool = false

    // Motionlapse 2-Point State
    @Published var motionlapsePointA: CGPoint = CGPoint(x: 0.22, y: 0.45)
    @Published var motionlapsePointB: CGPoint = CGPoint(x: 0.78, y: 0.35)
    @Published var motionlapseHasPointB: Bool = true
    @Published var motionlapseDurationSec: Int = 15
    @Published var motionlapseIntervalSec: Double = 2.0

    var motionlapseTotalFrames: Int {
        if motionlapseDurationSec == 15 && abs(motionlapseIntervalSec - 2.0) < 0.01 {
            return 450
        }
        return max(30, motionlapseDurationSec * 30)
    }

    // Pro Exposure & Audio HUD State
    @Published var iso: Int = 100
    @Published var shutterSpeed: String = "1/120s"
    @Published var ev: Double = 0.0
    @Published var wbKelvin: Int = 5600
    @Published var activeLut: String = "Standard Rec.709"
    @Published var audioLevelL: Double = 0.42
    @Published var audioLevelR: Double = 0.48

    // Quick Settings Viewfinder Overlays (Shared across Camera HUD & Quick Settings)
    @Published var gridEnabled: Bool = true {
        didSet { persistUiPreferences() }
    }
    @Published var zebraEnabled: Bool = false {
        didSet { persistUiPreferences() }
    }
    @Published var peakingEnabled: Bool = false {
        didSet { persistUiPreferences() }
    }
    @Published var antiFlicker: String = "50Hz" {
        didSet { persistUiPreferences() }
    }

    // Compatibility Aliases (Preserves external naming contracts)
    var isoValue: Int {
        get { iso }
        set { iso = newValue }
    }
    var whiteBalanceKelvin: Int {
        get { wbKelvin }
        set { wbKelvin = newValue }
    }
    var evBias: Double {
        get { ev }
        set { ev = newValue }
    }
    var selectedLut: String {
        get { activeLut }
        set { activeLut = newValue }
    }
    var aspectRatio: String {
        get { selectedAspectRatio }
        set { selectedAspectRatio = newValue }
    }

    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "tflow.camera.session.queue")
    private let visionQueue = DispatchQueue(label: "tflow.camera.video.processing")
    private var isSessionConfigured: Bool = false
    private var activePositionFront: Bool = false
    private var currentVideoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var recordingTimer: Timer?
    private var vuTimer: Timer?
    private var recordingSecondsCount: Int = 0
    private var isRestoringPreferences: Bool = false

    private enum PrefKeys {
        static let isProMode = "tflow_ui_is_pro_mode"
        static let uiThemeMode = "tflow_ui_theme_mode"
        static let showExposureReadout = "tflow_ui_show_exposure"
        static let showHorizonLevel = "tflow_ui_show_horizon"
        static let showHistogram = "tflow_ui_show_histogram"
        static let autoHideControls3s = "tflow_ui_autohide_3s"
        static let touchLockEnabled = "tflow_ui_touch_lock"
        static let gridEnabled = "tflow_ui_grid_enabled"
        static let zebraEnabled = "tflow_ui_zebra_enabled"
        static let peakingEnabled = "tflow_ui_peaking_enabled"
        static let antiFlicker = "tflow_ui_anti_flicker"
    }

    override init() {
        super.init()
        loadUiPreferences()
        setupMockThumbnails()
        startAudioVUAnimation()
        setupOrientationObserver()
    }

    deinit {
        vuTimer?.invalidate()
        recordingTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        let session = captureSession
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func setupOrientationObserver() {
        DispatchQueue.main.async {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceOrientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleDeviceOrientationChanged() {
        let orientation = UIDevice.current.orientation
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch orientation {
            case .landscapeLeft, .landscapeRight:
                if !self.isLandscapeMode {
                    self.isLandscapeMode = true
                }
            case .portrait:
                if self.isLandscapeMode {
                    self.isLandscapeMode = false
                }
            default:
                break
            }
        }
    }

    // MARK: - Figma Customizer & AI Target Controls

    func setAspectRatio(_ ratio: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedAspectRatio = ratio
    }

    func setCameraInterfaceMode(pro: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isProMode = pro
    }

    func lockObjectAtNormalizedPoint(_ point: CGPoint, label: String = "Vật thể đã chọn") {
        let clampedX = min(0.95, max(0.05, point.x))
        let clampedY = min(0.95, max(0.05, point.y))
        customObjectLockedPoint = CGPoint(x: clampedX, y: clampedY)
        customObjectLabel = label
        aiTargetMode = .object
        aiTrackingEnabled = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func clearLockedObject() {
        customObjectLockedPoint = nil
        customObjectLabel = "Vật thể đã chọn"
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func setAutoGroupFraming(_ enabled: Bool) {
        autoGroupFraming05x = enabled
        if enabled {
            setZoom(".5")
        }
    }

    func toggleLandscapeHud() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isLandscapeMode.toggle()
    }

    func cycleSelfTimer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch selfTimerSeconds {
        case 0: selfTimerSeconds = 3
        case 3: selfTimerSeconds = 10
        default: selfTimerSeconds = 0
        }
    }

    func cycleMicMode() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch micMode {
        case "Stereo": micMode = "Lọc gió AI"
        case "Lọc gió AI": micMode = "Tắt"
        default: micMode = "Stereo"
        }
    }

    func cycleResolution() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch selectedResolution {
        case "4K • 60": selectedResolution = "4K • 30"
        case "4K • 30": selectedResolution = "1080 • 60"
        default: selectedResolution = "4K • 60"
        }
    }

    // MARK: - Preference Persistence

    private func loadUiPreferences() {
        isRestoringPreferences = true
        defer { isRestoringPreferences = false }
        let defaults = UserDefaults.standard
        if defaults.object(forKey: PrefKeys.isProMode) != nil {
            isProMode = defaults.bool(forKey: PrefKeys.isProMode)
        }
        if let savedTheme = defaults.string(forKey: PrefKeys.uiThemeMode), !savedTheme.isEmpty {
            uiThemeMode = savedTheme
        }
        if defaults.object(forKey: PrefKeys.showExposureReadout) != nil {
            showExposureReadout = defaults.bool(forKey: PrefKeys.showExposureReadout)
        }
        if defaults.object(forKey: PrefKeys.showHorizonLevel) != nil {
            showHorizonLevel = defaults.bool(forKey: PrefKeys.showHorizonLevel)
        }
        if defaults.object(forKey: PrefKeys.showHistogram) != nil {
            showHistogram = defaults.bool(forKey: PrefKeys.showHistogram)
        }
        if defaults.object(forKey: PrefKeys.autoHideControls3s) != nil {
            autoHideControls3s = defaults.bool(forKey: PrefKeys.autoHideControls3s)
        }
        if defaults.object(forKey: PrefKeys.touchLockEnabled) != nil {
            touchLockEnabled = defaults.bool(forKey: PrefKeys.touchLockEnabled)
        }
        if defaults.object(forKey: PrefKeys.gridEnabled) != nil {
            gridEnabled = defaults.bool(forKey: PrefKeys.gridEnabled)
        }
        if defaults.object(forKey: PrefKeys.zebraEnabled) != nil {
            zebraEnabled = defaults.bool(forKey: PrefKeys.zebraEnabled)
        }
        if defaults.object(forKey: PrefKeys.peakingEnabled) != nil {
            peakingEnabled = defaults.bool(forKey: PrefKeys.peakingEnabled)
        }
        if let savedFlicker = defaults.string(forKey: PrefKeys.antiFlicker), !savedFlicker.isEmpty {
            antiFlicker = savedFlicker
        }
    }

    private func persistUiPreferences() {
        guard !isRestoringPreferences else { return }
        let defaults = UserDefaults.standard
        defaults.set(isProMode, forKey: PrefKeys.isProMode)
        defaults.set(uiThemeMode, forKey: PrefKeys.uiThemeMode)
        defaults.set(showExposureReadout, forKey: PrefKeys.showExposureReadout)
        defaults.set(showHorizonLevel, forKey: PrefKeys.showHorizonLevel)
        defaults.set(showHistogram, forKey: PrefKeys.showHistogram)
        defaults.set(autoHideControls3s, forKey: PrefKeys.autoHideControls3s)
        defaults.set(touchLockEnabled, forKey: PrefKeys.touchLockEnabled)
        defaults.set(gridEnabled, forKey: PrefKeys.gridEnabled)
        defaults.set(zebraEnabled, forKey: PrefKeys.zebraEnabled)
        defaults.set(peakingEnabled, forKey: PrefKeys.peakingEnabled)
        defaults.set(antiFlicker, forKey: PrefKeys.antiFlicker)
    }

    private func setupMockThumbnails() {
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
        vuTimer?.invalidate()
        vuTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelL = min(1.0, max(0.08, self.audioLevelL + Double.random(in: -0.15...0.15)))
            self.audioLevelR = min(1.0, max(0.08, self.audioLevelR + Double.random(in: -0.15...0.15)))
        }
    }

    // MARK: - AVCaptureSession Pipeline (Preserved IOS-BUG-01)

    func setupSession() {
        let wantFront = isFrontCamera
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isSessionConfigured {
                self.captureSession.beginConfiguration()
                if self.captureSession.canSetSessionPreset(.hd4K3840x2160) {
                    self.captureSession.sessionPreset = .hd4K3840x2160
                } else if self.captureSession.canSetSessionPreset(.hd1920x1080) {
                    self.captureSession.sessionPreset = .hd1920x1080
                } else {
                    self.captureSession.sessionPreset = .high
                }

                let position: AVCaptureDevice.Position = wantFront ? .front : .back
                let deviceType: AVCaptureDevice.DeviceType = wantFront ? .builtInTrueDepthCamera : .builtInWideAngleCamera
                let device = AVCaptureDevice.default(deviceType, for: .video, position: position)
                    ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)

                if let device = device,
                   let input = try? AVCaptureDeviceInput(device: device),
                   self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    self.currentVideoInput = input
                }

                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.setSampleBufferDelegate(self, queue: self.visionQueue)
                if self.captureSession.canAddOutput(output) {
                    self.captureSession.addOutput(output)
                    self.videoOutput = output
                }

                self.activePositionFront = wantFront
                self.captureSession.commitConfiguration()
                self.isSessionConfigured = true
            }

            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }

    func switchCamera() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isFrontCamera.toggle()
        let nextFront = isFrontCamera

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isSessionConfigured {
                self.activePositionFront = nextFront
                return
            }

            self.captureSession.beginConfiguration()
            if let current = self.currentVideoInput {
                self.captureSession.removeInput(current)
                self.currentVideoInput = nil
            }

            let newPosition: AVCaptureDevice.Position = nextFront ? .front : .back
            let deviceType: AVCaptureDevice.DeviceType = nextFront ? .builtInTrueDepthCamera : .builtInWideAngleCamera
            let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: newPosition)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)

            if let dev = newDevice,
               let newInput = try? AVCaptureDeviceInput(device: dev),
               self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.currentVideoInput = newInput
            }
            self.activePositionFront = nextFront
            self.captureSession.commitConfiguration()
        }
    }

    func toggleFlash() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isFlashEnabled.toggle()
        let nextEnabled = isFlashEnabled
        sessionQueue.async { [weak self] in
            guard let device = self?.currentVideoInput?.device,
                  device.hasTorch,
                  device.isTorchModeSupported(nextEnabled ? .on : .off) else { return }
            try? device.lockForConfiguration()
            device.torchMode = nextEnabled ? .on : .off
            device.unlockForConfiguration()
        }
    }

    func setZoom(_ label: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        zoomFactor = label
        let targetScale: CGFloat
        switch label {
        case ".5": targetScale = 1.0
        case "2", "2x": targetScale = 2.0
        case "5", "5x": targetScale = 5.0
        default: targetScale = 1.0
        }
        sessionQueue.async { [weak self] in
            guard let device = self?.currentVideoInput?.device else { return }
            let clamped = max(device.minAvailableVideoZoomFactor, min(targetScale, min(device.activeFormat.videoMaxZoomFactor, 8.0)))
            try? device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        }
    }

    func deleteMedia(_ item: CapturedMediaItem) {
        capturedMedia.removeAll { $0.id == item.id }
        latestThumbnail = capturedMedia.first?.image
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func capturePhoto() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        shutterFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.shutterFlash = false
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        let photo = renderer.image { ctx in
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
            let snapText = ("T-FLOW S1 PRO • " + selectedResolution + " • " + dateStr) as NSString
            snapText.draw(
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
                let clipText = ("CLIP 4K PRORES • " + durationStr + " • " + activeLut) as NSString
                clipText.draw(
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
            isRecording = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            recordingSecondsCount = 0
            recordingDuration = "00:00:00"

            recordingTimer?.invalidate()
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

            // Vision boundingBox uses lower-left origin in the oriented image space.
            // Convert cleanly to SwiftUI top-left normalized coordinates.
            let box = firstFace.boundingBox
            let normalized = CGRect(
                x: box.minX,
                y: 1.0 - box.maxY,
                width: box.width,
                height: box.height
            )

            DispatchQueue.main.async {
                self?.detectedFaceRect = normalized
            }
        }

        let orientation: CGImagePropertyOrientation = activePositionFront ? .leftMirrored : .right
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        try? handler.perform([request])
    }
}
