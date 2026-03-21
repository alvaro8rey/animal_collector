import SwiftUI

// MARK: - Main Pack Opening Flow

struct PackOpeningView: View {
    @EnvironmentObject var vm: GameViewModel
    let packType: PackType
    @Binding var isPresented: Bool

    // MARK: State

    @State private var phase: Phase = .packIdle
    @State private var cards: [Animal] = []

    // Pack idle
    @State private var packIdleScale: CGFloat = 1.0
    @State private var packIdleRotation: Double = 0

    // Opening animation
    @State private var shakeAngle: Double = 0
    @State private var openingScale: CGFloat = 1.0
    @State private var packTopFly: CGFloat = 0
    @State private var packBottomFly: CGFloat = 0
    @State private var packOpacity: Double = 1.0
    @State private var flashOpacity: Double = 0

    // Carousel
    @State private var carouselIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var flippedCards: Set<Int> = []

    enum Phase { case packIdle, opening, carousel, summary }

    private let cardSpacing: CGFloat = 230

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(white: 0.04).ignoresSafeArea()
            starfieldBackground

            switch phase {
            case .packIdle:  packIdleView
            case .opening:   openingView
            case .carousel:  carouselPhaseView
            case .summary:   summaryView
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

            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(packType.gradientColors[0].opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                        .frame(width: CGFloat(200 + i * 50))
                }
                PackSpriteView(packType: packType)
                    .scaleEffect(packIdleScale)
                    .rotationEffect(.degrees(packIdleRotation))
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
            packIdleScale = 1.05
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            packIdleRotation = 3
        }
    }

    // MARK: - Opening Animation View

    private var openingView: some View {
        ZStack {
            // Flash overlay
            packType.gradientColors[0]
                .ignoresSafeArea()
                .opacity(flashOpacity * 0.65)
                .blendMode(.screen)

            // Pack top half flying up
            PackSpriteView(packType: packType)
                .mask {
                    VStack(spacing: 0) {
                        Rectangle().frame(height: 110)
                        Color.clear.frame(height: 110)
                    }
                }
                .rotationEffect(.degrees(shakeAngle))
                .scaleEffect(openingScale)
                .offset(y: -packTopFly)
                .opacity(packOpacity)

            // Pack bottom half flying down
            PackSpriteView(packType: packType)
                .mask {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 110)
                        Rectangle().frame(height: 110)
                    }
                }
                .rotationEffect(.degrees(shakeAngle))
                .scaleEffect(openingScale)
                .offset(y: packBottomFly)
                .opacity(packOpacity)
        }
    }

    private func startOpening() {
        cards = vm.openPack(packType)
        phase = .opening

        // Reset opening state
        shakeAngle = 0; openingScale = 1.0
        packTopFly = 0; packBottomFly = 0
        packOpacity = 1.0; flashOpacity = 0

        // Phase 1: Shake 0–0.55s
        let angles: [Double] = [0, -9, 9, -8, 8, -7, 7, -6, 6, -3, 0]
        for (i, angle) in angles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.055) {
                withAnimation(.easeInOut(duration: 0.045)) { shakeAngle = angle }
            }
        }

        // Phase 2: Scale up 0.62s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
                openingScale = 1.4
            }
        }

        // Phase 3: Flash + tear apart 0.74s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.74) {
            withAnimation(.easeIn(duration: 0.1)) { flashOpacity = 1.0 }
            withAnimation(.easeOut(duration: 0.5)) {
                packTopFly = 340
                packBottomFly = 340
                packOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.88) {
            withAnimation(.easeOut(duration: 0.4)) { flashOpacity = 0 }
        }

        // Phase 4: Transition to carousel 1.3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            carouselIndex = 0
            flippedCards = []
            withAnimation(.spring(response: 0.5)) { phase = .carousel }
            // Auto-flip first card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    flippedCards.insert(0)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    // MARK: - Carousel

    private var carouselPhaseView: some View {
        VStack(spacing: 0) {
            // Navigation header
            HStack(spacing: 20) {
                Button {
                    guard carouselIndex > 0 else { return }
                    navigateTo(carouselIndex - 1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title)
                        .foregroundStyle(carouselIndex > 0 ? .white.opacity(0.8) : .white.opacity(0.15))
                }

                Text("\(carouselIndex + 1) / \(cards.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 60)

                Button {
                    guard carouselIndex < cards.count - 1 else { return }
                    navigateTo(carouselIndex + 1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title)
                        .foregroundStyle(carouselIndex < cards.count - 1 ? .white.opacity(0.8) : .white.opacity(0.15))
                }

                Spacer()

                Button { withAnimation { phase = .summary } } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow.opacity(0.85))
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)

            Text("Desliza o toca para revelar")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.top, 6)

            Spacer()

            // Card carousel
            ZStack {
                ForEach(Array(cards.enumerated()), id: \.offset) { idx, animal in
                    carouselCardView(idx: idx, animal: animal)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 340)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { val in dragOffset = val.translation.width }
                    .onEnded { val in
                        let velocity = val.predictedEndTranslation.width
                        if velocity < -80, carouselIndex < cards.count - 1 {
                            navigateTo(carouselIndex + 1)
                        } else if velocity > 80, carouselIndex > 0 {
                            navigateTo(carouselIndex - 1)
                        } else {
                            withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                        }
                    }
            )

            // Dot indicators
            HStack(spacing: 6) {
                ForEach(0..<cards.count, id: \.self) { idx in
                    Circle()
                        .fill(idx == carouselIndex ? Color.white : Color.white.opacity(0.25))
                        .frame(width: idx == carouselIndex ? 8 : 5)
                        .animation(.spring(response: 0.3), value: carouselIndex)
                }
            }
            .padding(.top, 16)

            Spacer()

            // Bottom action
            Button(action: { withAnimation { phase = .summary } }) {
                HStack(spacing: 8) {
                    Text(flippedCards.count == cards.count ? "Ver resumen" : "Saltar al resumen")
                        .fontWeight(.semibold)
                    Image(systemName: flippedCards.count == cards.count ? "checkmark" : "forward.fill")
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: flippedCards.count == cards.count
                                ? packType.gradientColors
                                : [Color.white.opacity(0.45), Color.white.opacity(0.3)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private func carouselCardView(idx: Int, animal: Animal) -> some View {
        let relPos = CGFloat(idx - carouselIndex)
        let rawOffset = relPos * cardSpacing + dragOffset
        let normalizedDist = abs(rawOffset) / cardSpacing
        let scale = max(0.68, 1.0 - normalizedDist * 0.2)
        let yOffset: CGFloat = normalizedDist * 18
        let rotDeg = Double(-rawOffset / 30)
        let isCenter = idx == carouselIndex

        Group {
            if flippedCards.contains(idx) {
                AnimalCardView(animal: animal, size: .large)
                    .overlay(alignment: .bottom) {
                        if idx == bestCardIndex {
                            Text("⭐ MEJOR CARTA")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.yellow)
                                .tracking(2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.black.opacity(0.55)))
                                .offset(y: 18)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
            } else {
                CardBackView(packType: packType)
                    .overlay(alignment: .center) {
                        if isCenter {
                            VStack(spacing: 6) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.45))
                                Text("Toca para revelar")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .offset(y: 75)
                        }
                    }
            }
        }
        .scaleEffect(scale)
        .rotation3DEffect(.degrees(rotDeg), axis: (x: 0, y: 1, z: 0))
        .offset(x: rawOffset, y: yOffset)
        .zIndex(isCenter ? 10 : max(0, 5.0 - normalizedDist))
        .opacity(abs(rawOffset) > cardSpacing * 2.4 ? 0 : 1)
        .onTapGesture {
            guard isCenter, !flippedCards.contains(idx) else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                flippedCards.insert(idx)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func navigateTo(_ index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            carouselIndex = index
            dragOffset = 0
        }
        if !flippedCards.contains(index) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    flippedCards.insert(index)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private var bestCardIndex: Int {
        cards.indices.max(by: { cards[$0].rarity < cards[$1].rarity }) ?? 0
    }

    // MARK: - Summary (no overlap fix)

    private var summaryView: some View {
        VStack(spacing: 0) {
            Text("¡Sobre Abierto!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 24)

            ScrollView {
                VStack(spacing: 16) {
                    // Row 1: first 3 cards
                    HStack(spacing: 10) {
                        ForEach(0..<min(3, cards.count), id: \.self) { idx in
                            summaryCardCell(idx: idx)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Row 2: remaining cards centred
                    if cards.count > 3 {
                        HStack(spacing: 10) {
                            Spacer(minLength: 0)
                            ForEach(3..<cards.count, id: \.self) { idx in
                                summaryCardCell(idx: idx)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Duplicate coins
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
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
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

    @ViewBuilder
    private func summaryCardCell(idx: Int) -> some View {
        let isBest = idx == bestCardIndex
        VStack(spacing: 0) {
            // Space at top for the badge if best card
            if isBest {
                Text("MEJOR CARTA")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.yellow)
                    .tracking(1)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
            } else {
                // Invisible spacer to keep alignment consistent
                Text(" ")
                    .font(.system(size: 7))
                    .padding(.vertical, 2)
                    .opacity(0)
            }
            AnimalCardView(animal: cards[idx], size: .small)
        }
        .animation(.spring(response: 0.3).delay(Double(idx) * 0.08), value: true)
    }

    // MARK: - Starfield Background

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
