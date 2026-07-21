import Foundation

@MainActor
final class AppDependencyContainer: ObservableObject {
    let router: AppRouter
    let eventBus: AppEventBus
    let assetResolver: AssetResolver

    let gameStateRepository: any GameStateRepository
    let profileRepository: any ProfileRepository
    let foodLogRepository: any FoodLogRepository
    let rewardCatalogRepository: any RewardCatalogRepository
    let gameConfigRepository: any GameConfigRepository

    let createCharacterUseCase: any CreateCharacterUseCase
    let selectStarterClassUseCase: any SelectStarterClassUseCase
    let logFoodUseCase: any LogFoodUseCase
    let equipItemUseCase: any EquipItemUseCase
    let markRewardOpenedUseCase: any MarkRewardOpenedUseCase
    let openMysteryPackUseCase: any OpenMysteryPackUseCase

    init(
        router: AppRouter,
        eventBus: AppEventBus,
        assetResolver: AssetResolver,
        gameStateRepository: any GameStateRepository,
        rewardCatalogRepository: any RewardCatalogRepository,
        gameConfigRepository: any GameConfigRepository
    ) {
        self.router = router
        self.eventBus = eventBus
        self.assetResolver = assetResolver
        self.gameStateRepository = gameStateRepository
        self.profileRepository = gameStateRepository
        self.foodLogRepository = gameStateRepository
        self.rewardCatalogRepository = rewardCatalogRepository
        self.gameConfigRepository = gameConfigRepository

        self.createCharacterUseCase = CreateCharacterUseCaseImpl(
            profileRepository: gameStateRepository,
            gameConfigRepository: gameConfigRepository
        )
        self.selectStarterClassUseCase = SelectStarterClassUseCaseImpl(
            profileRepository: gameStateRepository,
            gameConfigRepository: gameConfigRepository
        )
        self.logFoodUseCase = LogFoodUseCaseImpl(
            gameStateRepository: gameStateRepository,
            gameConfigRepository: gameConfigRepository,
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine()
        )
        self.equipItemUseCase = EquipItemUseCaseImpl(profileRepository: gameStateRepository)
        self.markRewardOpenedUseCase = MarkRewardOpenedUseCaseImpl(
            gameStateRepository: gameStateRepository
        )
        self.openMysteryPackUseCase = OpenMysteryPackUseCaseImpl(
            rewardCatalogRepository: rewardCatalogRepository
        )
    }

    static func live() -> AppDependencyContainer {
#if DEBUG
        let bootstrapStartedAt = ProcessInfo.processInfo.systemUptime
#endif
        let storageDirectory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("HealthyHeroes", isDirectory: true)

        let persistenceController: CoreDataPersistenceController
        do {
            persistenceController = try CoreDataPersistenceController(
                storeURL: storageDirectory.appendingPathComponent("HealthyHeroes.sqlite")
            )
        } catch {
            preconditionFailure("Could not load the Healthy Heroes database: \(error)")
        }

        let rewardCatalogRepository = BundledRewardCatalogRepository()
        let gameConfigRepository = BundledGameConfigRepository()
        let gameStateRepository = CoreDataGameRepository(
            container: persistenceController.container,
            gameConfigRepository: gameConfigRepository,
            rewardCatalogRepository: rewardCatalogRepository
        )
#if DEBUG
        let migrationStartedAt = ProcessInfo.processInfo.systemUptime
#endif
        do {
            try gameStateRepository.migrateLegacyJSONIfNeeded(
                profileURL: storageDirectory.appendingPathComponent("profile.json"),
                foodLogURL: storageDirectory.appendingPathComponent("food_log_entries.json")
            )
        } catch {
            NSLog("Legacy data migration failed: %@", String(describing: type(of: error)))
        }

#if DEBUG
        NSLog(
            "PERF legacy_migration_ms=%.2f",
            (ProcessInfo.processInfo.systemUptime - migrationStartedAt) * 1_000
        )
        NSLog(
            "PERF dependency_bootstrap_ms=%.2f",
            (ProcessInfo.processInfo.systemUptime - bootstrapStartedAt) * 1_000
        )
#endif

        return AppDependencyContainer(
            router: AppRouter(),
            eventBus: AppEventBus(),
            assetResolver: AssetResolver(),
            gameStateRepository: gameStateRepository,
            rewardCatalogRepository: rewardCatalogRepository,
            gameConfigRepository: gameConfigRepository
        )
    }
}
