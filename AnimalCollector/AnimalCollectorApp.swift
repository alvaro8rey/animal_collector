import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct AnimalCollectorApp: App {
    @StateObject private var gameViewModel = GameViewModel()

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #if DEBUG
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "5328bf3a52b8f9c9b9ce22384f467c04"
        ]
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .preferredColorScheme(.dark)
                .onAppear { requestTrackingIfNeeded() }
        }
    }

    private func requestTrackingIfNeeded() {
        // Delay so the UI is fully visible before the system dialog appears.
        // ATTrackingManager is a no-op if the user already answered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
