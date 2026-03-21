import SwiftUI
import GoogleMobileAds

@main
struct AnimalCollectorApp: App {
    @StateObject private var gameViewModel = GameViewModel()

    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
