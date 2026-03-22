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

        // Crystal shimmer: multiple light bands crossing the card
        CrystalShimmerView()

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

// MARK: - Crystal Shimmer

/// Simulates light catching a holographic/crystal surface:
/// several thin diagonal highlight bands sweep across at different speeds and angles,
/// plus small fixed-position glint flashes.
private struct CrystalShimmerView: View {

    // Each band: (speed, xOffset, angle, opacity, width)
    private let bands: [(speed: Double, phase: Double, angle: Double, opacity: Double, width: Double)] = [
        (speed: 0.28, phase: 0.0,  angle: 28,  opacity: 0.22, width: 0.18),
        (speed: 0.18, phase: 0.6,  angle: -20, opacity: 0.14, width: 0.10),
        (speed: 0.38, phase: 1.1,  angle: 15,  opacity: 0.18, width: 0.08),
        (speed: 0.12, phase: 0.3,  angle: -35, opacity: 0.10, width: 0.14),
    ]

    // Fixed glint positions (unit coords) and phase offsets
    private let glints: [(x: Double, y: Double, phase: Double)] = [
        (0.18, 0.15, 0.0),
        (0.82, 0.28, 1.3),
        (0.35, 0.75, 0.7),
        (0.72, 0.68, 2.1),
        (0.55, 0.42, 0.4),
    ]

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // --- Sweep bands ---
                for band in bands {
                    let cycle = (t * band.speed + band.phase).truncatingRemainder(dividingBy: 2.4) - 0.7
                    let rad = band.angle * Double.pi / 180
                    let w = band.width * Double(size.width)

                    // band centre in x
                    let cx = cycle * Double(size.width) * 1.3

                    // build a thin diagonal gradient strip
                    var path = Path(CGRect(x: 0, y: 0, width: size.width, height: size.height))

                    // perpendicular to the angle: start/end points of the gradient
                    let dx = cos(rad) * w
                    let dy = sin(rad) * w
                    let mid = CGPoint(x: cx, y: Double(size.height) * 0.5)
                    let start = CGPoint(x: mid.x - dx, y: mid.y - dy)
                    let end   = CGPoint(x: mid.x + dx, y: mid.y + dy)

                    context.fill(path, with: .linearGradient(
                        Gradient(stops: [
                            .init(color: .clear,                               location: 0),
                            .init(color: .white.opacity(band.opacity * 0.3),   location: 0.35),
                            .init(color: .white.opacity(band.opacity),          location: 0.5),
                            .init(color: .white.opacity(band.opacity * 0.3),   location: 0.65),
                            .init(color: .clear,                               location: 1),
                        ]),
                        startPoint: start,
                        endPoint: end
                    ))
                }

                // --- Point glints ---
                for glint in glints {
                    let pulse = 0.5 + 0.5 * sin(t * 1.8 + glint.phase)
                    let alpha = pulse * pulse  // sharper flicker
                    let gx = glint.x * Double(size.width)
                    let gy = glint.y * Double(size.height)
                    let r = 3.0 + 4.0 * pulse

                    // Outer soft halo
                    let halo = Path(ellipseIn: CGRect(x: gx - r * 2, y: gy - r * 2, width: r * 4, height: r * 4))
                    context.fill(halo, with: .radialGradient(
                        Gradient(colors: [.white.opacity(alpha * 0.35), .clear]),
                        center: CGPoint(x: gx, y: gy),
                        startRadius: 0, endRadius: r * 2
                    ))

                    // Bright core
                    let core = Path(ellipseIn: CGRect(x: gx - r * 0.4, y: gy - r * 0.4, width: r * 0.8, height: r * 0.8))
                    context.fill(core, with: .color(.white.opacity(alpha * 0.9)))

                    // Cross flare — horizontal
                    let hFlare = Path(CGRect(x: gx - r * 1.8, y: gy - 0.6, width: r * 3.6, height: 1.2))
                    context.fill(hFlare, with: .linearGradient(
                        Gradient(colors: [.clear, .white.opacity(alpha * 0.6), .clear]),
                        startPoint: CGPoint(x: gx - r * 1.8, y: gy),
                        endPoint:   CGPoint(x: gx + r * 1.8, y: gy)
                    ))
                    // Cross flare — vertical
                    let vFlare = Path(CGRect(x: gx - 0.6, y: gy - r * 1.8, width: 1.2, height: r * 3.6))
                    context.fill(vFlare, with: .linearGradient(
                        Gradient(colors: [.clear, .white.opacity(alpha * 0.6), .clear]),
                        startPoint: CGPoint(x: gx, y: gy - r * 1.8),
                        endPoint:   CGPoint(x: gx, y: gy + r * 1.8)
                    ))
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
