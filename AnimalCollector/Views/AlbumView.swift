import SwiftUI

// MARK: - Album View

struct AlbumView: View {
    @EnvironmentObject var vm: GameViewModel
    @Binding var selectedAnimal: Animal?

    @State private var currentPage: Int = 0
    @State private var flipAngle: Double = 0
    @State private var flipAnchor: UnitPoint = .leading
    @State private var isAnimating: Bool = false

    private let cardsPerPage = 9  // 3 cols × 3 rows

    private var sortedAnimals: [Animal] {
        vm.collection
            .filter { $0.category != .secret || $0.isObtained }
            .sorted { $0.collectionNumber < $1.collectionNumber }
    }

    private var totalPages: Int {
        max(1, Int(ceil(Double(sortedAnimals.count) / Double(cardsPerPage))))
    }

    private func pageSlots(for page: Int) -> [Animal?] {
        let start = page * cardsPerPage
        return (0..<cardsPerPage).map { i in
            let idx = start + i
            return idx < sortedAnimals.count ? sortedAnimals[idx] : nil
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Album page with 3-D flip
            AlbumPageView(slots: pageSlots(for: currentPage), selectedAnimal: $selectedAnimal)
                .rotation3DEffect(
                    .degrees(flipAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: flipAnchor,
                    perspective: 0.35
                )
                .shadow(color: .black.opacity(0.60), radius: 20, x: 4, y: 10)
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { value in
                            if value.translation.width < 0 { flipForward() }
                            else { flipBackward() }
                        }
                )

            // Navigation bar
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

    // MARK: - Flip helpers

    private func flipForward() {
        guard currentPage < totalPages - 1, !isAnimating else { return }
        flipAnchor = .leading
        // Right edge swings away from viewer → negative angle with leading anchor
        animateFlip(exitAngle: -90, enterAngle: 90) { currentPage += 1 }
    }

    private func flipBackward() {
        guard currentPage > 0, !isAnimating else { return }
        flipAnchor = .trailing
        // Left edge swings away from viewer → positive angle with trailing anchor
        animateFlip(exitAngle: 90, enterAngle: -90) { currentPage -= 1 }
    }

    private func animateFlip(exitAngle: Double, enterAngle: Double, change: @escaping () -> Void) {
        isAnimating = true
        withAnimation(.easeIn(duration: 0.18)) { flipAngle = exitAngle }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.19) {
            change()
            flipAngle = enterAngle
            withAnimation(.easeOut(duration: 0.18)) { flipAngle = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { isAnimating = false }
        }
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

            // Spine shadow (left edge — simulates book binding)
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.22), Color.black.opacity(0.06), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 32)
                Spacer()
            }

            // Subtle page-curl shadow (right edge)
            HStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.07)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var pageHeader: some View {
        VStack(spacing: 5) {
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
    }

    private var pageFooter: some View {
        HStack {
            decorativeLine
        }
        .padding(.horizontal, 14)
    }

    private var decorativeLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear,
                             Color(red: 0.70, green: 0.52, blue: 0.25).opacity(0.55),
                             Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
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
                // Slot tray background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.82, green: 0.76, blue: 0.63).opacity(0.55))

                if let animal {
                    if animal.isObtained {
                        // Obtained: show full card
                        AnimalCardView(animal: animal, isRevealed: true, size: .small)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        // Not obtained: blurred mystery silhouette + slot number
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

                // Dashed border for unfilled slots
                if !isObtained {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            Color(red: 0.54, green: 0.40, blue: 0.22).opacity(0.40),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                        )
                }
            }
            .frame(width: 100, height: 160)
            .shadow(color: .black.opacity(isObtained ? 0.18 : 0.08), radius: isObtained ? 4 : 2, x: 1, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isObtained)
    }
}
