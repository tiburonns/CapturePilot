import UIKit

enum OrientationPolicy {
    static let landscapeKey = "settings.orientation.landscape"
    static let upsideDownKey = "settings.orientation.upsideDown"

    static var supportedMask: UIInterfaceOrientationMask {
        var mask: UIInterfaceOrientationMask = .portrait

        if storedBool(forKey: landscapeKey, defaultValue: true) {
            mask.formUnion(.landscape)
        }

        if storedBool(forKey: upsideDownKey, defaultValue: true) {
            mask.insert(.portraitUpsideDown)
        }

        return mask
    }

    @MainActor
    static func applyCurrentPolicy() {
        let mask = supportedMask

        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.windows.forEach {
                $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }

            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { error in
                #if DEBUG
                print("CapturePilot orientation request was not applied: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private static func storedBool(forKey key: String, defaultValue: Bool) -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}

final class CapturePilotAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationPolicy.supportedMask
    }
}
