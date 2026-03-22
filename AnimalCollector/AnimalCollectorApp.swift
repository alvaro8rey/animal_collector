import SwiftUI
import GoogleMobileAds

@main
struct AnimalCollectorApp: App {
    @StateObject private var gameViewModel = GameViewModel()

    init() {
        MobileAds.shared.start(completionHandler: nil)
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
            "5328bf3a52b8f9c9b9ce22384f467c04"
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
