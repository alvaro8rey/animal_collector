import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject var vm: GameViewModel
    let animal: Animal
    @Environment(\.dismiss) private var dismiss

    @State private var appear = false
    @State private var cardScale: CGFloat = 0.85
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    animal.rarity.gradientColors[0].opacity(0.15),
                    Color(white: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Card art
                    cardArt

                    // Info block
                    infoBlock

                    // Fun fact
                    funFactBlock

                    // Stats row
                    statsRow

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.4))
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                cardScale = 1.0
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }

    // MARK: - Card Art

    private var cardArt: some View {
        ZStack {
            // Glow rings for high rarity
            if animal.rarity >= .epic {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            animal.rarity.glowColor.opacity(glowPulse ? 0.3 - Double(i) * 0.08 : 0.1 - Double(i) * 0.03),
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(180 + i * 40))
                }
            }

            // Large card
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.13), Color(white: 0.07)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: animal.rarity.gradientColors.map { $0.opacity(0.12) },
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    if UIImage(named: animal.id) != nil {
                        Image(animal.id)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: animal.rarity.glowColor.opacity(glowPulse ? 0.8 : 0.4),
                                    radius: glowPulse ? 24 : 14)
                    } else {
                        Text(animal.emoji)
                            .font(.system(size: 100))
                            .shadow(color: animal.rarity.glowColor.opacity(glowPulse ? 0.8 : 0.4),
                                    radius: glowPulse ? 24 : 14)
                    }

                    RarityBadgeView(rarity: animal.rarity)

                    Text(animal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding(32)

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(animal.rarity.borderGradient, lineWidth: animal.rarity.borderWidth + 1)
            }
            .frame(width: 240, height: 320)
            .scaleEffect(cardScale)
            .shadow(color: animal.rarity.glowColor.opacity(glowPulse ? 0.5 : 0.3),
                    radius: glowPulse ? animal.rarity.glowRadius : animal.rarity.glowRadius * 0.6)
        }
        .frame(height: 340)
    }

    // MARK: - Info Block

    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(animal.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(animal.scientificName)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()

                // Favorite button
                Button {
                    vm.toggleFavorite(animal)
                } label: {
                    let isFav = vm.collection.first(where: { $0.id == animal.id })?.isFavorite ?? false
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(isFav ? .red : .white.opacity(0.35))
                        .scaleEffect(isFav ? 1.1 : 1.0)
                        .animation(.spring(response: 0.25), value: isFav)
                }
            }

            // Category + collection number
            HStack(spacing: 10) {
                Label(animal.category.rawValue, systemImage: "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(animal.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(animal.category.color.opacity(0.15)))

                Text(animal.category.icon)
                    .font(.caption)

                Spacer()

                Text("#\(String(format: "%03d", animal.collectionNumber))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.3))
                    .monospacedDigit()
            }

            Divider().overlay(Color.white.opacity(0.08))

            Text(animal.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Fun Fact

    private var funFactBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("💡")
                .font(.title3)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("DATO CURIOSO")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow.opacity(0.7))
                    .tracking(1.5)

                Text(animal.funFact)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.yellow.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.yellow.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        let collectionAnimal = vm.collection.first(where: { $0.id == animal.id })
        let obtained = collectionAnimal?.isObtained ?? false
        let dupCount = collectionAnimal?.duplicateCount ?? 0
        let date = collectionAnimal?.obtainedDate

        return HStack(spacing: 0) {
            StatCell(
                icon: obtained ? "checkmark.circle.fill" : "circle",
                label: "Estado",
                value: obtained ? "Obtenida" : "No obtenida",
                color: obtained ? .green : .white.opacity(0.35)
            )

            Divider().frame(height: 40).overlay(Color.white.opacity(0.08))

            StatCell(
                icon: "square.on.square.fill",
                label: "Copias extra",
                value: "\(dupCount)",
                color: dupCount > 0 ? .blue : .white.opacity(0.35)
            )

            Divider().frame(height: 40).overlay(Color.white.opacity(0.08))

            StatCell(
                icon: "calendar",
                label: "Obtenida el",
                value: date.map { formatDate($0) } ?? "—",
                color: .white.opacity(0.5)
            )
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}

private struct StatCell: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
