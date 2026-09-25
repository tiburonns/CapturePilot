import AVFoundation
import SwiftUI
import UIKit

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func showFocusReticle(at point: CGPoint) {
        let size: CGFloat = 64
        let reticle = UIView(frame: CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size))
        reticle.layer.borderWidth = 1.5
        reticle.layer.borderColor = UIColor.systemYellow.cgColor
        reticle.layer.cornerRadius = 8
        reticle.alpha = 0
        addSubview(reticle)

        UIView.animate(withDuration: 0.12, animations: {
            reticle.alpha = 1
            reticle.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
        }) { _ in
            UIView.animate(withDuration: 0.55, delay: 0.35, options: [.curveEaseOut], animations: {
                reticle.alpha = 0
                reticle.transform = .identity
            }) { _ in
                reticle.removeFromSuperview()
            }
        }
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

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
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
