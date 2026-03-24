import SwiftUI
import Kingfisher

private let r2BaseURL = "https://pub-7042a31e227d46569e518a96fcc9951a.r2.dev"

struct AnimalRemoteImage: View {
    let animalId: String
    let emoji: String
    let glowColor: Color
    let glowRadius: CGFloat

    @State private var loadFailed = false

    var body: some View {
        if loadFailed {
            EmojiFallback(emoji: emoji, glowColor: glowColor, glowRadius: glowRadius)
        } else {
            KFImage(URL(string: "\(r2BaseURL)/\(animalId).webp"))
                .placeholder { ShimmerPlaceholder(color: glowColor) }
                .onFailure { _ in loadFailed = true }
                .resizable()
                .scaledToFill()
                .shadow(color: glowColor.opacity(0.5), radius: glowRadius)
        }
    }
}

/// Shown while the image is downloading.
private struct ShimmerPlaceholder: View {
    let color: Color
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(
                stops: [
                    .init(color: color.opacity(0.07), location: 0),
                    .init(color: color.opacity(0.18), location: 0.4),
                    .init(color: color.opacity(0.07), location: 1),
                ],
                startPoint: UnitPoint(x: phase, y: 0),
                endPoint: UnitPoint(x: phase + 1, y: 1)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
        .background(color.opacity(0.07))
    }
}

/// Shown when the image fails to load (missing or unavailable).
private struct EmojiFallback: View {
    let emoji: String
    let glowColor: Color
    let glowRadius: CGFloat

    var body: some View {
        Text(emoji)
            .font(.system(size: 52))
            .shadow(color: glowColor.opacity(0.6), radius: glowRadius)
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

    private let rainbow: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red]

    var body: some View {
        ZStack {
            if animal.rarity == .secret {
                secretCard
            } else {
                normalCard
            }

            if !animal.isObtained && !isRevealed {
                RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.7))
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white.opacity(0.4))
                    .font(.title2)
            }
        }
        .frame(width: size.width, height: size.height)
        .shadow(
            color: size == .small
                ? .clear
                : animal.rarity == .secret
                    ? Color(red: 0.7, green: 0.1, blue: 1.0).opacity(size == .large ? 0.8 : 0.45)
                    : animal.rarity.glowColor.opacity(size == .large ? 0.4 : 0.2),
            radius: size == .large ? animal.rarity.glowRadius : animal.rarity.glowRadius * 0.4
        )
    }

    // MARK: - Normal card

    @ViewBuilder
    private var normalCard: some View {
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
    private var secretCard: some View {
        // 1. Dark base
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(red: 0.04, green: 0.01, blue: 0.12))

        // 2. Iridescent color wash — slow hue rotation
        let washOpacity: Double = size == .small ? 0.28 : size == .medium ? 0.40 : 0.55
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [
                        Color(hue: (t * 0.04).truncatingRemainder(dividingBy: 1),
                              saturation: 0.9, brightness: 0.6).opacity(washOpacity),
                        Color(hue: ((t * 0.04) + 0.33).truncatingRemainder(dividingBy: 1),
                              saturation: 0.9, brightness: 0.5).opacity(washOpacity * 0.82),
                        Color(hue: ((t * 0.04) + 0.66).truncatingRemainder(dividingBy: 1),
                              saturation: 0.9, brightness: 0.4).opacity(washOpacity * 0.91),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        }

        // 3. Content on top of color wash
        cardContent

        // 4. Holographic sweep — a wide bright band crossing the card
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let pos = CGFloat((t * 0.4).truncatingRemainder(dividingBy: 2.5)) - 0.5
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.08), .white.opacity(0.38), .white.opacity(0.08), .clear],
                    startPoint: UnitPoint(x: pos, y: 0),
                    endPoint: UnitPoint(x: pos + 0.55, y: 1)
                ))
        }

        // 5. Second sweep at different angle and speed
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let pos = CGFloat((t * 0.25 + 1.2).truncatingRemainder(dividingBy: 2.5)) - 0.5
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.0), .white.opacity(0.18), .clear],
                    startPoint: UnitPoint(x: pos + 0.4, y: 0),
                    endPoint: UnitPoint(x: pos, y: 1)
                ))
        }

        // 6. Glint flashes — bright dots that flicker at fixed positions
        GlintView()

        // 7. Animated rainbow border
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    AngularGradient(
                        colors: rainbow,
                        center: .center,
                        startAngle: .degrees(t * 40),
                        endAngle: .degrees(t * 40 + 360)
                    ),
                    lineWidth: 2.5
                )
        }
    }

    // MARK: - Card content

    private var cardContent: some View {
        VStack(spacing: 6) {
            HStack {
                Text(animal.rarity == .secret ? "✦ ✦ ✦" : "#\(String(format: "%03d", animal.collectionNumber))")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
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

// MARK: - Glint flashes

/// Small bright spots that flicker at fixed positions, like light catching facets of a gem.
struct GlintView: View {
    private let spots: [(x: CGFloat, y: CGFloat, speed: Double, phase: Double)] = [
        (0.15, 0.12, 1.7, 0.0),
        (0.85, 0.20, 2.1, 1.3),
        (0.25, 0.78, 1.4, 2.6),
        (0.78, 0.72, 1.9, 0.8),
        (0.50, 0.45, 1.5, 1.9),
    ]

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack {
                    ForEach(spots.indices, id: \.self) { i in
                        let s = spots[i]
                        let pulse = (sin(t * s.speed + s.phase) + 1) / 2  // 0…1
                        let bright = pulse * pulse  // sharper peak
                        let size = 2.0 + 7.0 * bright
                        let x = s.x * geo.size.width
                        let y = s.y * geo.size.height

                        ZStack {
                            // Soft halo
                            Circle()
                                .fill(RadialGradient(
                                    colors: [.white.opacity(bright * 0.5), .clear],
                                    center: .center, startRadius: 0, endRadius: size * 2.5
                                ))
                                .frame(width: size * 5, height: size * 5)

                            // Bright core
                            Circle()
                                .fill(.white.opacity(bright * 0.95))
                                .frame(width: size * 0.8, height: size * 0.8)

                            // Horizontal flare
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [.clear, .white.opacity(bright * 0.7), .clear],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: size * 4, height: 1.2)

                            // Vertical flare
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [.clear, .white.opacity(bright * 0.7), .clear],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .frame(width: 1.2, height: size * 4)
                        }
                        .position(x: x, y: y)
                    }
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
                .fill(LinearGradient(
                    colors: [Color(white: 0.1), Color(white: 0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            RoundedRectangle(cornerRadius: 12)
                .fill(packType.gradient.opacity(0.15))

            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { _ in
                            Text("🐾").font(.system(size: 14)).opacity(0.12)
                        }
                    }
                }
            }

            VStack {
                Text(packType.emoji).font(.system(size: 48))
                Text("Animal Collector")
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
