import SwiftUI

struct ExchangeView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var obtainedAnimal: Animal? = nil
    @State private var showResult = false
    @State private var animateResult = false
    @State private var showExchangeError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.04).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        exchangeRows
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Trade")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showResult) {
            if let animal = obtainedAnimal {
                ExchangeResultSheet(animal: animal, isPresented: $showResult)
            }
        }
        .alert("No se pudo canjear", isPresented: $showExchangeError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No hay animales disponibles para canjear en esta rareza.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Convierte duplicados en nuevas cartas")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Exchange rows

    private var exchangeRows: some View {
        VStack(spacing: 16) {
            ForEach(GameViewModel.exchangeRates, id: \.from) { rate in
                ExchangeRow(
                    fromRarity: rate.from,
                    toRarity: rate.to,
                    cost: rate.cost,
                    currentDupes: vm.totalDuplicates(for: rate.from),
                    missingTargets: vm.unownedAnimals(of: rate.to).isEmpty,
                    canExchange: vm.canExchange(from: rate.from)
                ) {
                    if let animal = vm.exchangeDuplicates(from: rate.from) {
                        obtainedAnimal = animal
                        showResult = true
                    } else {
                        showExchangeError = true
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Exchange Row

private struct ExchangeRow: View {
    let fromRarity: Rarity
    let toRarity: Rarity
    let cost: Int
    let currentDupes: Int
    let missingTargets: Bool
    let canExchange: Bool
    let onExchange: () -> Void

    @State private var pressing = false

    private var progress: Double { min(Double(currentDupes) / Double(cost), 1.0) }

    var body: some View {
        VStack(spacing: 14) {
            // Rarity arrows
            HStack(spacing: 12) {
                rarityChip(fromRarity)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                rarityChip(toRarity)
                Spacer()
                costBadge
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(currentDupes) / \(cost) duplicados")
                        .font(.caption)
                        .foregroundColor(currentDupes >= cost ? fromRarity.color : .gray)
                    Spacer()
                    if missingTargets {
                        Text("Colección \(toRarity.displayName) completa")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: fromRarity.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.easeOut(duration: 0.4), value: progress)
                    }
                }
                .frame(height: 6)
            }

            // Exchange button
            Button(action: onExchange) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                    Text(buttonLabel)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(buttonBackground)
                .cornerRadius(12)
                .scaleEffect(pressing ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: pressing)
            }
            .disabled(!canExchange)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressing = true }
                    .onEnded { _ in pressing = false }
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            canExchange
                                ? fromRarity.borderGradient
                                : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: canExchange ? 1.5 : 1
                        )
                )
        )
    }

    private var buttonLabel: String {
        if missingTargets { return "Ya tienes todas las \(toRarity.displayName)" }
        if currentDupes >= cost { return "Canjear por 1 \(toRarity.displayName)" }
        return "Faltan \(cost - currentDupes) duplicados"
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if canExchange {
            LinearGradient(
                colors: fromRarity.gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.85)
        } else {
            Color.white.opacity(0.07)
        }
    }

    private var costBadge: some View {
        Text("\(cost) dupes")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.gray)
    }

    private func rarityChip(_ rarity: Rarity) -> some View {
        Text(rarity.displayName)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    colors: rarity.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).opacity(0.25)
            )
            .overlay(
                Capsule()
                    .strokeBorder(rarity.color.opacity(0.5), lineWidth: 1)
            )
            .clipShape(Capsule())
            .foregroundColor(rarity.color)
    }
}

// MARK: - Result Sheet

private struct ParticleItem: Identifiable {
    let id = UUID()
    var offset: CGSize = .zero
    var opacity: Double = 1
    let angle: Double
    let distance: CGFloat
    let scale: CGFloat
}

private struct ExchangeResultSheet: View {
    let animal: Animal
    @Binding var isPresented: Bool

    @State private var showFlash = false
    @State private var glowPulse = false
    @State private var titleVisible = false
    @State private var cardVisible = false
    @State private var infoVisible = false
    @State private var buttonVisible = false
    @State private var cardScale: CGFloat = 0.3
    @State private var cardRotation: Double = -15
    @State private var particles: [ParticleItem] = []

    private var particleSymbol: String {
        let e = animal.rarity.particleEmoji
        return e.isEmpty ? "✦" : e
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Pulsing radial glow
            RadialGradient(
                colors: [animal.rarity.glowColor.opacity(0.45), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 320
            )
            .scaleEffect(glowPulse ? 1.35 : 1.0)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }

            // Burst particles
            ForEach(particles) { p in
                Text(particleSymbol)
                    .font(.title2)
                    .scaleEffect(p.scale)
                    .offset(p.offset)
                    .opacity(p.opacity)
            }

            // White flash overlay
            Color.white
                .opacity(showFlash ? 0.45 : 0)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Title
                VStack(spacing: 6) {
                    Text("¡Nuevo animal!")
                        .font(.title.weight(.heavy))
                        .foregroundColor(.white)
                        .shadow(color: animal.rarity.glowColor, radius: 8)
                        .scaleEffect(titleVisible ? 1 : 0.4)
                        .opacity(titleVisible ? 1 : 0)
                    Text("Has canjeado tus duplicados")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .opacity(infoVisible ? 1 : 0)
                }

                // Card
                AnimalCardView(animal: animal, isRevealed: true, size: .large)
                    .shadow(color: animal.rarity.glowColor.opacity(0.9), radius: 45)
                    .scaleEffect(cardScale)
                    .rotationEffect(.degrees(cardRotation))
                    .opacity(cardVisible ? 1 : 0)

                // Animal info
                VStack(spacing: 4) {
                    Text(animal.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    Text(animal.scientificName)
                        .font(.caption).italic()
                        .foregroundColor(.gray)
                    RarityBadgeView(rarity: animal.rarity)
                        .padding(.top, 4)
                }
                .opacity(infoVisible ? 1 : 0)
                .offset(y: infoVisible ? 0 : 18)

                Spacer()

                Button(action: { isPresented = false }) {
                    Text("Continuar")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: animal.rarity.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .opacity(buttonVisible ? 1 : 0)
                .offset(y: buttonVisible ? 0 : 22)
            }
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // Flash
        withAnimation(.easeOut(duration: 0.12)) { showFlash = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) { showFlash = false }

        // Title bounces in
        withAnimation(.spring(response: 0.38, dampingFraction: 0.48).delay(0.15)) {
            titleVisible = true
        }

        // Card flips + overshoots
        withAnimation(.spring(response: 0.55, dampingFraction: 0.58).delay(0.3)) {
            cardVisible = true
            cardScale = 1.0
            cardRotation = 0
        }

        // Particles burst at card moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { burstParticles() }

        // Info
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.7)) {
            infoVisible = true
        }

        // Button
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.9)) {
            buttonVisible = true
        }
    }

    private func burstParticles() {
        let count = 10
        particles = (0..<count).map { i in
            ParticleItem(
                angle: Double(i) * (360.0 / Double(count)) + Double.random(in: -12...12),
                distance: CGFloat.random(in: 90...175),
                scale: CGFloat.random(in: 0.7...1.6)
            )
        }

        for i in particles.indices {
            let rad = particles[i].angle * .pi / 180
            let target = CGSize(
                width: cos(rad) * particles[i].distance,
                height: sin(rad) * particles[i].distance
            )
            withAnimation(.easeOut(duration: 0.65)) {
                particles[i].offset = target
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.35)) {
                particles[i].opacity = 0
            }
        }
    }
}
