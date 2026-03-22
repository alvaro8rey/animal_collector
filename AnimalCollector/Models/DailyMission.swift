import Foundation

// MARK: - Mission Condition

enum MissionCondition: String, CaseIterable {
    // Daily actions (reset each day)
    case claimDailyReward
    case openPacksToday1
    case openPacksToday3
    case openPacksToday5
    case getRareToday
    case getEpicToday
    case getDuplicateToday
    // Collection milestones (claimable every day if met)
    case haveAnimals10
    case haveAnimals25
    case haveAnimals50
    case haveFavorite
    case haveStreak3
}

// MARK: - DailyMission

struct DailyMission: Identifiable {
    let condition: MissionCondition
    let icon: String
    let title: String
    let rewardPacks: Int

    var id: String { condition.rawValue }

    // MARK: - Pool

    static let pool: [DailyMission] = [
        DailyMission(condition: .claimDailyReward,  icon: "gift.fill",                     title: "Reclamar la recompensa diaria",          rewardPacks: 1),
        DailyMission(condition: .openPacksToday1,   icon: "shippingbox.fill",               title: "Abrir 1 sobre hoy",                      rewardPacks: 1),
        DailyMission(condition: .openPacksToday3,   icon: "shippingbox.fill",               title: "Abrir 3 sobres hoy",                     rewardPacks: 1),
        DailyMission(condition: .openPacksToday5,   icon: "shippingbox.fill",               title: "Abrir 5 sobres hoy",                     rewardPacks: 2),
        DailyMission(condition: .getRareToday,      icon: "star.fill",                      title: "Conseguir una carta Rare+ hoy",          rewardPacks: 1),
        DailyMission(condition: .getEpicToday,      icon: "sparkles",                       title: "Conseguir una carta Epic+ hoy",          rewardPacks: 2),
        DailyMission(condition: .getDuplicateToday, icon: "arrow.triangle.2.circlepath",    title: "Obtener un animal duplicado hoy",        rewardPacks: 1),
        DailyMission(condition: .haveAnimals10,     icon: "pawprint.fill",                  title: "Tener 10 animales en la colección",      rewardPacks: 1),
        DailyMission(condition: .haveAnimals25,     icon: "pawprint.fill",                  title: "Tener 25 animales en la colección",      rewardPacks: 1),
        DailyMission(condition: .haveAnimals50,     icon: "pawprint.fill",                  title: "Tener 50 animales en la colección",      rewardPacks: 2),
        DailyMission(condition: .haveFavorite,      icon: "heart.fill",                     title: "Marcar un animal como favorito",         rewardPacks: 1),
        DailyMission(condition: .haveStreak3,       icon: "flame.fill",                     title: "Llevar una racha de 3 días",             rewardPacks: 1),
    ]

    // MARK: - Daily selection

    /// Returns the 3 missions for today, consistent for the entire day.
    static func todaysMissions() -> [DailyMission] {
        let cal = Calendar.current
        let day  = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let year = cal.component(.year, from: Date())
        var rng  = SeededRNG(seed: UInt64(year * 1000 + day))
        return Array(pool.shuffled(using: &rng).prefix(3))
    }
}

// MARK: - Seeded RNG (xorshift64)

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
