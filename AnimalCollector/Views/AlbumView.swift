import SwiftUI

// MARK: - Album View

struct AlbumView: View {
    @EnvironmentObject var vm: GameViewModel
    @Binding var selectedAnimal: Animal?

    @State private var currentPage: Int = 0
    @State private var flipAngle: Double = 0
    @State private var flipAnchor: UnitPoint = .leading
    @State private var isAnimating: Bool = false
    @State private var flipShadow: Double = 0
    @State private var shadowRadius: CGFloat = 18

    private let cardsPerPage = 9  // 3 × 3

    private var sortedAnimals: [Animal] {
        vm.collection
            .filter { $0.category != .secret || $0.isObtained }
            .sorted { $0.collectionNumber < $1.collectionNumber }
    }

    private var totalPages: Int {
        max(1, Int(ceil(Double(sortedAnimals.count) / Double(cardsPerPage))))
    }

    private var pagesAhead: Int { min(30, totalPages - currentPage - 1) }

    private func pageSlots(for page: Int) -> [Animal?] {
        let start = page * cardsPerPage
        return (0..<cardsPerPage).map { i in
            let idx = start + i
            return idx < sortedAnimals.count ? sortedAnimals[idx] : nil
        }
    }

    var body: some View {
        VStack(spacing: 12) {

            // ── Book: page + right-side paper stack ────────────────
            HStack(alignment: .center, spacing: 0) {

                // Current page (flipping)
                AlbumPageView(slots: pageSlots(for: currentPage), selectedAnimal: $selectedAnimal)
                    .rotation3DEffect(
                        .degrees(flipAngle),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: flipAnchor,
                        perspective: 0.65
                    )
                    // Paper bends inward slightly during the arc
                    .scaleEffect(y: 1.0 - flipShadow * 0.04, anchor: .center)
                    // Page dims as it turns away from the light
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(flipShadow * 0.32))
                            .allowsHitTesting(false)
                    )
                    // Brief warm-tinted "back of page" texture visible near 90°
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.86, green: 0.80, blue: 0.70)
                                    .opacity(flipShadow * 0.55))
                            .allowsHitTesting(false)
                    )
                    .shadow(color: .black.opacity(0.55), radius: shadowRadius, x: 4, y: 8)

                // Remaining pages stack (always visible, right side of book)
                if pagesAhead > 0 {
                    BookEdgeStrip(pageCount: pagesAhead)
                        .frame(width: edgeStripWidth)
                        .padding(.trailing, 4)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, pagesAhead > 0 ? 4 : 16)
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { v in
                        if v.translation.width < 0 { flipForward() }
                        else { flipBackward() }
                    }
            )

            // Navigation
            HStack(spacing: 0) {
                Button(action: flipBackward) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 36)
                        .foregroundStyle(currentPage > 0
                            ? Color(red: 0.92, green: 0.78, blue: 0.50)
                            : Color.white.opacity(0.18))
                }
                .disabled(currentPage == 0 || isAnimating)

                Spacer()

                Text("Pág. \(currentPage + 1) de \(totalPages)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(red: 0.85, green: 0.73, blue: 0.48).opacity(0.85))

                Spacer()

                Button(action: flipForward) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 36)
                        .foregroundStyle(currentPage < totalPages - 1
                            ? Color(red: 0.92, green: 0.78, blue: 0.50)
                            : Color.white.opacity(0.18))
                }
                .disabled(currentPage >= totalPages - 1 || isAnimating)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }

    // Strip width scales with remaining pages, capped at 36 pt
    private var edgeStripWidth: CGFloat {
        min(36, CGFloat(pagesAhead) * 1.1 + 6)
    }

    // MARK: - Flip logic

    private func flipForward() {
        guard currentPage < totalPages - 1, !isAnimating else { return }
        flipAnchor = .leading
        animateFlip(exitAngle: -90, enterAngle: 90) { currentPage += 1 }
    }

    private func flipBackward() {
        guard currentPage > 0, !isAnimating else { return }
        flipAnchor = .trailing
        animateFlip(exitAngle: 90, enterAngle: -90) { currentPage -= 1 }
    }

    /// 3-phase animation:
    ///   Phase 0 — micro-lift  (page edge rises a few degrees, very fast)
    ///   Phase 1 — main flip   (easeIn rush to 90°, shadow peaks)
    ///   Phase 2 — spring slap (new page swings in and bounces slightly on landing)
    private func animateFlip(exitAngle: Double, enterAngle: Double, change: @escaping () -> Void) {
        isAnimating = true
        let lift: Double = exitAngle > 0 ? -5 : 5   // tiny opposite pre-rotate

        // Phase 0 — lift
        withAnimation(.easeOut(duration: 0.09)) {
            flipAngle    = lift
            shadowRadius = 26
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            // Phase 1 — flip to edge-on (90°)
            withAnimation(.easeIn(duration: 0.24)) {
                flipAngle    = exitAngle
                flipShadow   = 1.0
                shadowRadius = 48
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                change()                  // swap content while page is edge-on
                flipAngle = enterAngle    // jump to mirror angle (instant, invisible)

                // Phase 2 — spring slap-down
                withAnimation(.spring(response: 0.46, dampingFraction: 0.66)) {
                    flipAngle    = 0
                    flipShadow   = 0
                    shadowRadius = 18
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Book Edge Strip

/// Represents the visible right-side paper edges of unread pages.
struct BookEdgeStrip: View {
    let pageCount: Int

    var body: some View {
        Canvas { ctx, size in
            // Paper-stack gradient: darker on the left (spine side), lighter to the right
            let grad = Gradient(colors: [
                Color(red: 0.68, green: 0.60, blue: 0.48),
                Color(red: 0.94, green: 0.90, blue: 0.82),
                Color(red: 0.88, green: 0.83, blue: 0.74),
            ])
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(grad,
                                      startPoint: .zero,
                                      endPoint: CGPoint(x: size.width, y: 0))
            )

            // Individual page-edge lines
            let lines = min(pageCount, Int(size.width / 1.0))
            guard lines > 0 else { return }
            let spacing = size.width / CGFloat(lines)
            for i in 0..<lines {
                let x = CGFloat(i) * spacing + spacing * 0.4
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(p, with: .color(.black.opacity(0.06)), lineWidth: 0.6)
            }
        }
        .overlay(
            // Left-edge shadow to blend with the page
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 6)
            , alignment: .leading
        )
        .shadow(color: .black.opacity(0.35), radius: 5, x: 3, y: 1)
    }
}

// MARK: - Album Page

struct AlbumPageView: View {
    let slots: [Animal?]
    @Binding var selectedAnimal: Animal?

    private let columns = 3
    private let rows    = 3
    private let gap: CGFloat = 8

    var body: some View {
        ZStack {
            // Paper
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.94, blue: 0.88),
                            Color(red: 0.91, green: 0.87, blue: 0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Content
            VStack(spacing: 0) {
                pageHeader.padding(.top, 10)

                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(0..<columns, id: \.self) { col in
                                let idx = row * columns + col
                                AlbumSlot(animal: slots[idx]) {
                                    if let a = slots[idx], a.isObtained {
                                        selectedAnimal = a
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer(minLength: 6)
                pageFooter.padding(.bottom, 10)
            }

            // Golden frame
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.78, green: 0.60, blue: 0.28),
                            Color(red: 0.97, green: 0.86, blue: 0.55),
                            Color(red: 0.78, green: 0.60, blue: 0.28),
                            Color(red: 0.97, green: 0.86, blue: 0.55),
                            Color(red: 0.78, green: 0.60, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )

            // Inset decorative line
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color(red: 0.72, green: 0.56, blue: 0.30).opacity(0.35), lineWidth: 1)
                .padding(6)

            // Spine shadow (left edge)
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.22), Color.black.opacity(0.06), Color.clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 32)
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var pageHeader: some View {
        HStack {
            decorativeLine
            Text("✦  ANIMALES DEL MUNDO  ✦")
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundStyle(Color(red: 0.48, green: 0.34, blue: 0.16))
                .tracking(1.5)
                .fixedSize()
            decorativeLine
        }
        .padding(.horizontal, 14)
    }

    private var pageFooter: some View {
        HStack { decorativeLine }
            .padding(.horizontal, 14)
    }

    private var decorativeLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear,
                             Color(red: 0.70, green: 0.52, blue: 0.25).opacity(0.55),
                             Color.clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Album Slot

struct AlbumSlot: View {
    let animal: Animal?
    let onTap: () -> Void

    private var isObtained: Bool { animal?.isObtained == true }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.82, green: 0.76, blue: 0.63).opacity(0.55))

                if let animal {
                    if animal.isObtained {
                        AnimalCardView(animal: animal, isRevealed: true, size: .small)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        VStack(spacing: 4) {
                            Text(animal.emoji)
                                .font(.system(size: 36))
                                .blur(radius: 7)
                                .opacity(0.25)
                                .saturation(0)
                            Text(String(format: "#%03d", animal.collectionNumber))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.44, green: 0.31, blue: 0.14))
                        }
                    }
                }

                if !isObtained {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            Color(red: 0.54, green: 0.40, blue: 0.22).opacity(0.40),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                        )
                }
            }
            .frame(width: 100, height: 160)
            .shadow(color: .black.opacity(isObtained ? 0.18 : 0.08),
                    radius: isObtained ? 4 : 2, x: 1, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isObtained)
    }
}
