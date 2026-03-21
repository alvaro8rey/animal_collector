import SwiftUI

// MARK: - Main Pack Opening Flow

struct PackOpeningView: View {
    @EnvironmentObject var vm: GameViewModel
    let packType: PackType
    @Binding var isPresented: Bool

    @State private var phase: Phase = .packIdle
    @State private var cards: [Animal] = []
    @State private var currentIndex: Int = 0
    @State private var revealedCards: [Animal] = []
    @State private var packScale: CGFloat = 1.0
    @State private var packOpacity: Double = 1.0
    @State private var packRotation: Double = 0

    enum Phase { case packIdle, opening, revealing, summary }

    var body: some View {
        ZStack {
            // Background
            Color(white: 0.04).ignoresSafeArea()
            starfieldBackground

            switch phase {
            case .packIdle:
                packIdleView
            case .opening:
                packOpeningAnimation
            case .revealing:
                if currentIndex < cards.count {
                    cardRevealView
                }
            case .summary:
                summaryView
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Pack Idle

    private var packIdleView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(packType.rawValue.uppercased())
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.6))
                .tracking(4)

            // Pack visual
            ZStack {
                // Glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(packType.gradientColors[0].opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                        .frame(width: CGFloat(200 + i * 50))
                }

                PackSpriteView(packType: packType)
                    .scaleEffect(packScale)
                    .rotationEffect(.degrees(packRotation))
            }
            .frame(height: 320)
            .onAppear { startPackIdle() }

            Text(packType.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: startOpening) {
                HStack(spacing: 10) {
                    Text("Abrir Sobre")
                        .font(.headline)
                        .fontWeight(.bold)
                    Image(systemName: "gift.fill")
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: packType.gradientColors, startPoint: .leading, endPoint: .trailing))
                )
            }
            .padding(.horizontal, 32)

            Button("Cancelar") { isPresented = false }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 16)
        }
    }

    private func startPackIdle() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            packScale = 1.05
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            packRotation = 3
        }
    }

    // MARK: - Opening Animation

    private var packOpeningAnimation: some View {
        ZStack {
            PackSpriteView(packType: packType)
                .scaleEffect(packScale)
                .opacity(packOpacity)
        }
    }

    private func startOpening() {
        cards = vm.openPack(packType)
        phase = .opening

        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            packScale = 1.35
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.35)) {
                packScale = 0.01
                packOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                phase = .revealing
            }
        }
    }

    // MARK: - Card Reveal

    private var cardRevealView: some View {
        let animal = cards[currentIndex]
        let isLast = currentIndex == cards.count - 1

        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.title3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Card flip reveal
            FlipCardView(animal: animal, isLast: isLast)

            Spacer()

            // Action
            Button(action: advanceCard) {
                HStack(spacing: 8) {
                    Text(currentIndex < cards.count - 1 ? "Siguiente" : "Ver resumen")
                        .fontWeight(.semibold)
                    Image(systemName: currentIndex < cards.count - 1 ? "arrow.right" : "checkmark")
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: animal.rarity.gradientColors,
                            startPoint: .leading, endPoint: .trailing
                        ))
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .id(currentIndex) // force re-render on index change for animation
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func advanceCard() {
        if currentIndex < cards.count - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                currentIndex += 1
            }
        } else {
            withAnimation { phase = .summary }
        }
    }

    // MARK: - Summary

    private var summaryView: some View {
        VStack(spacing: 0) {
            Text("¡Sobre Abierto!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 24)

            // Cards grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { idx, animal in
                        VStack(spacing: 4) {
                            AnimalCardView(animal: animal, size: .small)
                            if idx == cards.count - 1 {
                                Text("MEJOR CARTA")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.yellow)
                                    .tracking(1)
                            }
                        }
                        .scaleEffect(idx == cards.count - 1 ? 1.06 : 1.0)
                        .animation(.spring(response: 0.3).delay(Double(idx) * 0.08), value: true)
                    }
                }
                .padding(20)

                // Duplicate coins earned
                let dupCount = cards.filter { card in
                    vm.collection.first(where: { $0.id == card.id })?.duplicateCount ?? 0 > 0
                }.count
                if dupCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.yellow)
                        Text("+\(dupCount * vm.duplicateReward) monedas por duplicados")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.bottom, 8)
                }
            }

            Button(action: { isPresented = false }) {
                Text("Cerrar")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                                 startPoint: .leading, endPoint: .trailing))
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Background

    private var starfieldBackground: some View {
        GeometryReader { geo in
            ForEach(0..<40, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.03...0.12)))
                    .frame(width: Double.random(in: 1...3))
                    .position(
                        x: CGFloat(i * 47 % Int(geo.size.width)),
                        y: CGFloat(i * 83 % Int(geo.size.height))
                    )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Pack Sprite

private struct PackSpriteView: View {
    let packType: PackType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 220)

            RoundedRectangle(cornerRadius: 20)
                .fill(packType.gradient.opacity(0.2))
                .frame(width: 160, height: 220)

            VStack(spacing: 12) {
                Text(packType.emoji)
                    .font(.system(size: 64))
                Text(packType.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(3)
                Text("\(PackType.basic.cardsPerPack) cartas")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }

            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(packType.gradient, lineWidth: 2)
                .frame(width: 160, height: 220)
        }
        .shadow(color: packType.gradientColors[0].opacity(0.5), radius: 20)
    }
}

// MARK: - Flip Card

private struct FlipCardView: View {
    let animal: Animal
    let isLast: Bool

    @State private var flipped = false
    @State private var showGlow = false

    var body: some View {
        ZStack {
            // Back side
            CardBackView(packType: .basic)
                .rotation3DEffect(.degrees(flipped ? 90 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 0 : 1)

            // Front side
            AnimalCardView(animal: animal, size: .large)
                .rotation3DEffect(.degrees(flipped ? 0 : -90), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 1 : 0)
                .shadow(color: animal.rarity.glowColor.opacity(showGlow ? 0.8 : 0), radius: showGlow ? 30 : 0)
        }
        .onAppear { reveal() }
        .overlay(alignment: .top) {
            if isLast && flipped {
                Text("⭐ MEJOR CARTA")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                    .tracking(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                    .offset(y: -16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isLast && flipped)
    }

    private func reveal() {
        withAnimation(.easeIn(duration: 0.25)) {
            flipped = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                flipped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showGlow = animal.rarity >= .rare
                }
            }
        }
    }
}
