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

    func showFocusReticle(at point: CGPoint, locked: Bool = false) {
        let size: CGFloat = 68
        let reticle = UIView(
            frame: CGRect(
                x: point.x - size / 2,
                y: point.y - size / 2,
                width: size,
                height: size
            )
        )
        reticle.layer.borderWidth = 1.5
        reticle.layer.borderColor = (
            locked ? UIColor.systemOrange : UIColor.systemYellow
        ).cgColor
        reticle.layer.cornerRadius = 8
        reticle.alpha = 0

        if locked {
            let label = UILabel()
            label.text = "AF/AE LOCK"
            label.font = .monospacedSystemFont(ofSize: 9, weight: .semibold)
            label.textColor = .systemOrange
            label.sizeToFit()
            label.center = CGPoint(x: size / 2, y: size + 12)
            reticle.addSubview(label)
        }

        addSubview(reticle)

        UIView.animate(withDuration: 0.12, animations: {
            reticle.alpha = 1
            reticle.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
        }) { _ in
            UIView.animate(
                withDuration: 0.55,
                delay: locked ? 0.7 : 0.35,
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
    let onLongPressAFAE: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTapToFocus: onTapToFocus,
            onLongPressAFAE: onLongPressAFAE
        )
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.45
        longPress.allowableMovement = 18

        tap.require(toFail: longPress)

        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(longPress)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }

        uiView.configureRotationIfNeeded()
        context.coordinator.onTapToFocus = onTapToFocus
        context.coordinator.onLongPressAFAE = onLongPressAFAE
    }

    final class Coordinator: NSObject {
        var onTapToFocus: (CGPoint) -> Void
        var onLongPressAFAE: (CGPoint) -> Void

        init(
            onTapToFocus: @escaping (CGPoint) -> Void,
            onLongPressAFAE: @escaping (CGPoint) -> Void
        ) {
            self.onTapToFocus = onTapToFocus
            self.onLongPressAFAE = onLongPressAFAE
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? CameraPreviewView else { return }
            let layerPoint = recognizer.location(in: view)
            let devicePoint = view.previewLayer.captureDevicePointConverted(
                fromLayerPoint: layerPoint
            )
            view.showFocusReticle(at: layerPoint)
            onTapToFocus(devicePoint)
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began,
                  let view = recognizer.view as? CameraPreviewView else { return }

            let layerPoint = recognizer.location(in: view)
            let devicePoint = view.previewLayer.captureDevicePointConverted(
                fromLayerPoint: layerPoint
            )
            view.showFocusReticle(at: layerPoint, locked: true)
            onLongPressAFAE(devicePoint)
        }
    }
}
