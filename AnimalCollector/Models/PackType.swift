import SwiftUI

enum PackType: String, CaseIterable, Identifiable {
    case basic = "Básico"
    case daily = "Diario"

    var id: String { rawValue }
    var cardsPerPack: Int { 5 }

    var gradientColors: [Color] {
        switch self {
        case .basic: return [Color(red: 0.25, green: 0.5, blue: 1.0), Color(red: 0.35, green: 0.2, blue: 0.9)]
        case .daily: return [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.5)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var emoji: String {
        switch self {
        case .basic: return "📦"
        case .daily: return "🎁"
        }
    }

    var description: String {
        switch self {
        case .basic: return "Probabilidades estándar"
        case .daily: return "Recompensa gratuita diaria"
        }
    }

    // Weights for the last card (guaranteed elevated rarity)
    var lastCardWeights: [Rarity: Int] {
        switch self {
        case .basic: return [.rare: 90, .epic: 8, .legendary: 2]
        case .daily: return [.uncommon: 62, .rare: 35, .epic: 3, .legendary: 0]
        }
    }

    // Standard weights for non-last cards (out of 1000 for finer control)
    var standardWeights: [Rarity: Int] {
        switch self {
        case .basic: return [.common: 639, .uncommon: 274, .rare: 81, .epic: 5, .legendary: 1]
        case .daily: return [.common: 650, .uncommon: 280, .rare: 70, .epic: 0,  .legendary: 0]
        }
    }
}
