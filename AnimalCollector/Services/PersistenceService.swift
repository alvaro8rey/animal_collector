import Foundation

final class PersistenceService {
    static let shared = PersistenceService()
    private let defaults = UserDefaults.standard

    private enum Key {
        static let collection        = "ac_collection"
        static let availablePacks    = "ac_available_packs"
        static let isPremium         = "ac_is_premium"
        static let streak            = "ac_streak"
        static let lastStreakDate     = "ac_last_streak_date"
        static let pityCount         = "ac_pity_count"
        static let totalPacksOpened  = "ac_total_packs"
        static let dailyClaimedDate  = "ac_daily_claimed"
        static let firstLaunch       = "ac_first_launch"
        // Daily missions
        static let claimedMissionIds = "ac_claimed_mission_ids"
        static let claimedMissionDate = "ac_claimed_mission_date"
        static let packsOpenedTodayCount = "ac_packs_today_count"
        static let packsOpenedTodayDate  = "ac_packs_today_date"
        static let gotRareDateKey    = "ac_got_rare_date"
        static let gotEpicDateKey    = "ac_got_epic_date"
        static let gotDupDateKey     = "ac_got_dup_date"
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

    var availablePacks: Int {
        get { defaults.integer(forKey: Key.availablePacks) }
        set { defaults.set(newValue, forKey: Key.availablePacks) }
    }

    var isPremium: Bool {
        get { defaults.bool(forKey: Key.isPremium) }
        set { defaults.set(newValue, forKey: Key.isPremium) }
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

    // MARK: - Daily Missions

    /// Set of mission IDs claimed today. Automatically resets if date is not today.
    var claimedMissionIds: Set<String> {
        get {
            guard let date = defaults.object(forKey: Key.claimedMissionDate) as? Date,
                  Calendar.current.isDateInToday(date) else { return [] }
            return Set(defaults.stringArray(forKey: Key.claimedMissionIds) ?? [])
        }
        set {
            defaults.set(Array(newValue), forKey: Key.claimedMissionIds)
            defaults.set(Date(), forKey: Key.claimedMissionDate)
        }
    }

    /// Number of packs opened today. Resets on a new day.
    var packsOpenedToday: Int {
        get {
            guard let date = defaults.object(forKey: Key.packsOpenedTodayDate) as? Date,
                  Calendar.current.isDateInToday(date) else { return 0 }
            return defaults.integer(forKey: Key.packsOpenedTodayCount)
        }
        set {
            defaults.set(newValue, forKey: Key.packsOpenedTodayCount)
            defaults.set(Date(), forKey: Key.packsOpenedTodayDate)
        }
    }

    /// Whether a Rare+ card was obtained today.
    var gotRareToday: Bool {
        get {
            guard let date = defaults.object(forKey: Key.gotRareDateKey) as? Date else { return false }
            return Calendar.current.isDateInToday(date)
        }
        set { defaults.set(newValue ? Date() : nil, forKey: Key.gotRareDateKey) }
    }

    /// Whether an Epic+ card was obtained today.
    var gotEpicToday: Bool {
        get {
            guard let date = defaults.object(forKey: Key.gotEpicDateKey) as? Date else { return false }
            return Calendar.current.isDateInToday(date)
        }
        set { defaults.set(newValue ? Date() : nil, forKey: Key.gotEpicDateKey) }
    }

    /// Whether a duplicate was obtained today.
    var gotDuplicateToday: Bool {
        get {
            guard let date = defaults.object(forKey: Key.gotDupDateKey) as? Date else { return false }
            return Calendar.current.isDateInToday(date)
        }
        set { defaults.set(newValue ? Date() : nil, forKey: Key.gotDupDateKey) }
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
        } else {
            streak = 1
        }
        defaults.set(Date(), forKey: Key.lastStreakDate)
    }
}
