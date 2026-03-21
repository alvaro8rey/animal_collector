import SwiftUI

// MARK: - Pack Image View (shared between GachaView and PackOpeningView)

struct PackImageView: View {
    var body: some View {
        Group {
            if UIImage(named: "pack_image") != nil {
                Image("pack_image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 330)
            } else {
                PackSpriteView()
            }
        }
    }
}

// MARK: - Main Pack Opening Flow

struct PackOpeningView: View {
    @EnvironmentObject var vm: GameViewModel
    let packType: PackType
    @Binding var isPresented: Bool

    // MARK: State

    @State private var phase: Phase
    @State private var cards: [Animal]

    // Pack idle
    @State private var packIdleScale: CGFloat = 1.0
    @State private var packIdleRotation: Double = 0

    // Opening animation
    @State private var shakeAngle: Double = 0
    @State private var openingScale: CGFloat = 1.0
    @State private var packOpacity: Double = 1.0
    @State private var flashOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.01
    @State private var ringOpacity: Double = 0
    @State private var burstProgress: Double = 0

    // Carousel
    @State private var carouselIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var flippedCards: Set<Int> = []

    enum Phase { case packIdle, opening, carousel, summary }

    // MARK: - Init

    init(packType: PackType, isPresented: Binding<Bool>, preDrawnCards: [Animal]? = nil) {
        self.packType = packType
        self._isPresented = isPresented
        if let preDrawn = preDrawnCards {
            self._phase = State(initialValue: .carousel)
            self._cards = State(initialValue: preDrawn)
        } else {
            self._phase = State(initialValue: .packIdle)
            self._cards = State(initialValue: [])
        }
    }

    private let cardSpacing: CGFloat = 230

    private let burstConfigs: [(dx: CGFloat, dy: CGFloat, rot: Double)] = [
        (-130, -90, -28),
        (-65, -145, -14),
        (0, -160, 0),
        (65, -145, 14),
        (130, -90, 28)
    ]

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
        .onAppear {
            if phase == .carousel {
                // Empezamos directamente en el carrusel: auto-revelar primera carta
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { flippedCards.insert(0) }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }

    // MARK: - Pack Idle (tap to open)

    private var packIdleView: some View {
        ZStack {
            // Close button top-left
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    Spacer()
                }
                Spacer()
            }

            // Central content
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(packType.gradientColors[0].opacity(0.18 - Double(i) * 0.05), lineWidth: 1)
                            .frame(width: CGFloat(220 + i * 60))
                    }

                    PackImageView()
                        .scaleEffect(packIdleScale)
                        .rotationEffect(.degrees(packIdleRotation))
                        .shadow(color: packType.gradientColors[0].opacity(0.5), radius: 28)
                }
                .frame(height: 340)
                .contentShape(Rectangle())
                .onTapGesture { startOpening() }
                .onAppear { startPackIdle() }

                Text("▲  TOCA PARA ABRIR  ▲")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                    .tracking(2)
                    .onTapGesture { startOpening() }

                Spacer()
            }
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
            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)

            Circle()
                .stroke(
                    LinearGradient(colors: packType.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: max(0.5, 5 * (1 - ringScale * 0.5))
                )
                .frame(width: 320, height: 320)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .stroke(packType.gradientColors[0].opacity(0.35), lineWidth: 2)
                .frame(width: 320, height: 320)
                .scaleEffect(ringScale * 1.35)
                .opacity(ringOpacity * 0.5)

            ForEach(0..<5, id: \.self) { i in
                let cfg = burstConfigs[i]
                RoundedRectangle(cornerRadius: 4)
                    .fill(packType.gradient)
                    .frame(width: 28, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .rotationEffect(.degrees(cfg.rot * burstProgress))
                    .offset(x: cfg.dx * burstProgress, y: cfg.dy * burstProgress)
                    .scaleEffect(0.45 + burstProgress * 0.35)
                    .opacity(burstProgress < 0.65 ? 1.0 : max(0, (1 - burstProgress) * 2.86))
            }

            PackImageView()
                .rotationEffect(.degrees(shakeAngle))
                .scaleEffect(openingScale)
                .opacity(packOpacity)
        }
    }

    private func startOpening() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        cards = vm.openPack(packType).sorted { $0.rarity < $1.rarity }
        phase = .opening

        shakeAngle = 0; openingScale = 1.0; packOpacity = 1.0
        flashOpacity = 0; ringScale = 0.01; ringOpacity = 0; burstProgress = 0

        // Shake: 31 frames × 0.05s ≈ 1.55s (+1s respecto al anterior)
        let angles: [Double] = [
            0, -11, 10, -10, 9, -9, 8, -8, 7, -7,
            6, -6, 5, -5, 5, -5, 4, -4, 4, -4,
            3, -3, 2, -2, 1, -1, 0, -1, 1, -1, 0
        ]
        for (i, angle) in angles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.04)) { shakeAngle = angle }
            }
        }

        // Scale up (0.56 + 1.0 = 1.56s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.56) {
            withAnimation(.spring(response: 0.14, dampingFraction: 0.38)) {
                openingScale = 1.5
            }
        }

        // Flash + burst + ring (0.70 + 1.0 = 1.70s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.70) {
            withAnimation(.easeIn(duration: 0.07)) { flashOpacity = 1.0 }
            withAnimation(.easeOut(duration: 0.18)) {
                packOpacity = 0
                openingScale = 2.2
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                burstProgress = 1.0
            }
            withAnimation(.easeOut(duration: 1.3)) { ringScale = 1.9 }
            withAnimation(.easeIn(duration: 0.15)) { ringOpacity = 0.9 }
        }

        // Flash fades (0.78 + 1.0 = 1.78s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.78) {
            withAnimation(.easeOut(duration: 0.45)) { flashOpacity = 0 }
        }
        // Ring fades (1.05 + 1.0 = 2.05s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.05) {
            withAnimation(.easeOut(duration: 0.45)) { ringOpacity = 0 }
        }

        // Carousel (1.35 + 1.0 = 2.35s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) {
            carouselIndex = 0
            flippedCards = []
            withAnimation(.spring(response: 0.5)) { phase = .carousel }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
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
                    .monospacedDigit()
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
        let isBest = idx == bestCardIndex

        Group {
            if flippedCards.contains(idx) {
                AnimalCardView(animal: animal, size: .large)
                    .overlay {
                        if isBest {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(colors: [.yellow, .orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2.5
                                )
                        }
                    }
                    .shadow(color: isBest ? .yellow.opacity(0.7) : .clear, radius: isBest ? 20 : 0)
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
                            .offset(y: 72)
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

    private var bestCardIndex: Int { cards.isEmpty ? 0 : cards.count - 1 }

    // MARK: - Summary

    private var summaryView: some View {
        VStack(spacing: 0) {
            Text("¡Sobre Abierto!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 24)

            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ForEach(0..<min(3, cards.count), id: \.self) { idx in
                            summaryCardCell(idx: idx)
                        }
                    }
                    .padding(.horizontal, 20)

                    if cards.count > 3 {
                        HStack(spacing: 12) {
                            Spacer(minLength: 0)
                            ForEach(3..<cards.count, id: \.self) { idx in
                                summaryCardCell(idx: idx)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 20)
                    }

                    let dupCount = cards.filter { card in
                        vm.collection.first(where: { $0.id == card.id })?.duplicateCount ?? 0 > 0
                    }.count
                    if dupCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.2.squarepath")
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(dupCount) duplicado\(dupCount > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
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
        AnimalCardView(animal: cards[idx], size: .small)
            .overlay {
                if isBest {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(colors: [.yellow, .orange, .yellow],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                }
            }
            .shadow(color: isBest ? .yellow.opacity(0.55) : .clear, radius: isBest ? 14 : 0)
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

// MARK: - Pack Sprite (fallback when no custom image)

struct PackSpriteView: View {
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
                .fill(PackType.basic.gradient.opacity(0.2))
                .frame(width: 160, height: 220)

            VStack(spacing: 12) {
                Text("📦")
                    .font(.system(size: 64))
                Text("SOBRE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(3)
                Text("\(PackType.basic.cardsPerPack) cartas")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }

            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(PackType.basic.gradient, lineWidth: 2)
                .frame(width: 160, height: 220)
        }
        .shadow(color: PackType.basic.gradientColors[0].opacity(0.5), radius: 20)
    }
}
