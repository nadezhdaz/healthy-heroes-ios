import XCTest
@testable import HealthyHeroes

@MainActor
final class FoodLogViewModelTests: XCTestCase {
    func testFirstFoodEventUsesCommittedProfileWithoutWaitingForGuidance() async {
        let repository = InMemoryProfileRepository(profile: makeProfile(quests: []))
        let useCase = LogFoodUseCaseImpl(
            gameStateRepository: repository,
            gameConfigRepository: StaticGameConfigRepository(quests: []),
            progressEngine: ProgressEngine(), questEngine: QuestEngine(),
            rewardEngine: RewardEngine(), mapEngine: MapEngine()
        )
        let bus = AppEventBus()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }
        let analytics = AppAnalytics(eventBus: bus, defaults: defaults)
        let viewModel = FoodLogViewModel(logFoodUseCase: useCase, eventBus: bus, router: AppRouter())

        repository.commitError = NSError(domain: "test", code: 1)
        let failed = await viewModel.log(.fruit)
        XCTAssertFalse(failed)
        XCTAssertEqual(analytics.eventNames, ["app_opened"])

        repository.commitError = nil
        let first = await viewModel.log(.fruit)
        let second = await viewModel.log(.water)
        XCTAssertTrue(first && second)
        XCTAssertEqual(analytics.eventNames, ["app_opened", "food_logged", "first_food_logged", "food_logged"])
        XCTAssertEqual(repository.entries.count, 2)
    }

    func testFailureClearsPreviousResultAndShowsError() async {
        let useCase = SequencedLogFoodUseCase(outcomes: [
            .success(makeLogFoodResult()),
            .failure
        ])
        let viewModel = FoodLogViewModel(
            logFoodUseCase: useCase,
            eventBus: AppEventBus(),
            router: AppRouter()
        )

        await viewModel.log(.fruit)
        XCTAssertNotNil(viewModel.lastResult)
        XCTAssertNil(viewModel.errorMessage)

        await viewModel.log(.fruit)
        XCTAssertNil(viewModel.lastResult)
        XCTAssertEqual(viewModel.errorMessage, "Could not log this choice. Please try again.")
    }

    private func makeLogFoodResult() -> LogFoodResult {
        LogFoodResult(
            updatedProfile: makeProfile(),
            foodLogEntry: FoodLogEntry(
                id: "entry",
                category: .fruit,
                customTitle: nil,
                createdAt: Date(timeIntervalSince1970: 100)
            ),
            completedQuestIDs: [],
            unlockedRewardIDs: [],
            didAdvanceOnMap: false,
            smallProgressAwarded: 5,
            bigProgressAwarded: 0,
            isFirstFoodLog: false
        )
    }
}

private final class SequencedLogFoodUseCase: LogFoodUseCase {
    enum Outcome {
        case success(LogFoodResult)
        case failure
    }

    private var outcomes: [Outcome]

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func log(category: FoodCategory, customTitle: String?) async throws -> LogFoodResult {
        guard !outcomes.isEmpty else { throw TestError.noOutcome }

        switch outcomes.removeFirst() {
        case let .success(result):
            return result
        case .failure:
            throw TestError.expectedFailure
        }
    }

    private enum TestError: Error {
        case noOutcome
        case expectedFailure
    }
}
