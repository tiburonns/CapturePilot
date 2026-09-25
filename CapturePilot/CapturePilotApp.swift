import SwiftUI

@main
struct CapturePilotApp: App {
    @UIApplicationDelegateAdaptor(CapturePilotAppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var hud = HUDLayoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(hud)
        }
    }
}
