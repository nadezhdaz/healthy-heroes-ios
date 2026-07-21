import CoreData
import XCTest
@testable import HealthyHeroes

final class CoreDataGameRepositoryTests: XCTestCase {
    func testV1ModelKeepsRequiredUniqueIdentifiers() throws {
        let persistence = try CoreDataPersistenceController(inMemory: true)
        let model = persistence.container.managedObjectModel
        let requiredConstraints = [
            "ChildProfileEntity": "profileID",
            "FoodLogEntryEntity": "entryID",
            "QuestProgressEntity": "questID",
            "RewardUnlockEntity": "rewardID",
            "WardrobeStateEntity": "itemID",
            "LegacyImportEntity": "migrationID"
        ]

        for (entityName, attributeName) in requiredConstraints {
            let entity = try XCTUnwrap(model.entitiesByName[entityName])
            let hasConstraint = entity.uniquenessConstraints.contains { constraint in
                constraint.contains { value in
                    if let name = value as? String {
                        return name == attributeName
                    }
                    return (value as? NSPropertyDescription)?.name == attributeName
                }
            }
            XCTAssertTrue(hasConstraint, "Missing \(attributeName) constraint on \(entityName)")
        }
    }

    func testProfileRoundTripUsesNormalizedStore() async throws {
        let quest = makeQuest(id: "quest", target: 1, currentProgress: 1, status: .rewarded)
        let repository = try makeRepository(quests: [quest])
        var profile = makeProfile(quests: [quest], selectedClass: .princess)
        profile.progress = ProgressState(totalXP: 35, mapPosition: 3)
        profile.unlockedRewardIDs = ["wardrobe_leaf_cape", "sticker_star"]
        profile.wardrobe = WardrobeState(
            unlockedItemIDs: ["wardrobe_leaf_cape"],
            equippedItemIDs: ["wardrobe_leaf_cape"]
        )
        profile.character.equippedItemIDs = ["wardrobe_leaf_cape"]
        profile.stickers.unlockedStickerIDs = ["sticker_star"]

        try await repository.saveProfile(profile)

        let loadedProfile = try await repository.loadProfile()
        XCTAssertEqual(loadedProfile, profile)
    }

    func testFoodLogTransactionRollsBackProfileWhenEntryFails() async throws {
        let repository = try makeRepository(quests: [makeQuest()])
        let originalProfile = makeProfile()
        let duplicateEntry = FoodLogEntry(
            id: "duplicate-entry",
            category: .fruit,
            customTitle: nil,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        try await repository.saveProfile(originalProfile)
        try await repository.addEntry(duplicateEntry)

        var updatedProfile = originalProfile
        updatedProfile.progress.totalXP = 999

        do {
            try await repository.commitFoodLog(duplicateEntry, updatedProfile: updatedProfile)
            XCTFail("Expected duplicate entry to roll back the transaction")
        } catch {
            XCTAssertEqual(
                error as? CoreDataPersistenceError,
                .duplicateFoodLogEntry("duplicate-entry")
            )
        }
        let rolledBackProfile = try await repository.loadProfile()
        let storedEntries = try await repository.fetchEntries()
        XCTAssertEqual(rolledBackProfile, originalProfile)
        XCTAssertEqual(storedEntries, [duplicateEntry])
    }

    func testLegacyV1FixtureImportsProfileAndFoodLogOnce() async throws {
        let repository = try makeRepository(quests: [makeQuest()])
        let fixture = fixtureDirectory(named: "legacy-v1")

        XCTAssertTrue(
            try repository.migrateLegacyJSONIfNeeded(
                profileURL: fixture.appendingPathComponent("legacy-v1-profile.json"),
                foodLogURL: fixture.appendingPathComponent("legacy-v1-food-log.json")
            )
        )
        let importedProfile = try await repository.loadProfile()
        let importedEntryIDs = try await repository.fetchEntries().map(\.id)
        XCTAssertEqual(importedProfile?.id, "legacy-v1-child")
        XCTAssertEqual(importedProfile?.character.selectedClass, .princess)
        XCTAssertEqual(importedProfile?.progress.totalXP, 35)
        XCTAssertEqual(importedEntryIDs, ["legacy-v1-entry"])
        XCTAssertTrue(try repository.hasCompletedLegacyImport())

        XCTAssertFalse(
            try repository.migrateLegacyJSONIfNeeded(
                profileURL: fixture.appendingPathComponent("legacy-v1-profile.json"),
                foodLogURL: fixture.appendingPathComponent("legacy-v1-food-log.json")
            )
        )
        let entryCount = try await repository.fetchEntries().count
        XCTAssertEqual(entryCount, 1)
    }

    func testLegacyV0FixtureMapsGuardianToKnight() async throws {
        let repository = try makeRepository(quests: [makeQuest()])
        let fixture = fixtureDirectory(named: "legacy-v0")

        XCTAssertTrue(
            try repository.migrateLegacyJSONIfNeeded(
                profileURL: fixture.appendingPathComponent("legacy-v0-profile.json"),
                foodLogURL: fixture.appendingPathComponent("legacy-v0-food-log.json")
            )
        )

        let loadedProfile = try await repository.loadProfile()
        let profile = try XCTUnwrap(loadedProfile)
        XCTAssertEqual(profile.id, "legacy-v0-child")
        XCTAssertEqual(profile.character.selectedClass, .knight)
        XCTAssertEqual(profile.progress.totalXP, 10)
        XCTAssertTrue(try repository.hasCompletedLegacyImport())
    }

    private func makeRepository(quests: [Quest]) throws -> CoreDataGameRepository {
        let persistence = try CoreDataPersistenceController(inMemory: true)
        return CoreDataGameRepository(
            container: persistence.container,
            gameConfigRepository: StaticGameConfigRepository(quests: quests),
            rewardCatalogRepository: StaticRewardCatalogRepository(
                rewards: [
                    Reward(
                        id: "wardrobe_leaf_cape",
                        type: .wardrobeItem,
                        title: "Leaf Cape",
                        assetID: "reward_leaf_cape"
                    ),
                    Reward(
                        id: "sticker_star",
                        type: .sticker,
                        title: "Star",
                        assetID: "reward_star_sticker"
                    )
                ]
            )
        )
    }

    private func fixtureDirectory(named name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
    }
}
