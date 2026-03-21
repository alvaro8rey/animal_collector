import SwiftUI

enum Category: String, Codable, CaseIterable {
    case ocean = "Océano"
    case insects = "Insectos"
    case mammals = "Mamíferos"
    case birds = "Aves"
    case reptiles = "Reptiles"
    case amphibians = "Anfibios"
    case extinct = "Extintos"

    var icon: String {
        switch self {
        case .ocean: return "🌊"
        case .insects: return "🦋"
        case .mammals: return "🦁"
        case .birds: return "🦅"
        case .reptiles: return "🦎"
        case .amphibians: return "🐸"
        case .extinct: return "🦴"
        }
    }

    var color: Color {
        switch self {
        case .ocean: return Color(red: 0.1, green: 0.5, blue: 0.95)
        case .insects: return Color(red: 0.2, green: 0.75, blue: 0.3)
        case .mammals: return Color(red: 0.95, green: 0.5, blue: 0.15)
        case .birds: return Color(red: 0.95, green: 0.78, blue: 0.1)
        case .reptiles: return Color(red: 0.1, green: 0.75, blue: 0.6)
        case .amphibians: return Color(red: 0.45, green: 0.88, blue: 0.45)
        case .extinct: return Color(red: 0.65, green: 0.42, blue: 0.22)
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.3), color.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
