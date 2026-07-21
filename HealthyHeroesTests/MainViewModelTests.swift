import XCTest
@testable import HealthyHeroes

@MainActor
final class MainViewModelTests: XCTestCase {
    func testLoadExposesPersistedClassForMainScreen() async {
        let profileRepository = InMemoryProfileRepository(
            profile: makeProfile(selectedClass: .princess)
        )
        let viewModel = MainViewModel(
            profileRepository: profileRepository,
            gameConfigRepository: StaticGameConfigRepository(quests: [makeQuest()]),
            eventBus: AppEventBus(),
            router: AppRouter()
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.selectedClass, .princess)
        XCTAssertEqual(viewModel.heroTitle, "Princess")
    }
}
