import Foundation

protocol ProfileRepository {
    func loadProfile() async throws -> ChildProfile?
    func saveProfile(_ profile: ChildProfile) async throws
}

protocol FoodLogRepository {
    func fetchEntries() async throws -> [FoodLogEntry]
    func addEntry(_ entry: FoodLogEntry) async throws
}

/// Persistence boundary for changes that must be committed together.
///
/// Logging food changes both the append-only diary and the aggregate player
/// profile. Keeping this operation on one repository lets Core Data persist
/// both records in a single SQLite transaction.
protocol GameStateRepository: ProfileRepository, FoodLogRepository {
    func commitFoodLog(_ entry: FoodLogEntry, updatedProfile: ChildProfile) async throws
    func commitRewardOpened(_ rewardID: RewardID, updatedProfile: ChildProfile) async throws
}

protocol RewardCatalogRepository {
    func reward(id: RewardID) throws -> Reward?
    func allRewards() throws -> [Reward]
}

protocol GameConfigRepository {
    func progressConfig() throws -> ProgressConfig
    func starterQuests() throws -> [Quest]
    func mapConfig() throws -> MapConfig
}
