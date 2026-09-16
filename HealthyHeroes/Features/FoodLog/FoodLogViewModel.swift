import Foundation

@MainActor
final class FoodLogViewModel: ObservableObject {
    @Published private(set) var showsFirstFoodTip = false
    @Published private(set) var foodLogXP: Int?
    private let gameConfigRepository: any GameConfigRepository
    private let profileRepository: (any ProfileRepository)?

    func loadGuidance() async {
        do {
            foodLogXP = try gameConfigRepository.progressConfig().smallFoodLogXP
            let profile = try await profileRepository?.loadProfile()
            showsFirstFoodTip = profile.map { !$0.onboarding.hasCompletedFirstFoodLog } ?? false
        } catch {
            errorMessage = "Could not load your progress. Please try again."
        }
    }

    @Published private(set) var isLogging = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastResult: LogFoodResult?

    let categories: [FoodCategory] = [.fruit, .vegetable, .water, .healthyMeal]

    private let logFoodUseCase: any LogFoodUseCase
    private let eventBus: AppEventBus
    private let router: AppRouter
    private var feedbackDismissalTask: Task<Void, Never>?

    init(
        logFoodUseCase: any LogFoodUseCase,
        eventBus: AppEventBus,
        router: AppRouter,
        profileRepository: (any ProfileRepository)? = nil,
        gameConfigRepository: any GameConfigRepository = BundledGameConfigRepository()
    ) {
        self.profileRepository = profileRepository
        self.gameConfigRepository = gameConfigRepository
        self.logFoodUseCase = logFoodUseCase
        self.eventBus = eventBus
        self.router = router
    }

    @discardableResult
    func log(_ category: FoodCategory) async -> Bool {
        await log(category, customTitle: nil)
    }

    @discardableResult
    func log(_ category: FoodCategory, customTitle: String?) async -> Bool {
        guard !isLogging else { return false }

        feedbackDismissalTask?.cancel()
        lastResult = nil
        errorMessage = nil
        isLogging = true
        defer { isLogging = false }

        do {
            let result = try await logFoodUseCase.log(category: category, customTitle: customTitle)
            lastResult = result
            showsFirstFoodTip = false
            scheduleResultDismissal()

            eventBus.post(.foodLogged(result.foodLogEntry))
            if result.isFirstFoodLog {
                eventBus.post(.firstFoodLogged)
            }
            eventBus.post(.profileUpdated(result.updatedProfile))
            eventBus.post(.firstSessionProgressUpdated(result.updatedProfile.onboarding))

            if !result.completedQuestIDs.isEmpty {
                eventBus.post(.questCompleted(result.completedQuestIDs))
            }
            if !result.unlockedRewardIDs.isEmpty {
                eventBus.post(.rewardsUnlocked(result.unlockedRewardIDs))
                router.present(.mysteryPack(result.unlockedRewardIDs))
            }
            return true
        } catch {
            lastResult = nil
            errorMessage = "Could not log this choice. Please try again."
            return false
        }
    }

    private func scheduleResultDismissal() {
        feedbackDismissalTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.lastResult = nil
        }
    }
}
