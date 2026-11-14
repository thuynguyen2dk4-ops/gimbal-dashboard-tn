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

final class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
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
    @Published var trackedObjectRect: CGRect? = nil
    @Published var lastCaptureError: String? = nil

    // Camera Mode, Flash & Zoom State
    @Published var selectedMode: String = "VIDEO"
    @Published var zoomFactor: String = "1x"
    @Published var isFlashEnabled: Bool = false

    // Customizable Figma UI States (Node 96:3)
    @Published var isProMode: Bool = false {
        didSet {
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
    private var currentAudioInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var visionSequenceHandler = VNSequenceRequestHandler()
    private var activeTrackObservation: VNDetectedObjectObservation?
    private var pendingRecordingDuration: String = "00:00:00"
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
        loadPersistedMediaFromDisk()
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
        guard !isRecording else { return }
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
        let boxSize: CGFloat = 0.22
        let visionRect = CGRect(
            x: min(max(0.0, clampedX - boxSize * 0.5), 1.0 - boxSize),
            y: min(max(0.0, (1.0 - clampedY) - boxSize * 0.5), 1.0 - boxSize),
            width: boxSize,
            height: boxSize
        )
        visionQueue.async { [weak self] in
            self?.visionSequenceHandler = VNSequenceRequestHandler()
            self?.activeTrackObservation = VNDetectedObjectObservation(boundingBox: visionRect)
        }
        customObjectLockedPoint = CGPoint(x: clampedX, y: clampedY)
        trackedObjectRect = CGRect(x: clampedX - boxSize * 0.5, y: clampedY - boxSize * 0.5, width: boxSize, height: boxSize)
        customObjectLabel = label
        aiTargetMode = .object
        aiTrackingEnabled = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func clearLockedObject() {
        visionQueue.async { [weak self] in
            self?.activeTrackObservation = nil
            self?.visionSequenceHandler = VNSequenceRequestHandler()
        }
        customObjectLockedPoint = nil
        trackedObjectRect = nil
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

    private struct PersistedMediaRecord: Codable {
        let id: UUID
        let fileName: String
        let isVideo: Bool
        let duration: String?
        let timestamp: Date
        let resolution: String
        let profile: String
        let fileSizeBytes: Int64
    }

    private var mediaDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("TFlowMedia", isDirectory: true)
    }

    private var manifestFileURL: URL {
        mediaDirectoryURL.appendingPathComponent("manifest.json")
    }

    var realPhotoCount: Int {
        capturedMedia.filter { !$0.isVideo }.count
    }

    var realVideoCount: Int {
        capturedMedia.filter { $0.isVideo }.count
    }

    var realTotalStorageBytes: Int64 {
        capturedMedia.reduce(0) { $0 + $1.fileSizeBytes }
    }

    var realVideoStorageBytes: Int64 {
        capturedMedia.filter { $0.isVideo }.reduce(0) { $0 + $1.fileSizeBytes }
    }

    var realPhotoStorageBytes: Int64 {
        capturedMedia.filter { !$0.isVideo }.reduce(0) { $0 + $1.fileSizeBytes }
    }

    var totalLibraryStorageBytesFormatted: String {
        formatByteCount(realTotalStorageBytes)
    }

    var videoStorageFormatted: String {
        formatByteCount(realVideoStorageBytes)
    }

    var photoStorageFormatted: String {
        formatByteCount(realPhotoStorageBytes)
    }

    private func formatByteCount(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 KB" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func ensureMediaDirectoryExists() {
        if !FileManager.default.fileExists(atPath: mediaDirectoryURL.path) {
            try? FileManager.default.createDirectory(at: mediaDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private func loadPersistedMediaFromDisk() {
        ensureMediaDirectoryExists()
        guard let data = try? Data(contentsOf: manifestFileURL),
              let records = try? JSONDecoder().decode([PersistedMediaRecord].self, from: data) else {
            capturedMedia = []
            latestThumbnail = nil
            return
        }

        var loaded: [CapturedMediaItem] = []
        for record in records {
            let fileURL = mediaDirectoryURL.appendingPathComponent(record.fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                continue
            }
            var itemVideoURL: URL? = nil
            var previewImage: UIImage? = nil
            var diskSize: Int64 = record.fileSizeBytes

            if record.isVideo && record.fileName.lowercased().hasSuffix(".mov") {
                itemVideoURL = fileURL
                let thumbURL = mediaDirectoryURL.appendingPathComponent("\(record.id.uuidString).thumb.jpg")
                if let thumbData = try? Data(contentsOf: thumbURL), let img = UIImage(data: thumbData) {
                    previewImage = img
                } else {
                    previewImage = generateVideoThumbnailSync(for: fileURL)
                }
                if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let sizeNum = attrs[.size] as? NSNumber {
                    diskSize = sizeNum.int64Value
                }
            } else if let imgData = try? Data(contentsOf: fileURL),
                      let image = UIImage(data: imgData) {
                previewImage = image
                diskSize = Int64(imgData.count)
            }

            guard let finalImage = previewImage else { continue }
            loaded.append(
                CapturedMediaItem(
                    id: record.id,
                    image: finalImage,
                    isVideo: record.isVideo,
                    duration: record.duration,
                    timestamp: record.timestamp,
                    resolution: record.resolution,
                    profile: record.profile,
                    fileName: record.fileName,
                    fileSizeBytes: record.fileSizeBytes > 0 ? record.fileSizeBytes : diskSize,
                    videoURL: itemVideoURL
                )
            )
        }
        capturedMedia = loaded
        latestThumbnail = loaded.first?.image
    }

    private func saveManifestToDisk() {
        ensureMediaDirectoryExists()
        let records = capturedMedia.map {
            PersistedMediaRecord(
                id: $0.id,
                fileName: $0.fileName,
                isVideo: $0.isVideo,
                duration: $0.duration,
                timestamp: $0.timestamp,
                resolution: $0.resolution,
                profile: $0.profile,
                fileSizeBytes: $0.fileSizeBytes
            )
        }
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: manifestFileURL, options: .atomic)
        }
    }

    func addAndPersistMedia(_ item: CapturedMediaItem) {
        ensureMediaDirectoryExists()
        var stored = item
        if stored.isVideo, let sourceVideoURL = stored.videoURL {
            if stored.fileName.isEmpty {
                stored.fileName = "\(stored.id.uuidString).mov"
            }
            let targetVideoURL = mediaDirectoryURL.appendingPathComponent(stored.fileName)
            if sourceVideoURL != targetVideoURL {
                try? FileManager.default.removeItem(at: targetVideoURL)
                do {
                    try FileManager.default.moveItem(at: sourceVideoURL, to: targetVideoURL)
                } catch {
                    try? FileManager.default.copyItem(at: sourceVideoURL, to: targetVideoURL)
                }
            }
            stored.videoURL = targetVideoURL
            let thumbURL = mediaDirectoryURL.appendingPathComponent("\(stored.id.uuidString).thumb.jpg")
            if let thumbData = stored.image.jpegData(compressionQuality: 0.85) {
                try? thumbData.write(to: thumbURL, options: .atomic)
            }
            if let attrs = try? FileManager.default.attributesOfItem(atPath: targetVideoURL.path),
               let sizeNum = attrs[.size] as? NSNumber {
                stored.fileSizeBytes = sizeNum.int64Value
            }
        } else {
            if stored.fileName.isEmpty {
                stored.fileName = "\(stored.id.uuidString).jpg"
            }
            let targetURL = mediaDirectoryURL.appendingPathComponent(stored.fileName)
            if let encoded = stored.image.jpegData(compressionQuality: 0.92) ?? stored.image.pngData() {
                try? encoded.write(to: targetURL, options: .atomic)
                stored.fileSizeBytes = Int64(encoded.count)
            }
        }
        capturedMedia.insert(stored, at: 0)
        latestThumbnail = stored.image
        saveManifestToDisk()
    }

    private func generateVideoThumbnailSync(for url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        guard let cgImg = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        return UIImage(cgImage: cgImg)
    }

    private func saveImageToPhotosLibraryIfAllowed(_ imageData: Data) {
        let saveBlock = {
            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetCreationRequest.forAsset()
                req.addResource(with: .photo, data: imageData, options: nil)
            }, completionHandler: nil)
        }
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .authorized || status == .limited {
            saveBlock()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    saveBlock()
                }
            }
        }
    }

    private func saveVideoToPhotosLibraryIfAllowed(_ videoURL: URL) {
        let saveBlock = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }, completionHandler: nil)
        }
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .authorized || status == .limited {
            saveBlock()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    saveBlock()
                }
            }
        }
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
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                } else {
                    DispatchQueue.main.async {
                        self?.lastCaptureError = "Vui lòng cấp quyền Camera trong Cài đặt iPhone."
                    }
                }
            }
            return
        }
        guard authStatus == .authorized else {
            DispatchQueue.main.async { [weak self] in
                self?.lastCaptureError = "Quyền truy cập Camera đang bị từ chối."
            }
            return
        }

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

                if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
                   let audioDev = AVCaptureDevice.default(for: .audio),
                   let audioInput = try? AVCaptureDeviceInput(device: audioDev),
                   self.captureSession.canAddInput(audioInput) {
                    self.captureSession.addInput(audioInput)
                    self.currentAudioInput = audioInput
                }

                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.setSampleBufferDelegate(self, queue: self.visionQueue)
                if self.captureSession.canAddOutput(output) {
                    self.captureSession.addOutput(output)
                    self.videoOutput = output
                }

                let photoOut = AVCapturePhotoOutput()
                if self.captureSession.canAddOutput(photoOut) {
                    self.captureSession.addOutput(photoOut)
                    self.photoOutput = photoOut
                }

                let movieOut = AVCaptureMovieFileOutput()
                if self.captureSession.canAddOutput(movieOut) {
                    self.captureSession.addOutput(movieOut)
                    self.movieOutput = movieOut
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
                self.lastCaptureError = nil
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            DispatchQueue.main.async {
                self.isSessionRunning = false
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
        if !item.fileName.isEmpty {
            let fileURL = mediaDirectoryURL.appendingPathComponent(item.fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let videoURL = item.videoURL {
            try? FileManager.default.removeItem(at: videoURL)
        }
        let thumbURL = mediaDirectoryURL.appendingPathComponent("\(item.id.uuidString).thumb.jpg")
        try? FileManager.default.removeItem(at: thumbURL)
        capturedMedia.removeAll { $0.id == item.id }
        latestThumbnail = capturedMedia.first?.image
        saveManifestToDisk()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func capturePhoto() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        shutterFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.shutterFlash = false
        }

        let resSnapshot = selectedResolution
        let lutSnapshot = activeLut
        sessionQueue.async { [weak self] in
            guard let self = self,
                  self.captureSession.isRunning,
                  let photoOut = self.photoOutput,
                  photoOut.connection(with: .video) != nil else {
                DispatchQueue.main.async {
                    self?.lastCaptureError = "Camera chưa sẵn sàng để chụp ảnh (hãy dùng iPhone thực hoặc cấp quyền Camera)."
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
                return
            }
            let settings = AVCapturePhotoSettings()
            if photoOut.supportedFlashModes.contains(self.isFlashEnabled ? .on : .off) {
                settings.flashMode = self.isFlashEnabled ? .on : .off
            }
            photoOut.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.lastCaptureError = "Lỗi chụp ảnh: \(error.localizedDescription)"
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            return
        }
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async { [weak self] in
                self?.lastCaptureError = "Không thể đọc dữ liệu ảnh từ cảm biến Camera."
            }
            return
        }

        saveImageToPhotosLibraryIfAllowed(imageData)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let newItem = CapturedMediaItem(
                image: image,
                isVideo: false,
                duration: nil,
                resolution: self.selectedResolution,
                profile: self.activeLut
            )
            self.addAndPersistMedia(newItem)
            self.lastCaptureError = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func toggleRecording() {
        if isRecording {
            pendingRecordingDuration = recordingDuration
            isRecording = false
            recordingTimer?.invalidate()
            recordingTimer = nil
            recordingDuration = "00:00:00"
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                if let movieOut = self.movieOutput, movieOut.isRecording {
                    movieOut.stopRecording()
                }
            }
        } else {
            sessionQueue.async { [weak self] in
                guard let self = self,
                      self.captureSession.isRunning,
                      let movieOut = self.movieOutput,
                      let videoConn = movieOut.connection(with: .video) else {
                    DispatchQueue.main.async {
                        self?.lastCaptureError = "Camera chưa sẵn sàng để quay video."
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                    return
                }
                if videoConn.isVideoMirroringSupported {
                    videoConn.automaticallyAdjustsVideoMirroring = false
                    videoConn.isVideoMirrored = self.activePositionFront
                }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("tflow_rec_\(UUID().uuidString).mov")
                try? FileManager.default.removeItem(at: tempURL)
                movieOut.startRecording(to: tempURL, recordingDelegate: self)

                DispatchQueue.main.async {
                    self.isRecording = true
                    self.lastCaptureError = nil
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.recordingSecondsCount = 0
                    self.recordingDuration = "00:00:00"
                    self.recordingTimer?.invalidate()
                    self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                        guard let self = self else { return }
                        self.recordingSecondsCount += 1
                        let m = self.recordingSecondsCount / 60
                        let s = self.recordingSecondsCount % 60
                        self.recordingDuration = String(format: "00:%02d:%02d", m, s)
                    }
                }
            }
        }
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            try? FileManager.default.removeItem(at: outputFileURL)
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = false
                self?.recordingTimer?.invalidate()
                self?.recordingTimer = nil
                self?.lastCaptureError = "Lỗi ghi hình video: \(error.localizedDescription)"
            }
            return
        }

        let thumb = generateVideoThumbnailSync(for: outputFileURL) ?? UIImage()
        let savedDuration = pendingRecordingDuration == "00:00:00" ? "00:00:01" : pendingRecordingDuration
        let itemId = UUID()
        let movFileName = "\(itemId.uuidString).mov"

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let newItem = CapturedMediaItem(
                id: itemId,
                image: thumb,
                isVideo: true,
                duration: savedDuration,
                resolution: self.selectedResolution,
                profile: self.activeLut,
                fileName: movFileName,
                videoURL: outputFileURL
            )
            self.addAndPersistMedia(newItem)
            if let finalURL = self.capturedMedia.first(where: { $0.id == itemId })?.videoURL {
                self.saveVideoToPhotosLibraryIfAllowed(finalURL)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orientation: CGImagePropertyOrientation = activePositionFront ? .leftMirrored : .right

        if aiTrackingEnabled, let trackedObs = activeTrackObservation {
            let trackReq = VNTrackObjectRequest(detectedObjectObservation: trackedObs) { [weak self] req, _ in
                guard let self = self else { return }
                if let updated = req.results?.first as? VNDetectedObjectObservation, updated.confidence > 0.3 {
                    self.activeTrackObservation = updated
                    let box = updated.boundingBox
                    let normalized = CGRect(
                        x: box.minX,
                        y: 1.0 - box.maxY,
                        width: box.width,
                        height: box.height
                    )
                    DispatchQueue.main.async {
                        self.trackedObjectRect = normalized
                        self.customObjectLockedPoint = CGPoint(x: normalized.midX, y: normalized.midY)
                    }
                }
            }
            trackReq.trackingLevel = .fast
            try? visionSequenceHandler.perform([trackReq], on: pixelBuffer, orientation: orientation)
            return
        }

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

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        try? handler.perform([request])
    }
}
