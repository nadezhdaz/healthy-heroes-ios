import XCTest
@testable import HealthyHeroes

@MainActor
final class FoodLogViewModelTests: XCTestCase {
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
            bigProgressAwarded: 0
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
