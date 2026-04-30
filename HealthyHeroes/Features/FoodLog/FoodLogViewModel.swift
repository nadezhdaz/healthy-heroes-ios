import Foundation

@MainActor
final class FoodLogViewModel: ObservableObject {
    @Published private(set) var isLogging = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastResult: LogFoodResult?

    let categories: [FoodCategory] = [.fruit, .vegetable, .water, .healthyMeal]

    private let logFoodUseCase: any LogFoodUseCase
    private let eventBus: AppEventBus
    private let router: AppRouter

    init(
        logFoodUseCase: any LogFoodUseCase,
        eventBus: AppEventBus,
        router: AppRouter
    ) {
        self.logFoodUseCase = logFoodUseCase
        self.eventBus = eventBus
        self.router = router
    }

    func log(_ category: FoodCategory) {
        log(category, customTitle: nil)
    }

    func log(_ category: FoodCategory, customTitle: String?) {
        guard !isLogging else { return }

        isLogging = true
        defer { isLogging = false }

        do {
            let result = try logFoodUseCase.log(category: category, customTitle: customTitle)
            lastResult = result
            errorMessage = nil

            eventBus.post(.foodLogged(result.foodLogEntry))
            eventBus.post(.profileUpdated(result.updatedProfile))
            eventBus.post(.firstSessionProgressUpdated(result.updatedProfile.onboarding))

            if !result.completedQuestIDs.isEmpty {
                eventBus.post(.questCompleted(result.completedQuestIDs))
            }
            if !result.unlockedRewardIDs.isEmpty {
                eventBus.post(.rewardsUnlocked(result.unlockedRewardIDs))
                router.present(.mysteryPack(result.unlockedRewardIDs))
            }
        } catch {
            errorMessage = "Could not log this choice. Please try again."
        }
    }
}
