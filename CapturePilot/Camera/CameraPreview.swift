import AVFoundation
import SwiftUI
import UIKit

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureRotationIfNeeded()
        applyCurrentRotation()
    }

    func configureRotationIfNeeded() {
        guard let input = previewLayer.session?.inputs
            .compactMap({ $0 as? AVCaptureDeviceInput })
            .first else { return }

        if rotationCoordinator?.device !== input.device {
            rotationObservation = nil

            let coordinator = AVCaptureDevice.RotationCoordinator(
                device: input.device,
                previewLayer: previewLayer
            )
            rotationCoordinator = coordinator

            rotationObservation = coordinator.observe(
                \.videoRotationAngleForHorizonLevelPreview,
                options: [.initial, .new]
            ) { [weak self] _, _ in
                self?.applyCurrentRotation()
            }
        }
    }

    func showFocusReticle(at point: CGPoint) {
        let size: CGFloat = 64
        let reticle = UIView(
            frame: CGRect(
                x: point.x - size / 2,
                y: point.y - size / 2,
                width: size,
                height: size
            )
        )
        reticle.layer.borderWidth = 1.5
        reticle.layer.borderColor = UIColor.systemYellow.cgColor
        reticle.layer.cornerRadius = 8
        reticle.alpha = 0
        addSubview(reticle)

        UIView.animate(withDuration: 0.12, animations: {
            reticle.alpha = 1
            reticle.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
        }) { _ in
            UIView.animate(
                withDuration: 0.55,
                delay: 0.35,
                options: [.curveEaseOut],
                animations: {
                    reticle.alpha = 0
                    reticle.transform = .identity
                }
            ) { _ in
                reticle.removeFromSuperview()
            }
        }
    }

    private func applyCurrentRotation() {
        guard let coordinator = rotationCoordinator,
              let connection = previewLayer.connection else { return }

        let angle = coordinator.videoRotationAngleForHorizonLevelPreview
        guard connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let onTapToFocus: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTapToFocus: onTapToFocus)
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }

        uiView.configureRotationIfNeeded()
        context.coordinator.onTapToFocus = onTapToFocus
    }

    final class Coordinator: NSObject {
        var onTapToFocus: (CGPoint) -> Void

        init(onTapToFocus: @escaping (CGPoint) -> Void) {
            self.onTapToFocus = onTapToFocus
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? CameraPreviewView else { return }
            let layerPoint = recognizer.location(in: view)
            let devicePoint = view.previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
            view.showFocusReticle(at: layerPoint)
            onTapToFocus(devicePoint)
        }
    }
}
