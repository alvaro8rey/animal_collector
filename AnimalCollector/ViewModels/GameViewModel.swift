import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published state

    @Published var collection: [Animal] = []
    @Published var coins: Int = 200
    @Published var basicPacks: Int = 3
    @Published var premiumPacks: Int = 0
    @Published var streak: Int = 0
    @Published var pityCount: Int = 0
    @Published var totalPacksOpened: Int = 0
    @Published var isDailyAvailable: Bool = true

    // MARK: - Dependencies

    private let persistence = PersistenceService.shared
    let allAnimals = AnimalData.all

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Computed

    var obtainedCount: Int { collection.filter(\.isObtained).count }

    var collectionProgress: Double {
        allAnimals.isEmpty ? 0 : Double(obtainedCount) / Double(allAnimals.count)
    }

    func progress(for category: Category) -> (obtained: Int, total: Int) {
        let total = allAnimals.filter { $0.category == category }.count
        let obtained = collection.filter { $0.category == category && $0.isObtained }.count
        return (obtained, total)
    }

    func canOpen(_ type: PackType) -> Bool {
        switch type {
        case .basic: return basicPacks > 0
        case .daily: return isDailyAvailable
        case .premium: return premiumPacks > 0
        }
    }

    /// Coins earned per duplicate
    var duplicateReward: Int { 25 }

    // MARK: - Pack opening

    /// Opens a pack, updates state, and returns the drawn cards.
    func openPack(_ type: PackType) -> [Animal] {
        guard canOpen(type) else { return [] }

        // Deduct resource
        switch type {
        case .basic:
            basicPacks -= 1
        case .daily:
            isDailyAvailable = false
            persistence.claimDailyAndUpdateStreak()
            streak = persistence.streak
        case .premium:
            premiumPacks -= 1
        }

        let drawn = GachaEngine.drawCards(
            count: type.cardsPerPack,
            packType: type,
            allAnimals: allAnimals,
            pityCount: pityCount
        )

        // Update pity counter
        let hasEpicPlus = drawn.contains { $0.rarity >= .epic }
        pityCount = hasEpicPlus ? 0 : pityCount + 1
        totalPacksOpened += 1

        // Process into collection
        for animal in drawn {
            receiveAnimal(animal)
        }

        save()
        return drawn
    }

    private func receiveAnimal(_ animal: Animal) {
        if let idx = collection.firstIndex(where: { $0.id == animal.id }) {
            if collection[idx].isObtained {
                collection[idx].duplicateCount += 1
                coins += duplicateReward
            } else {
                collection[idx].obtainedDate = Date()
            }
        } else {
            var a = animal
            a.obtainedDate = Date()
            collection.append(a)
        }
    }

    // MARK: - User actions

    func toggleFavorite(_ animal: Animal) {
        guard let idx = collection.firstIndex(where: { $0.id == animal.id }) else { return }
        collection[idx].isFavorite.toggle()
        save()
    }

    func buyBasicPack() {
        guard coins >= PackType.basic.cost else { return }
        coins -= PackType.basic.cost
        basicPacks += 1
        save()
    }

    func claimDailyPack() {
        guard isDailyAvailable else { return }
        basicPacks += 1
        isDailyAvailable = false
        persistence.claimDailyAndUpdateStreak()
        streak = persistence.streak
        save()
    }

    // MARK: - Persistence

    private func load() {
        if let saved = persistence.loadCollection() {
            // Merge saved collection with current animal catalog
            var merged: [Animal] = saved
            for animal in allAnimals where !merged.contains(where: { $0.id == animal.id }) {
                merged.append(animal)
            }
            collection = merged
        } else {
            // First launch: populate with all animals (not obtained)
            collection = allAnimals
        }

        if persistence.isFirstLaunch {
            // Default starting resources
            coins = 200
            basicPacks = 3
            persistence.coins = 200
            persistence.basicPacks = 3
            persistence.isFirstLaunch = false
        } else {
            coins = persistence.coins
            basicPacks = persistence.basicPacks
        }

        premiumPacks = persistence.premiumPacks
        streak = persistence.streak
        pityCount = persistence.pityCount
        totalPacksOpened = persistence.totalPacksOpened
        isDailyAvailable = persistence.isDailyAvailable
    }

    private func save() {
        persistence.saveCollection(collection)
        persistence.coins = coins
        persistence.basicPacks = basicPacks
        persistence.premiumPacks = premiumPacks
        persistence.pityCount = pityCount
        persistence.totalPacksOpened = totalPacksOpened
    }
}
