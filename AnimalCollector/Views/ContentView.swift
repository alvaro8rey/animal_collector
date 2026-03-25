import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            GachaView()
                .tabItem {
                    Label("Sobres", systemImage: "gift.fill")
                }
                .tag(0)

            CollectionView()
                .tabItem {
                    Label("Colección", systemImage: "square.grid.3x3.fill")
                }
                .tag(1)

            ExchangeView()
                .tabItem {
                    Label("Trade", systemImage: "arrow.2.circlepath")
                }
                .tag(2)
        }
        .tint(.yellow)
        .preferredColorScheme(.dark)
        .onAppear { vm.refreshFromRemote() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { vm.refreshDailyStateIfNeeded() }
        }
    }
}
