import SwiftUI
import GoogleMobileAds

// MARK: - SwiftUI wrapper

struct AdSimulatorView: View {
    @EnvironmentObject var vm: GameViewModel
    @Binding var isPresented: Bool

    @State private var coordinator: RewardedAdCoordinator?
    @State private var phase: Phase = .loading
    @State private var hasStarted = false

    // Reward animation state
    @State private var rewardAppeared = false
    @State private var pack1Scale: CGFloat = 0.3
    @State private var pack2Scale: CGFloat = 0.3
    @State private var pack1Opacity: Double = 0
    @State private var pack2Opacity: Double = 0
    @State private var titleScale: CGFloat = 0.5
    @State private var titleOpacity: Double = 0
    @State private var glowPulse = false
    @State private var particleProgress: Double = 0

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
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            loadAndShow()
        }
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
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.05, blue: 0.18),
                    Color(red: 0.04, green: 0.02, blue: 0.10)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Particles
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * 30.0 * .pi / 180.0
                let distance: CGFloat = 200
                Circle()
                    .fill(i % 3 == 0 ? Color.yellow : i % 3 == 1 ? Color.purple.opacity(0.8) : Color.blue.opacity(0.7))
                    .frame(width: CGFloat.random(in: 4...9))
                    .offset(
                        x: cos(angle) * distance * particleProgress,
                        y: sin(angle) * distance * particleProgress - 40
                    )
                    .opacity(particleProgress < 0.6
                        ? particleProgress / 0.6
                        : (1 - particleProgress) / 0.4)
            }

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 6) {
                    Text("¡RECOMPENSA!")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.2), .white, Color(red: 1.0, green: 0.6, blue: 0.1)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.yellow.opacity(0.6), radius: glowPulse ? 16 : 8)
                        .scaleEffect(titleScale)
                        .opacity(titleOpacity)

                    Text("Has ganado 2 sobres")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                        .opacity(titleOpacity)
                }

                Spacer().frame(height: 48)

                // Pack images
                HStack(spacing: 28) {
                    packImage
                        .scaleEffect(pack1Scale)
                        .opacity(pack1Opacity)
                        .rotationEffect(.degrees(rewardAppeared ? -8 : 0))

                    packImage
                        .scaleEffect(pack2Scale)
                        .opacity(pack2Opacity)
                        .rotationEffect(.degrees(rewardAppeared ? 8 : 0))
                }
                .shadow(color: Color(red: 0.25, green: 0.5, blue: 1.0).opacity(glowPulse ? 0.7 : 0.35), radius: glowPulse ? 28 : 16)

                Spacer()

                // CTA button
                Button(action: { isPresented = false }) {
                    HStack(spacing: 10) {
                        Image(systemName: "gift.fill")
                            .font(.headline)
                        Text("¡Abrir sobres!")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    )
                    .shadow(color: Color.yellow.opacity(0.4), radius: 12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
                .opacity(titleOpacity)
            }
        }
        .onAppear { animateReward() }
    }

    private var packImage: some View {
        Group {
            if UIImage(named: "pack_image") != nil {
                Image("pack_image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
            } else {
                PackSpriteView()
                    .scaleEffect(0.6)
            }
        }
    }

    private func animateReward() {
        guard !rewardAppeared else { return }
        rewardAppeared = true

        // Particles burst
        withAnimation(.spring(response: 0.9, dampingFraction: 0.65)) {
            particleProgress = 1.0
        }

        // Title drops in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }
        }

        // Pack 1 bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                pack1Scale = 1.0
                pack1Opacity = 1.0
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // Pack 2 bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                pack2Scale = 1.0
                pack2Opacity = 1.0
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // Glow pulse starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Ad logic

    private func loadAndShow() {
        #if targetEnvironment(simulator)
        // El simulador no puede reproducir vídeo de AdMob → simular el anuncio directamente
        simulateFakeAd()
        #else
        loadRealAd()
        #endif
    }

    // Simulación fake para el simulador: muestra "anuncio" durante 3 s y otorga recompensa
    private func simulateFakeAd() {
        Task {
            try? await Task.sleep(for: .seconds(3))
            vm.rewardAdPacks()
            phase = .rewarded
        }
    }

    private func loadRealAd() {
        #if DEBUG
        let adUnitID = "ca-app-pub-3940256099942544/1712485313"  // ID de test oficial de Google
        #else
        let adUnitID = "ca-app-pub-9606090335798660/1210235038"
        #endif

        let c = RewardedAdCoordinator(
            adUnitID: adUnitID,
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
final class RewardedAdCoordinator: NSObject, GADFullScreenContentDelegate {

    private let adUnitID: String
    private let onRewarded: () -> Void
    private let onFailed: () -> Void
    private var rewardedAd: GADRewardedAd?

    init(adUnitID: String, onRewarded: @escaping () -> Void, onFailed: @escaping () -> Void) {
        self.adUnitID = adUnitID
        self.onRewarded = onRewarded
        self.onFailed = onFailed
    }

    func loadAndPresent() {
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
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

        // Subir hasta el VC más alto para no bloquear presentaciones modales ya activas
        var topVC = root
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        ad.present(fromRootViewController: topVC) { [weak self] in
            // Este bloque solo se llama si el usuario VIO el anuncio completo
            self?.onRewarded()
        }
    }

    // El usuario cerró el anuncio antes de terminar → no recompensar
    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.onFailed() }
    }
}
