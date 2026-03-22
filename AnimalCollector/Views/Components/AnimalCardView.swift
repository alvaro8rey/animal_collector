import SwiftUI

private let r2BaseURL = "https://pub-7042a31e227d46569e518a96fcc9951a.r2.dev"

struct AnimalRemoteImage: View {
    let animalId: String
    let emoji: String
    let glowColor: Color
    let glowRadius: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: "\(r2BaseURL)/\(animalId).webp")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .shadow(color: glowColor.opacity(0.5), radius: glowRadius)
            default:
                Text(emoji)
                    .font(.system(size: 52))
                    .shadow(color: glowColor.opacity(0.6), radius: glowRadius)
            }
        }
    }
}

struct AnimalCardView: View {
    let animal: Animal
    var isRevealed: Bool = true
    var size: CardSize = .medium

    enum CardSize {
        case small, medium, large
        var width: CGFloat {
            switch self { case .small: return 100; case .medium: return 150; case .large: return 220 }
        }
        var height: CGFloat {
            switch self { case .small: return 160; case .medium: return width * 1.4; case .large: return width * 1.4 }
        }
        var emojiSize: CGFloat {
            switch self { case .small: return 32; case .medium: return 52; case .large: return 80 }
        }
        var nameFont: Font {
            switch self { case .small: return .caption2; case .medium: return .caption; case .large: return .subheadline }
        }
        var imageSize: CGFloat {
            switch self { case .small: return 52; case .medium: return 80; case .large: return 160 }
        }
        var imageCornerRadius: CGFloat {
            switch self { case .small: return 6; case .medium: return 8; case .large: return 12 }
        }
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.12),
                            Color(white: 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Rarity shimmer overlay
            if animal.rarity >= .rare {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: animal.rarity.gradientColors.map { $0.opacity(0.08) } + [.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Content
            VStack(spacing: 6) {
                // Collection number
                HStack {
                    Text("#\(String(format: "%03d", animal.collectionNumber))")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                    Spacer()
                    RarityBadgeView(rarity: animal.rarity, compact: true)
                }

                Spacer()

                // Image from Cloudflare R2 or emoji fallback
                AnimalRemoteImage(animalId: animal.id, emoji: animal.emoji, glowColor: animal.rarity.glowColor, glowRadius: animal.rarity.glowRadius / 2)
                    .frame(width: size.imageSize, height: size.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: size.imageCornerRadius))

                Spacer()

                // Category pill
                Text("\(animal.category.icon) \(animal.category.rawValue)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(animal.category.color.opacity(0.9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(animal.category.color.opacity(0.15))
                    )

                // Name
                Text(animal.name)
                    .font(size.nameFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(10)

            // Border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(animal.rarity.borderGradient, lineWidth: animal.rarity.borderWidth)

            // Not obtained overlay
            if !animal.isObtained && !isRevealed {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white.opacity(0.4))
                    .font(.title2)
            }
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: animal.rarity.glowColor.opacity(0.4), radius: animal.rarity.glowRadius)
    }
}

// MARK: - Card Back View

struct CardBackView: View {
    let packType: PackType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.1), Color(white: 0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 12)
                .fill(packType.gradient.opacity(0.15))

            // Pattern
            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { _ in
                            Text("🐾")
                                .font(.system(size: 14))
                                .opacity(0.12)
                        }
                    }
                }
            }

            VStack {
                Text(packType.emoji)
                    .font(.system(size: 48))
                Text("AnimalCards")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(2)
            }

            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(packType.gradient, lineWidth: 1.5)
        }
        .frame(width: 150, height: 210)
    }
}
