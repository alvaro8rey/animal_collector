import SwiftUI

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    private var order: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.order < rhs.order }

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .common: return Color(white: 0.6)
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return Color(red: 1, green: 0.84, blue: 0)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .common: return [Color(white: 0.45), Color(white: 0.28)]
        case .uncommon: return [Color(red: 0.2, green: 0.85, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.45)]
        case .rare: return [Color(red: 0.25, green: 0.5, blue: 1.0), Color(red: 0.35, green: 0.2, blue: 0.9)]
        case .epic: return [Color(red: 0.7, green: 0.2, blue: 1.0), Color(red: 0.95, green: 0.3, blue: 0.6)]
        case .legendary: return [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.5, blue: 0.0)]
        }
    }

    var borderGradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var glowColor: Color { gradientColors[0] }

    var glowRadius: CGFloat {
        switch self {
        case .common: return 0
        case .uncommon: return 6
        case .rare: return 12
        case .epic: return 18
        case .legendary: return 28
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .common: return 1
        case .uncommon: return 1.5
        case .rare: return 2
        case .epic: return 2.5
        case .legendary: return 3
        }
    }

    var weight: Int {
        switch self {
        case .common: return 40
        case .uncommon: return 30
        case .rare: return 20
        case .epic: return 7
        case .legendary: return 3
        }
    }

    var starCount: Int { order + 1 }

    var particleEmoji: String {
        switch self {
        case .common: return ""
        case .uncommon: return "✦"
        case .rare: return "★"
        case .epic: return "✦★"
        case .legendary: return "🌟"
        }
    }
}
