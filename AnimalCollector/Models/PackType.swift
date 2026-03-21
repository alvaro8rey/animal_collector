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
        case .basic:   return [.rare: 72, .epic: 22, .legendary: 6]
        case .daily:   return [.uncommon: 52, .rare: 38, .epic: 8, .legendary: 2]
        case .premium: return [.rare: 50, .epic: 38, .legendary: 12]
        }
    }

    // Standard weights for non-last cards
    var standardWeights: [Rarity: Int] {
        switch self {
        case .basic:   return [.common: 55, .uncommon: 32, .rare: 10, .epic: 2, .legendary: 1]
        case .daily:   return [.common: 60, .uncommon: 32, .rare: 7,  .epic: 1, .legendary: 0]
        case .premium: return [.common: 35, .uncommon: 35, .rare: 22, .epic: 6, .legendary: 2]
        }
    }
}
