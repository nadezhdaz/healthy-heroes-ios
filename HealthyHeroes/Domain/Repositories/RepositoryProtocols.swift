import Foundation

protocol ProfileRepository {
    func loadProfile() throws -> ChildProfile?
    func saveProfile(_ profile: ChildProfile) throws
}

protocol FoodLogRepository {
    func fetchEntries() throws -> [FoodLogEntry]
    func addEntry(_ entry: FoodLogEntry) throws
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
