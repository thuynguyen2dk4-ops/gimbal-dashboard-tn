//
//  NativeCameraPreviewRepresentable.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - =====================================================================
// 19. AVFOUNDATION LIVE CAMERA CAPTURE PREVIEW CONTROLLER
// =====================================================================

struct NativeCameraPreviewRepresentable: UIViewControllerRepresentable {
    let session: AVCaptureSession
    let isFrontCamera: Bool

    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController(session: session, isFrontCamera: isFrontCamera)
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.updateMirroring(isFrontCamera: isFrontCamera)
    }
}

final class CameraViewController: UIViewController {
    private let captureSession: AVCaptureSession
    private var initialFrontCamera: Bool
    private var previewLayer: AVCaptureVideoPreviewLayer?

    init(session: AVCaptureSession, isFrontCamera: Bool) {
        self.captureSession = session
        self.initialFrontCamera = isFrontCamera
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        bindPreviewLayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func bindPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.previewLayer = layer
        updateMirroring(isFrontCamera: initialFrontCamera)
    }

    func updateMirroring(isFrontCamera: Bool) {
        initialFrontCamera = isFrontCamera
        guard let conn = previewLayer?.connection, conn.isVideoMirroringSupported else { return }
        conn.automaticallyAdjustsVideoMirroring = false
        conn.isVideoMirrored = isFrontCamera
    }
}
