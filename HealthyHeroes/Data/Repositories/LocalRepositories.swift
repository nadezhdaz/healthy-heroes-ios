import Foundation

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
