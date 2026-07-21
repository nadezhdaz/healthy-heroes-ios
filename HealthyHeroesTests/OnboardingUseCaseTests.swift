import XCTest
@testable import HealthyHeroes

final class OnboardingUseCaseTests: XCTestCase {
    func testCreateCharacterSavesAppearanceAndOnboardingState() throws {
        let profileRepository = InMemoryProfileRepository()
        let configRepository = StaticGameConfigRepository(quests: [makeQuest()])
        let useCase = CreateCharacterUseCaseImpl(
            profileRepository: profileRepository,
            gameConfigRepository: configRepository
        )
        let appearance = CharacterAppearance(
            hairStyle: "bhairstyle_2",
            faceStyle: "face_round",
            eyesStyle: "b_eyes2",
            noseStyle: "b_nose2",
            earsStyle: "ears_round"
        )

        let profile = try useCase.create(appearance: appearance)

        XCTAssertEqual(profile.character.appearance, appearance)
        XCTAssertTrue(profile.onboarding.hasCreatedCharacter)
        XCTAssertEqual(profile.quests.map(\.id), ["quest"])
        XCTAssertEqual(profileRepository.savedProfiles.last, profile)
    }

    func testSelectStarterClassSavesAvailableClass() throws {
        let profileRepository = InMemoryProfileRepository(profile: makeProfile())
        let useCase = SelectStarterClassUseCaseImpl(
            profileRepository: profileRepository,
            gameConfigRepository: StaticGameConfigRepository(quests: [makeQuest()])
        )

        let profile = try useCase.select(.guardian)

        XCTAssertEqual(profile.character.selectedClass, .guardian)
        XCTAssertTrue(profile.onboarding.hasSelectedClass)
        XCTAssertEqual(profileRepository.savedProfiles.last, profile)
    }

    func testSelectStarterClassRejectsLockedClass() throws {
        let profileRepository = InMemoryProfileRepository(profile: makeProfile())
        let useCase = SelectStarterClassUseCaseImpl(
            profileRepository: profileRepository,
            gameConfigRepository: StaticGameConfigRepository(quests: [makeQuest()])
        )

        XCTAssertThrowsError(try useCase.select(.sproutMage)) { error in
            XCTAssertEqual(error as? UseCaseError, .classLocked)
        }
        XCTAssertTrue(profileRepository.savedProfiles.isEmpty)
    }
}
