import SwiftUI

struct RarityBadgeView: View {
    let rarity: Rarity
    var compact: Bool = false

    var body: some View {
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
                .overlay(
                    Capsule()
                        .strokeBorder(rarity.borderGradient, lineWidth: 0.8)
                )
        )
    }
}
