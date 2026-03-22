import SwiftUI
import Kingfisher

private let r2BaseURL = "https://pub-7042a31e227d46569e518a96fcc9951a.r2.dev"

struct AnimalRemoteImage: View {
    let animalId: String
    let emoji: String
    let glowColor: Color
    let glowRadius: CGFloat

    var body: some View {
        KFImage(URL(string: "\(r2BaseURL)/\(animalId).webp"))
            .placeholder {
                Text(emoji)
                    .font(.system(size: 52))
                    .shadow(color: glowColor.opacity(0.6), radius: glowRadius)
            }
            .resizable()
            .scaledToFill()
            .shadow(color: glowColor.opacity(0.5), radius: glowRadius)
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

    private let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red]

    var body: some View {
        ZStack {
            if animal.rarity == .secret {
                secretCardLayers
            } else {
                normalCardLayers
            }

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
        .shadow(
            color: animal.rarity == .secret
                ? Color(red: 0.75, green: 0.15, blue: 1.0).opacity(0.75)
                : animal.rarity.glowColor.opacity(0.4),
            radius: animal.rarity.glowRadius
        )
    }

    // MARK: - Normal card

    @ViewBuilder
    private var normalCardLayers: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))

        if animal.rarity >= .rare {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: animal.rarity.gradientColors.map { $0.opacity(0.08) } + [.clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        }

        cardContent
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(animal.rarity.borderGradient, lineWidth: animal.rarity.borderWidth)
    }

    // MARK: - Secret card

    @ViewBuilder
    private var secretCardLayers: some View {
        // Deep nebula background
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.02, blue: 0.18),
                    Color(red: 0.03, green: 0.01, blue: 0.10)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))

        // Radial inner glow — brighter center
        RoundedRectangle(cornerRadius: 12)
            .fill(RadialGradient(
                colors: [Color(red: 0.5, green: 0.1, blue: 0.8).opacity(0.18), .clear],
                center: .center, startRadius: 0, endRadius: 80
            ))

        // Rotating prismatic overlay
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            RoundedRectangle(cornerRadius: 12)
                .fill(AngularGradient(
                    colors: rainbowColors.map { $0.opacity(0.09) },
                    center: .center,
                    startAngle: .degrees(t * 22),
                    endAngle: .degrees(t * 22 + 360)
                ))
        }

        cardContent

        // Diagonal shimmer sweep
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let x = (t * 0.3).truncatingRemainder(dividingBy: 2.0) - 0.5
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.18), .white.opacity(0.06), .clear],
                    startPoint: UnitPoint(x: x, y: 0),
                    endPoint: UnitPoint(x: x + 0.7, y: 1)
                ))
        }

        // Orbiting sparkles (medium and large only)
        if size != .small {
            SecretSparklesView(radius: size == .large ? 62 : 44)
        }

        // Animated rainbow border
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    AngularGradient(
                        colors: rainbowColors,
                        center: .center,
                        startAngle: .degrees(t * 40),
                        endAngle: .degrees(t * 40 + 360)
                    ),
                    lineWidth: 2.5
                )
        }
    }

    // MARK: - Shared content

    private var cardContent: some View {
        VStack(spacing: 6) {
            HStack {
                Text(animal.rarity == .secret ? "✦ ✦ ✦" : "#\(String(format: "%03d", animal.collectionNumber))")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()
                RarityBadgeView(rarity: animal.rarity, compact: true)
            }

            Spacer()

            AnimalRemoteImage(
                animalId: animal.id,
                emoji: animal.emoji,
                glowColor: animal.rarity.glowColor,
                glowRadius: animal.rarity.glowRadius / 2
            )
            .frame(width: size.imageSize, height: size.imageSize)
            .clipShape(RoundedRectangle(cornerRadius: size.imageCornerRadius))
            .overlay {
                if animal.rarity == .secret {
                    RoundedRectangle(cornerRadius: size.imageCornerRadius)
                        .strokeBorder(
                            LinearGradient(colors: [.purple.opacity(0.6), .cyan.opacity(0.4)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                }
            }

            Spacer()

            Text("\(animal.category.icon) \(animal.category.rawValue)")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(animal.category.color.opacity(0.9))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule().fill(animal.category.color.opacity(0.15)))

            Text(animal.name)
                .font(size.nameFont)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(10)
    }
}

// MARK: - Secret Sparkles

/// Fixed-radius orbiting particles for the secret card.
/// Each particle orbits at a constant radius and only varies in opacity,
/// so the motion stays perfectly circular.
private struct SecretSparklesView: View {
    let radius: CGFloat
    private let symbols = ["✦", "★", "✧", "✦", "★", "✧"]
    private let count = 6

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let fi = Double(i)
                    let phaseOffset = fi / Double(count)               // evenly spaced
                    let angle = (t * 0.4 + phaseOffset) * .pi * 2     // constant speed
                    let hue = (t * 0.06 + fi * (1.0 / Double(count))).truncatingRemainder(dividingBy: 1)
                    let opacity = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 1.2 + fi * 1.1))

                    Text(symbols[i])
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(
                            Color(hue: hue, saturation: 0.85, brightness: 1.0)
                                .opacity(opacity)
                        )
                        .offset(
                            x: radius * CGFloat(cos(angle)),
                            y: radius * CGFloat(sin(angle))
                        )
                }
            }
        }
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
