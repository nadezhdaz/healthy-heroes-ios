import XCTest
@testable import HealthyHeroes

final class OnboardingUseCaseTests: XCTestCase {
    func testCharacterClassesMatchMVPDesignSources() {
        XCTAssertEqual(
            CharacterClass.allCases,
            [.knight, .princess, .wizard, .fairy, .elf, .mermaid, .unicorn, .dragon]
        )
        XCTAssertEqual(
            CharacterClass.allCases.map(\.title),
            ["Knight", "Princess", "Wizard", "Fairy", "Elf", "Mermaid", "Unicorn", "Dragon"]
        )
        XCTAssertEqual(
            CharacterClass.allCases.map(\.assetID),
            [
                "class_knight",
                "class_princess",
                "class_wizard",
                "class_fairy",
                "class_elf",
                "class_mermaid",
                "class_unicorn",
                "class_dragon"
            ]
        )
    }

    func testOnlyKnightAndPrincessAreAvailableAtStart() {
        XCTAssertEqual(
            CharacterClass.allCases.filter(\.isAvailableAtStart),
            [.knight, .princess]
        )
        XCTAssertEqual(
            CharacterClass.allCases.filter(\.isLocked),
            [.wizard, .fairy, .elf, .mermaid, .unicorn, .dragon]
        )
    }

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

        let profile = try useCase.select(.princess)

        XCTAssertEqual(profile.character.selectedClass, .princess)
        XCTAssertTrue(profile.onboarding.hasSelectedClass)
        XCTAssertEqual(profileRepository.savedProfiles.last, profile)
    }

    func testSelectStarterClassRejectsEveryLockedClass() throws {
        let profileRepository = InMemoryProfileRepository(profile: makeProfile())
        let useCase = SelectStarterClassUseCaseImpl(
            profileRepository: profileRepository,
            gameConfigRepository: StaticGameConfigRepository(quests: [makeQuest()])
        )

        for characterClass in CharacterClass.allCases.filter(\.isLocked) {
            XCTAssertThrowsError(try useCase.select(characterClass)) { error in
                XCTAssertEqual(error as? UseCaseError, .classLocked)
            }
        }
        XCTAssertTrue(profileRepository.savedProfiles.isEmpty)
    }
}
