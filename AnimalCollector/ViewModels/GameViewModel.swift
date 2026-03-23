import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published state

    @Published var collection: [Animal] = []
    @Published var availablePacks: Int = 5
    @Published var isPremium: Bool = false

    // MARK: - StoreKit

    let store = StoreKitManager()
    private var cancellables = Set<AnyCancellable>()
    @Published var streak: Int = 0
    @Published var pityCount: Int = 0
    @Published var totalPacksOpened: Int = 0
    @Published var isDailyAvailable: Bool = true

    // Daily missions
    @Published var todayMissions: [DailyMission] = DailyMission.todaysMissions()
    @Published var claimedMissionIds: Set<String> = []
    @Published var packsOpenedToday: Int = 0
    @Published var gotRareToday: Bool = false
    @Published var gotEpicToday: Bool = false
    @Published var gotDuplicateToday: Bool = false
    @Published var newAnimalsToday: Int = 0

    // MARK: - Dependencies

    private let persistence = PersistenceService.shared
    let allAnimals = AnimalData.all

    // MARK: - Init

    init() {
        load()
        // StoreKit es la fuente de verdad para isPremium.
        // La persistencia es solo un caché para el arranque rápido.
        store.$isPremium
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.isPremium = newValue
                self?.persistence.isPremium = newValue
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed

    // Secret animals are hidden from all public-facing counts.
    var obtainedCount: Int { collection.filter { $0.isObtained && $0.category != .secret }.count }

    // MARK: - Mission helpers

    func isMissionCompleted(_ mission: DailyMission) -> Bool {
        switch mission.condition {
        case .claimDailyReward:   return !isDailyAvailable
        case .openPacksToday1:    return packsOpenedToday >= 1
        case .openPacksToday3:    return packsOpenedToday >= 3
        case .openPacksToday5:    return packsOpenedToday >= 5
        case .newAnimalToday1:    return newAnimalsToday >= 1
        case .newAnimalToday3:    return newAnimalsToday >= 3
        case .getRareToday:       return gotRareToday
        case .getEpicToday:       return gotEpicToday
        case .getDuplicateToday:  return gotDuplicateToday
        case .haveAnimals10:      return obtainedCount >= 10
        case .haveAnimals25:      return obtainedCount >= 25
        case .haveAnimals50:      return obtainedCount >= 50
        case .haveAnimals100:     return obtainedCount >= 100
        case .complete10pct:      return collectionProgress >= 0.10
        case .allCategories:
            let obtainedCategories = Set(collection.filter(\.isObtained).map(\.category))
            return Category.allCases.allSatisfy { obtainedCategories.contains($0) }
        case .haveFavorites3:     return collection.filter(\.isFavorite).count >= 3
        case .haveDuplicates10:   return collection.map(\.duplicateCount).reduce(0, +) >= 10
        case .haveStreak3:        return streak >= 3
        case .haveStreak7:        return streak >= 7
        }
    }

    func isMissionClaimed(_ mission: DailyMission) -> Bool {
        claimedMissionIds.contains(mission.id)
    }

    func claimMission(_ mission: DailyMission) {
        guard isMissionCompleted(mission) && !isMissionClaimed(mission) else { return }
        availablePacks += mission.rewardPacks
        claimedMissionIds.insert(mission.id)
        persistence.claimedMissionIds = claimedMissionIds
        save()
    }

    var collectionProgress: Double {
        let total = allAnimals.filter { $0.category != .secret }.count
        return total == 0 ? 0 : Double(obtainedCount) / Double(total)
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

        let obtainedIds = Set(collection.filter { $0.isObtained }.map { $0.id })
        let drawn = GachaEngine.drawCards(
            count: type.cardsPerPack,
            packType: type,
            allAnimals: allAnimals,
            pityCount: pityCount,
            obtainedIds: obtainedIds
        )

        let hasEpicPlus = drawn.contains { $0.rarity >= .epic }
        pityCount = hasEpicPlus ? 0 : pityCount + 1
        totalPacksOpened += 1

        // Daily mission tracking
        packsOpenedToday += 1
        persistence.packsOpenedToday = packsOpenedToday

        for animal in drawn {
            let wasDuplicate = collection.first(where: { $0.id == animal.id })?.isObtained == true
            receiveAnimal(animal)
            if wasDuplicate {
                if !gotDuplicateToday {
                    gotDuplicateToday = true
                    persistence.gotDuplicateToday = true
                }
            } else {
                newAnimalsToday += 1
                persistence.newAnimalsToday = newAnimalsToday
            }
        }

        if !gotRareToday && drawn.contains(where: { $0.rarity >= .rare }) {
            gotRareToday = true
            persistence.gotRareToday = true
        }
        if !gotEpicToday && drawn.contains(where: { $0.rarity >= .epic }) {
            gotEpicToday = true
            persistence.gotEpicToday = true
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

    /// Lanza el flujo de compra de StoreKit. Lanza error si falla.
    func purchase() async throws {
        try await store.purchase()
    }

    /// Restaura compras previas consultando el servidor de Apple.
    func restorePurchases() async {
        await store.restorePurchases()
    }

    // MARK: - Persistence

    private func load() {
        if let saved = persistence.loadCollection() {
            // Start from fresh JSON data so static fields (e.g. wikipediaURL) are always current,
            // then overlay mutable state (obtainedDate, duplicateCount, isFavorite) from saved data.
            collection = allAnimals.map { base in
                guard let saved = saved.first(where: { $0.id == base.id }) else { return base }
                var updated = base
                updated.obtainedDate   = saved.obtainedDate
                updated.duplicateCount = saved.duplicateCount
                updated.isFavorite     = saved.isFavorite
                return updated
            }
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

        // Daily missions
        claimedMissionIds = persistence.claimedMissionIds
        packsOpenedToday  = persistence.packsOpenedToday
        gotRareToday      = persistence.gotRareToday
        gotEpicToday      = persistence.gotEpicToday
        gotDuplicateToday = persistence.gotDuplicateToday
        newAnimalsToday   = persistence.newAnimalsToday
    }

    private func save() {
        persistence.saveCollection(collection)
        persistence.availablePacks = availablePacks
        persistence.isPremium = isPremium
        persistence.pityCount = pityCount
        persistence.totalPacksOpened = totalPacksOpened
    }
}
