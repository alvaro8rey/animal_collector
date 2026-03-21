import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published state

    @Published var collection: [Animal] = []
    @Published var availablePacks: Int = 5
    @Published var isPremium: Bool = false
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
        return isPremium || availablePacks > 0
    }

    /// Checks if the daily reward is available and, if so, adds +1 pack to the pool.
    func claimDailyIfAvailable() {
        guard isDailyAvailable else { return }
        isDailyAvailable = false
        availablePacks += 1
        persistence.claimDailyAndUpdateStreak()
        streak = persistence.streak
        save()
    }

    // MARK: - Pack opening

    /// Opens a pack, updates state, and returns the drawn cards.
    func openPack(_ type: PackType) -> [Animal] {
        guard canOpen(type) else { return [] }

        if !isPremium { availablePacks -= 1 }

        let drawn = GachaEngine.drawCards(
            count: type.cardsPerPack,
            packType: type,
            allAnimals: allAnimals,
            pityCount: pityCount
        )

        let hasEpicPlus = drawn.contains { $0.rarity >= .epic }
        pityCount = hasEpicPlus ? 0 : pityCount + 1
        totalPacksOpened += 1

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

    /// Called after the user watches an ad. Rewards +2 packs.
    func rewardAdPacks() {
        availablePacks += 2
        save()
    }

    /// Activates premium subscription (stub).
    func activatePremium() {
        isPremium = true
        save()
    }

    /// Cancels premium subscription (stub).
    func cancelPremium() {
        isPremium = false
        save()
    }

    // MARK: - Persistence

    private func load() {
        if let saved = persistence.loadCollection() {
            var merged: [Animal] = saved
            for animal in allAnimals where !merged.contains(where: { $0.id == animal.id }) {
                merged.append(animal)
            }
            collection = merged
        } else {
            collection = allAnimals
        }

        if persistence.isFirstLaunch {
            availablePacks = 5
            persistence.availablePacks = 5
            persistence.isFirstLaunch = false
        } else {
            availablePacks = persistence.availablePacks
        }

        isPremium = persistence.isPremium
        streak = persistence.streak
        pityCount = persistence.pityCount
        totalPacksOpened = persistence.totalPacksOpened
        isDailyAvailable = persistence.isDailyAvailable
    }

    private func save() {
        persistence.saveCollection(collection)
        persistence.availablePacks = availablePacks
        persistence.isPremium = isPremium
        persistence.pityCount = pityCount
        persistence.totalPacksOpened = totalPacksOpened
    }
}
