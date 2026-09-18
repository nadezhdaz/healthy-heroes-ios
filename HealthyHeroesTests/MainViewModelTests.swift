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
    func testProgressUsesConfiguredMapLengthAndClampsAtEndpoints() async throws {
        var profile = makeProfile()
        let repository = InMemoryProfileRepository(profile: profile)
        for config in [MapConfig(xpPerStep: 10, maxPosition: 20), MapConfig(xpPerStep: 15, maxPosition: 10)] {
            let model = MainViewModel(
                profileRepository: repository,
                gameConfigRepository: StaticGameConfigRepository(quests: [], map: config),
                eventBus: AppEventBus(), router: AppRouter()
            )
            let target = config.xpPerStep * config.maxPosition
            for (xp, expected) in [(-5, 0.0), (0, 0.0), (target / 2, 0.5), (target, 1.0), (target + 5, 1.0)] {
                profile.progress.totalXP = xp
                try await repository.saveProfile(profile)
                await model.load()
                XCTAssertEqual(model.progressValue, expected, accuracy: 0.001)
            }
        }
    }

}
