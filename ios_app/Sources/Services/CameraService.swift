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
