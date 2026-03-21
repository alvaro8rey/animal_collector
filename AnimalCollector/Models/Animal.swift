import Foundation

struct Animal: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let scientificName: String
    let category: Category
    let rarity: Rarity
    let description: String
    let funFact: String
    let emoji: String
    let collectionNumber: Int

    // Mutable state (saved to disk)
    var obtainedDate: Date?
    var duplicateCount: Int = 0
    var isFavorite: Bool = false

    var isObtained: Bool { obtainedDate != nil }

    static func == (lhs: Animal, rhs: Animal) -> Bool { lhs.id == rhs.id }
}
