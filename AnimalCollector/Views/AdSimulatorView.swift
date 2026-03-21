import SwiftUI

/// Simulates a rewarded ad experience. In production, replace with the real ad SDK call.
struct AdSimulatorView: View {
    @EnvironmentObject var vm: GameViewModel
    @Binding var isPresented: Bool

    @State private var phase: Phase = .watching
    @State private var secondsLeft: Int = 5
    @State private var timer: Timer? = nil
    @State private var showReward = false

    private enum Phase { case watching, rewarded }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .watching:
                watchingView
            case .rewarded:
                rewardedView
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Watching phase

    private var watchingView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Fake ad placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )

                VStack(spacing: 16) {
                    Text("📺")
                        .font(.system(size: 64))

                    Text("Anuncio")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Recompensa: +2 sobres")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .padding(.horizontal, 24)

            Spacer()

            // Countdown
            VStack(spacing: 8) {
                Text("Anuncio termina en")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: CGFloat(5 - secondsLeft) / 5.0)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: secondsLeft)

                    Text("\(secondsLeft)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Rewarded phase

    private var rewardedView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 72))
                    .scaleEffect(showReward ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showReward)

                VStack(spacing: 8) {
                    Text("¡Recompensa obtenida!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("+2 sobres añadidos")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .opacity(showReward ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.2), value: showReward)

                // Pack icons
                HStack(spacing: 12) {
                    ForEach(0..<2, id: \.self) { _ in
                        Text("📦")
                            .font(.system(size: 40))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                }
                .opacity(showReward ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.4), value: showReward)
            }

            Spacer()

            Button(action: close) {
                Text("¡Abrir sobres!")
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.95), .white.opacity(0.75)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(showReward ? 1 : 0)
            .animation(.easeIn(duration: 0.3).delay(0.6), value: showReward)
        }
        .onAppear { showReward = true }
    }

    // MARK: - Logic

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if secondsLeft > 1 {
                    secondsLeft -= 1
                } else {
                    timer?.invalidate()
                    vm.rewardAdPacks()
                    withAnimation { phase = .rewarded }
                }
            }
        }
    }

    private func close() {
        isPresented = false
    }
}
