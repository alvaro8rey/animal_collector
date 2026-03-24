import Foundation

enum GachaEngine {

    /// Draw `count` animals for a pack opening.
    /// - Last card is always elevated (Rare+).
    /// - Pity: after 10 packs without Epic+, second-to-last card is guaranteed Epic+.
    /// - `obtainedIds`: animals the player already has; biases draws toward duplicates.
    /// - Same animal won't repeat within a single pack (unless unavoidable).
    static func drawCards(
        count: Int,
        packType: PackType,
        allAnimals: [Animal],
        pityCount: Int,
        obtainedIds: Set<String> = []
    ) -> [Animal] {
        var result: [Animal] = []
        var drawnIds: Set<String> = []   // avoid same card twice in one pack
        let pityActive = pityCount >= 20

        for index in 0..<count {
            let isLastCard  = index == count - 1
            let isPityCard  = pityActive && index == count - 2

            let animal: Animal
            if isLastCard {
                animal = draw(from: allAnimals,
                              weights: packType.lastCardWeights,
                              obtainedIds: obtainedIds,
                              excludedIds: drawnIds)
            } else if isPityCard {
                // Guaranteed Epic+; try to avoid same-pack duplicates
                let pool = filteredPool(allAnimals.filter { $0.rarity >= .epic }, excluding: drawnIds)
                animal = pool.randomElement()
                    ?? draw(from: allAnimals,
                            weights: packType.standardWeights,
                            obtainedIds: obtainedIds,
                            excludedIds: drawnIds)
            } else {
                animal = draw(from: allAnimals,
                              weights: packType.standardWeights,
                              obtainedIds: obtainedIds,
                              excludedIds: drawnIds)
            }
            result.append(animal)
            drawnIds.insert(animal.id)
        }
        // Secret injection: 0.3 % chance per pack to replace one card
        let secretPool = allAnimals.filter { $0.rarity == .secret }
        if !secretPool.isEmpty, Double.random(in: 0..<1) < 0.003 {
            let replaceIdx = Int.random(in: 0..<result.count)
            result[replaceIdx] = secretPool.randomElement()!
        }

        return result
    }

    // MARK: - Private helpers

    /// Pick a rarity then a candidate, biased toward already-obtained animals.
    /// 80 % chance of duplicate when the player owns at least one animal of that rarity.
    private static func draw(
        from animals: [Animal],
        weights: [Rarity: Int],
        obtainedIds: Set<String>,
        excludedIds: Set<String>
    ) -> Animal {
        let rarity = weightedRarity(weights)

        // Prefer animals not already drawn this pack
        var candidates = filteredPool(animals.filter { $0.rarity == rarity }, excluding: excludedIds)
        if candidates.isEmpty {
            // All of this rarity already drawn this pack — fallback to full rarity pool
            candidates = animals.filter { $0.rarity == rarity }
        }
        if candidates.isEmpty { candidates = animals }

        let obtained = candidates.filter {  obtainedIds.contains($0.id) }
        let newOnes  = candidates.filter { !obtainedIds.contains($0.id) }

        // Bias toward duplicates based on:
        //   - Per-rarity ownership (how much of this rarity the player owns)
        //   - Global collection completion (the more cards overall, the harder to get new ones)
        // Formula: rarityBias + globalCompletion × (1 - rarityBias)
        // E.g. 55% global + 50% rarity → 77.5% duplicate chance.
        if !obtained.isEmpty && !newOnes.isEmpty {
            let rarityBias = Double(obtained.count) / Double(obtained.count + newOnes.count)
            let globalCompletion = Double(obtainedIds.count) / Double(max(animals.count, 1))
            let duplicateBias = rarityBias + globalCompletion * (1.0 - rarityBias)
            return Double.random(in: 0..<1) < duplicateBias
                ? obtained.randomElement()!
                : newOnes.randomElement()!
        }

        return candidates.randomElement()!
    }

    /// Remove already-drawn-this-pack animals from a pool; returns the full pool if it would be empty.
    private static func filteredPool(_ pool: [Animal], excluding ids: Set<String>) -> [Animal] {
        let filtered = pool.filter { !ids.contains($0.id) }
        return filtered.isEmpty ? pool : filtered
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
