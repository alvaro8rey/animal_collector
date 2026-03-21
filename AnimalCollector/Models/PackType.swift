import SwiftUI

enum PackType: String, CaseIterable, Identifiable {
    case basic = "Básico"
    case daily = "Diario"
    case premium = "Premium"

    var id: String { rawValue }
    var cardsPerPack: Int { 5 }

    var gradientColors: [Color] {
        switch self {
        case .basic: return [Color(red: 0.25, green: 0.5, blue: 1.0), Color(red: 0.35, green: 0.2, blue: 0.9)]
        case .daily: return [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.5)]
        case .premium: return [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.5, blue: 0.0)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var emoji: String {
        switch self {
        case .basic: return "📦"
        case .daily: return "🎁"
        case .premium: return "⭐"
        }
    }

    var description: String {
        switch self {
        case .basic: return "Probabilidades estándar"
        case .daily: return "Recompensa gratuita diaria"
        case .premium: return "Mejores probabilidades de rarezas altas"
        }
    }

    var cost: Int {
        switch self {
        case .basic: return 100
        case .daily: return 0
        case .premium: return 300
        }
    }

    // Weights for the last card (guaranteed elevated rarity)
    var lastCardWeights: [Rarity: Int] {
        switch self {
        case .basic: return [.rare: 55, .epic: 35, .legendary: 10]
        case .daily: return [.uncommon: 40, .rare: 40, .epic: 15, .legendary: 5]
        case .premium: return [.rare: 30, .epic: 45, .legendary: 25]
        }
    }

    // Standard weights for non-last cards
    var standardWeights: [Rarity: Int] {
        switch self {
        case .basic: return [.common: 40, .uncommon: 33, .rare: 20, .epic: 5, .legendary: 2]
        case .daily: return [.common: 45, .uncommon: 35, .rare: 15, .epic: 4, .legendary: 1]
        case .premium: return [.common: 25, .uncommon: 30, .rare: 30, .epic: 12, .legendary: 3]
        }
    }
}
