import SwiftUI

struct RarityBadgeView: View {
    let rarity: Rarity
    var compact: Bool = false

    private let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red]

    var body: some View {
        if rarity == .secret {
            secretBadge
        } else {
            normalBadge
        }
    }

    private var normalBadge: some View {
        HStack(spacing: compact ? 2 : 4) {
            Text(String(repeating: "★", count: rarity.starCount))
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(rarity.borderGradient)

            if !compact {
                Text(rarity.displayName.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(rarity.borderGradient)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 2 : 3)
        .background(
            Capsule()
                .fill(rarity.glowColor.opacity(0.15))
                .overlay(Capsule().strokeBorder(rarity.borderGradient, lineWidth: 0.8))
        )
    }

    private var secretBadge: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let gradient = AngularGradient(
                colors: rainbowColors,
                center: .center,
                startAngle: .degrees(t * 60),
                endAngle: .degrees(t * 60 + 360)
            )
            HStack(spacing: compact ? 2 : 3) {
                Text("✦")
                    .font(compact ? .system(size: 8) : .caption)
                    .foregroundStyle(gradient)
                if !compact {
                    Text("MÍTICO")
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundStyle(gradient)
                    Text("✦")
                        .font(.caption)
                        .foregroundStyle(gradient)
                }
            }
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2 : 3)
            .background(
                Capsule()
                    .fill(Color(red: 0.9, green: 0.3, blue: 1.0).opacity(0.12))
                    .overlay(
                        Capsule().strokeBorder(gradient, lineWidth: 0.8)
                    )
            )
        }
    }
}
