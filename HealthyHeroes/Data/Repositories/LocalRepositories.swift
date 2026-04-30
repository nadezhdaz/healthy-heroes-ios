import Foundation

final class LocalProfileRepository: ProfileRepository {
    private let store: JSONFileStore<ChildProfile>

    init(store: JSONFileStore<ChildProfile>) {
        self.store = store
    }

    func loadProfile() throws -> ChildProfile? {
        try store.load()
    }

    func saveProfile(_ profile: ChildProfile) throws {
        try store.save(profile)
    }
}

final class LocalFoodLogRepository: FoodLogRepository {
    private let store: JSONFileStore<[FoodLogEntry]>

    init(store: JSONFileStore<[FoodLogEntry]>) {
        self.store = store
    }

    func fetchEntries() throws -> [FoodLogEntry] {
        try store.load() ?? []
    }

    func addEntry(_ entry: FoodLogEntry) throws {
        var entries = try fetchEntries()
        entries.append(entry)
        try store.save(entries)
    }
}

final class BundledRewardCatalogRepository: RewardCatalogRepository {
    private let loader: BundledConfigLoader

    init(loader: BundledConfigLoader = BundledConfigLoader()) {
        self.loader = loader
    }

    func reward(id: RewardID) throws -> Reward? {
        try allRewards().first { $0.id == id }
    }

    func allRewards() throws -> [Reward] {
        try loader.decode([Reward].self, fileName: "rewards")
    }
}

final class BundledGameConfigRepository: GameConfigRepository {
    private let loader: BundledConfigLoader

    init(loader: BundledConfigLoader = BundledConfigLoader()) {
        self.loader = loader
    }

    func progressConfig() throws -> ProgressConfig {
        try loader.decode(ProgressConfig.self, fileName: "progress_config")
    }

    func starterQuests() throws -> [Quest] {
        try loader.decode([Quest].self, fileName: "starter_quests")
    }

    func mapConfig() throws -> MapConfig {
        try loader.decode(MapConfig.self, fileName: "map_config")
    }
}
