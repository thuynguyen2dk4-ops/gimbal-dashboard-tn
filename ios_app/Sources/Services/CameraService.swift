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

    // Quick Settings Viewfinder Overlays (Shared across Camera HUD & Quick Settings)
    @Published var gridEnabled: Bool = true
    @Published var zebraEnabled: Bool = false
    @Published var peakingEnabled: Bool = false
    @Published var antiFlicker: String = "50Hz"

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

    override init() {
        super.init()
        setupMockThumbnails()
        startAudioVUAnimation()
    }

    deinit {
        vuTimer?.invalidate()
        recordingTimer?.invalidate()
        let session = captureSession
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
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
        vuTimer?.invalidate()
        vuTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelL = min(1.0, max(0.08, self.audioLevelL + Double.random(in: -0.15...0.15)))
            self.audioLevelR = min(1.0, max(0.08, self.audioLevelR + Double.random(in: -0.15...0.15)))
        }
    }

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
            // Start recording
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
