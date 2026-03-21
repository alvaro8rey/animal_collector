import SwiftUI
import GoogleMobileAds

// MARK: - SwiftUI wrapper

struct AdSimulatorView: View {
    @EnvironmentObject var vm: GameViewModel
    @Binding var isPresented: Bool

    @State private var coordinator: RewardedAdCoordinator?
    @State private var phase: Phase = .loading

    private enum Phase { case loading, failed, rewarded }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .loading:
                loadingView

            case .failed:
                failedView

            case .rewarded:
                rewardedView
            }
        }
        .onAppear { loadAndShow() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.4)
            Text("Cargando anuncio...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Failed

    private var failedView: some View {
        VStack(spacing: 24) {
            Text("⚠️")
                .font(.system(size: 52))

            VStack(spacing: 8) {
                Text("Anuncio no disponible")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("No hay anuncios en este momento.\nInténtalo de nuevo más tarde.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            Button(action: { isPresented = false }) {
                Text("Cerrar")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.85)))
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Rewarded

    private var rewardedView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 72))

                VStack(spacing: 8) {
                    Text("¡Recompensa obtenida!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("+2 sobres añadidos")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                HStack(spacing: 12) {
                    ForEach(0..<2, id: \.self) { _ in
                        Text("📦")
                            .font(.system(size: 40))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(.white.opacity(0.1), lineWidth: 1))
                            )
                    }
                }
            }

            Spacer()

            Button(action: { isPresented = false }) {
                Text("¡Abrir sobres!")
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.95), .white.opacity(0.75)],
                            startPoint: .leading, endPoint: .trailing
                        )))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Ad logic

    private func loadAndShow() {
        let c = RewardedAdCoordinator(
            adUnitID: "ca-app-pub-9606090335798660/1210235038",
            onRewarded: {
                vm.rewardAdPacks()
                phase = .rewarded
            },
            onFailed: {
                phase = .failed
            }
        )
        coordinator = c
        c.loadAndPresent()
    }
}

// MARK: - Ad coordinator (UIKit bridge)

@MainActor
final class RewardedAdCoordinator: NSObject, FullScreenContentDelegate {

    private let adUnitID: String
    private let onRewarded: () -> Void
    private let onFailed: () -> Void
    private var rewardedAd: RewardedAd?

    init(adUnitID: String, onRewarded: @escaping () -> Void, onFailed: @escaping () -> Void) {
        self.adUnitID = adUnitID
        self.onRewarded = onRewarded
        self.onFailed = onFailed
    }

    func loadAndPresent() {
        RewardedAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                print("AdMob load error: \(error.localizedDescription)")
                self.onFailed()
                return
            }
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.present()
        }
    }

    private func present() {
        guard let ad = rewardedAd,
              let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController
        else {
            onFailed()
            return
        }

        ad.present(from: root) { [weak self] in
            // Este bloque solo se llama si el usuario VIO el anuncio completo
            self?.onRewarded()
        }
    }

    // El usuario cerró el anuncio antes de terminar → no recompensar
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.onFailed() }
    }
}
