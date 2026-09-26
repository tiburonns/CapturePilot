import SwiftUI

@main
struct CapturePilotApp: App {
    @UIApplicationDelegateAdaptor(CapturePilotAppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var hud = HUDLayoutStore()
    @StateObject private var lutLibrary = LUTLibraryStore()
    @StateObject private var rankings = PhotoRankingStore()
    @StateObject private var social = SocialCompetitionService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(hud)
                .environmentObject(lutLibrary)
                .environmentObject(rankings)
                .environmentObject(social)
        }
    }
}
