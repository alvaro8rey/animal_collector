import SwiftUI
import GoogleMobileAds

@main
struct AnimalCollectorApp: App {
    @StateObject private var gameViewModel = GameViewModel()

    init() {
        MobileAds.shared.start(completionHandler: nil)
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
            "cab5d71812d48a303721fc50fc2c0f1d"
        ]
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
