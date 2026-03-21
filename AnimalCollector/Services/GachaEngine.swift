import Foundation

enum GachaEngine {

    /// Draw `count` animals for a pack opening.
    /// - Last card is always elevated (Rare+).
    /// - Pity: after 10 packs without Epic+, second-to-last card is guaranteed Epic+.
    static func drawCards(
        count: Int,
        packType: PackType,
        allAnimals: [Animal],
        pityCount: Int
    ) -> [Animal] {
        var result: [Animal] = []
        let pityActive = pityCount >= 10

        for index in 0..<count {
            let isLastCard = index == count - 1
            let isPityCard = pityActive && index == count - 2

            let animal: Animal
            if isLastCard {
                animal = draw(from: allAnimals, weights: packType.lastCardWeights)
            } else if isPityCard {
                let epicAnimals = allAnimals.filter { $0.rarity >= .epic }
                animal = epicAnimals.randomElement() ?? draw(from: allAnimals, weights: packType.standardWeights)
            } else {
                animal = draw(from: allAnimals, weights: packType.standardWeights)
            }
            result.append(animal)
        }
        return result
    }

    private static func draw(from animals: [Animal], weights: [Rarity: Int]) -> Animal {
        let rarity = weightedRarity(weights)
        let candidates = animals.filter { $0.rarity == rarity }
        // Fallback to any animal if none match (shouldn't happen with full data)
        return candidates.randomElement() ?? animals.randomElement()!
    }

    private static func weightedRarity(_ weights: [Rarity: Int]) -> Rarity {
        let sorted = Rarity.allCases.compactMap { r -> (Rarity, Int)? in
            guard let w = weights[r] else { return nil }
            return (r, w)
        }
        let total = sorted.map(\.1).reduce(0, +)
        var roll = Int.random(in: 0..<max(total, 1))
        for (rarity, weight) in sorted {
            roll -= weight
            if roll < 0 { return rarity }
        }
        return .common
    }
}
