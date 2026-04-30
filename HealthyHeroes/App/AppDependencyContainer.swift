import Foundation

@MainActor
final class AppDependencyContainer: ObservableObject {
    let router: AppRouter
    let eventBus: AppEventBus
    let assetResolver: AssetResolver

    let profileRepository: any ProfileRepository
    let foodLogRepository: any FoodLogRepository
    let rewardCatalogRepository: any RewardCatalogRepository
    let gameConfigRepository: any GameConfigRepository

    let createCharacterUseCase: any CreateCharacterUseCase
    let selectStarterClassUseCase: any SelectStarterClassUseCase
    let logFoodUseCase: any LogFoodUseCase
    let equipItemUseCase: any EquipItemUseCase
    let openMysteryPackUseCase: any OpenMysteryPackUseCase

    init(
        router: AppRouter,
        eventBus: AppEventBus,
        assetResolver: AssetResolver,
        profileRepository: any ProfileRepository,
        foodLogRepository: any FoodLogRepository,
        rewardCatalogRepository: any RewardCatalogRepository,
        gameConfigRepository: any GameConfigRepository
    ) {
        self.router = router
        self.eventBus = eventBus
        self.assetResolver = assetResolver
        self.profileRepository = profileRepository
        self.foodLogRepository = foodLogRepository
        self.rewardCatalogRepository = rewardCatalogRepository
        self.gameConfigRepository = gameConfigRepository

        self.createCharacterUseCase = CreateCharacterUseCaseImpl(
            profileRepository: profileRepository,
            gameConfigRepository: gameConfigRepository
        )
        self.selectStarterClassUseCase = SelectStarterClassUseCaseImpl(
            profileRepository: profileRepository,
            gameConfigRepository: gameConfigRepository
        )
        self.logFoodUseCase = LogFoodUseCaseImpl(
            profileRepository: profileRepository,
            foodLogRepository: foodLogRepository,
            gameConfigRepository: gameConfigRepository,
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine()
        )
        self.equipItemUseCase = EquipItemUseCaseImpl(profileRepository: profileRepository)
        self.openMysteryPackUseCase = OpenMysteryPackUseCaseImpl(
            rewardCatalogRepository: rewardCatalogRepository
        )
    }

    static func live() -> AppDependencyContainer {
        let storageDirectory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("HealthyHeroes", isDirectory: true)

        let profileStore = JSONFileStore<ChildProfile>(
            fileURL: storageDirectory.appendingPathComponent("profile.json")
        )
        let foodLogStore = JSONFileStore<[FoodLogEntry]>(
            fileURL: storageDirectory.appendingPathComponent("food_log_entries.json")
        )

        return AppDependencyContainer(
            router: AppRouter(),
            eventBus: AppEventBus(),
            assetResolver: AssetResolver(),
            profileRepository: LocalProfileRepository(store: profileStore),
            foodLogRepository: LocalFoodLogRepository(store: foodLogStore),
            rewardCatalogRepository: BundledRewardCatalogRepository(),
            gameConfigRepository: BundledGameConfigRepository()
        )
    }
}
