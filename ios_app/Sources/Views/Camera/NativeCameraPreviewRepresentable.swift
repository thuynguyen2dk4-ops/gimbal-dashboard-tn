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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateVideoOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.previewLayer?.frame = self.view.bounds
            self.updateVideoOrientation()
        }, completion: { _ in
            self.previewLayer?.frame = self.view.bounds
            self.updateVideoOrientation()
        })
    }

    @objc private func handleOrientationChange() {
        updateVideoOrientation()
    }

    private func bindPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.previewLayer = layer
        updateVideoOrientation()
        updateMirroring(isFrontCamera: initialFrontCamera)
    }

    func updateVideoOrientation() {
        guard let conn = previewLayer?.connection, conn.isVideoOrientationSupported else { return }
        let interfaceOrientation = view.window?.windowScene?.interfaceOrientation
            ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.interfaceOrientation
            ?? .portrait
        let target: AVCaptureVideoOrientation
        switch interfaceOrientation {
        case .portrait:
            target = .portrait
        case .portraitUpsideDown:
            target = .portraitUpsideDown
        case .landscapeLeft:
            target = .landscapeLeft
        case .landscapeRight:
            target = .landscapeRight
        default:
            target = .portrait
        }
        if conn.videoOrientation != target {
            conn.videoOrientation = target
        }
    }

    func updateMirroring(isFrontCamera: Bool) {
        initialFrontCamera = isFrontCamera
        guard let conn = previewLayer?.connection, conn.isVideoMirroringSupported else { return }
        conn.automaticallyAdjustsVideoMirroring = false
        conn.isVideoMirrored = isFrontCamera
    }
}
