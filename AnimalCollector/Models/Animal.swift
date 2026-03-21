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

    // Mutable state (saved to disk, absent in animals.json)
    var obtainedDate: Date?
    var duplicateCount: Int = 0
    var isFavorite: Bool = false

    var isObtained: Bool { obtainedDate != nil }

    static func == (lhs: Animal, rhs: Animal) -> Bool { lhs.id == rhs.id }

    // Custom decode so mutable fields are optional —
    // animals.json doesn't have them; persistence saves do.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(String.self,   forKey: .id)
        name             = try c.decode(String.self,   forKey: .name)
        scientificName   = try c.decode(String.self,   forKey: .scientificName)
        category         = try c.decode(Category.self, forKey: .category)
        rarity           = try c.decode(Rarity.self,   forKey: .rarity)
        description      = try c.decode(String.self,   forKey: .description)
        funFact          = try c.decode(String.self,   forKey: .funFact)
        emoji            = try c.decode(String.self,   forKey: .emoji)
        collectionNumber = try c.decode(Int.self,      forKey: .collectionNumber)
        obtainedDate     = try c.decodeIfPresent(Date.self, forKey: .obtainedDate)
        duplicateCount   = try c.decodeIfPresent(Int.self,  forKey: .duplicateCount) ?? 0
        isFavorite       = try c.decodeIfPresent(Bool.self, forKey: .isFavorite)     ?? false
    }
}
