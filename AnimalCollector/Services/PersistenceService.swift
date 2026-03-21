import Foundation

final class PersistenceService {
    static let shared = PersistenceService()
    private let defaults = UserDefaults.standard

    private enum Key {
        static let collection = "ac_collection"
        static let coins = "ac_coins"
        static let basicPacks = "ac_basic_packs"
        static let premiumPacks = "ac_premium_packs"
        static let streak = "ac_streak"
        static let lastStreakDate = "ac_last_streak_date"
        static let pityCount = "ac_pity_count"
        static let totalPacksOpened = "ac_total_packs"
        static let dailyClaimedDate = "ac_daily_claimed"
        static let firstLaunch = "ac_first_launch"
    }

    // MARK: - Collection

    func saveCollection(_ animals: [Animal]) {
        if let data = try? JSONEncoder().encode(animals) {
            defaults.set(data, forKey: Key.collection)
        }
    }

    func loadCollection() -> [Animal]? {
        guard let data = defaults.data(forKey: Key.collection),
              let animals = try? JSONDecoder().decode([Animal].self, from: data)
        else { return nil }
        return animals
    }

    // MARK: - Simple values

    var coins: Int {
        get { defaults.integer(forKey: Key.coins) }
        set { defaults.set(newValue, forKey: Key.coins) }
    }

    var basicPacks: Int {
        get { defaults.integer(forKey: Key.basicPacks) }
        set { defaults.set(newValue, forKey: Key.basicPacks) }
    }

    var premiumPacks: Int {
        get { defaults.integer(forKey: Key.premiumPacks) }
        set { defaults.set(newValue, forKey: Key.premiumPacks) }
    }

    var streak: Int {
        get { defaults.integer(forKey: Key.streak) }
        set { defaults.set(newValue, forKey: Key.streak) }
    }

    var pityCount: Int {
        get { defaults.integer(forKey: Key.pityCount) }
        set { defaults.set(newValue, forKey: Key.pityCount) }
    }

    var totalPacksOpened: Int {
        get { defaults.integer(forKey: Key.totalPacksOpened) }
        set { defaults.set(newValue, forKey: Key.totalPacksOpened) }
    }

    var isFirstLaunch: Bool {
        get { !defaults.bool(forKey: Key.firstLaunch) }
        set { defaults.set(!newValue, forKey: Key.firstLaunch) }
    }

    // MARK: - Daily

    var dailyClaimedDate: Date? {
        get { defaults.object(forKey: Key.dailyClaimedDate) as? Date }
        set { defaults.set(newValue, forKey: Key.dailyClaimedDate) }
    }

    var isDailyAvailable: Bool {
        guard let last = dailyClaimedDate else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    // MARK: - Streak logic

    func claimDailyAndUpdateStreak() {
        dailyClaimedDate = Date()
        updateStreak()
    }

    private func updateStreak() {
        let lastDate = defaults.object(forKey: Key.lastStreakDate) as? Date
        if let last = lastDate {
            if Calendar.current.isDateInYesterday(last) {
                streak += 1
            } else if !Calendar.current.isDateInToday(last) {
                streak = 1
            }
            // Same day: no change
        } else {
            streak = 1
        }
        defaults.set(Date(), forKey: Key.lastStreakDate)
    }
}
