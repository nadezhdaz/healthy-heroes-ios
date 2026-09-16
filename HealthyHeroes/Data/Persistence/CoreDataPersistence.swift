import CoreData
import Foundation

enum CoreDataPersistenceError: Error, Equatable {
    case modelNotFound
    case storeLoadFailed(String)
    case missingProfile
    case invalidCharacterClass(String)
    case invalidFoodCategory(String)
    case invalidQuestStatus(String)
    case duplicateFoodLogEntry(String)
    case rewardNotUnlocked(String)
    case legacyImportVerificationFailed
}

final class CoreDataPersistenceController {
    let container: NSPersistentContainer

    init(
        storeURL: URL? = nil,
        inMemory: Bool = false,
        bundle: Bundle = .main
    ) throws {
#if DEBUG
        let bootstrapStartedAt = ProcessInfo.processInfo.systemUptime
#endif
        let model = try Self.loadModel(bundle: bundle)
        container = NSPersistentContainer(name: "HealthyHeroes", managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        description.type = inMemory ? NSInMemoryStoreType : NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(
            FileProtectionType.completeUntilFirstUserAuthentication as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )

        if let storeURL, !inMemory {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            description.url = storeURL
        }
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw CoreDataPersistenceError.storeLoadFailed(
                String(describing: type(of: loadError))
            )
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
#if DEBUG
        NSLog(
            "PERF persistence_controller_ms=%.2f",
            (ProcessInfo.processInfo.systemUptime - bootstrapStartedAt) * 1_000
        )
#endif
    }

    private static func loadModel(bundle: Bundle) throws -> NSManagedObjectModel {
        let bundles = [bundle, Bundle(for: CoreDataPersistenceController.self)]
        let modelURL = bundles.lazy.compactMap { candidate in
            candidate.url(forResource: "HealthyHeroes", withExtension: "momd")
                ?? candidate.url(forResource: "HealthyHeroes", withExtension: "mom")
        }.first

        guard let modelURL, let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataPersistenceError.modelNotFound
        }
        return model
    }
}

@objc(HHChildProfileEntity)
private final class ChildProfileEntity: NSManagedObject {
    static let entityName = "ChildProfileEntity"

    @NSManaged var profileID: String
    @NSManaged var selectedClass: String?
    @NSManaged var baseStyle: String?
    @NSManaged var hairStyle: String
    @NSManaged var faceStyle: String
    @NSManaged var browsStyle: String?
    @NSManaged var eyesStyle: String
    @NSManaged var noseStyle: String
    @NSManaged var mouthStyle: String?
    @NSManaged var earsStyle: String
    @NSManaged var totalXP: Int64
    @NSManaged var mapPosition: Int64
    @NSManaged var hasSeenStart: Bool
    @NSManaged var hasCreatedCharacter: Bool
    @NSManaged var hasSelectedClass: Bool
    @NSManaged var hasCompletedFirstFoodLog: Bool
    @NSManaged var hasCompletedFirstQuest: Bool
    @NSManaged var hasOpenedFirstReward: Bool
    @NSManaged var hasEquippedFirstItem: Bool
    @NSManaged var isFirstSessionCompleted: Bool
    @NSManaged var updatedAt: Date
}

@objc(HHFoodLogEntryEntity)
private final class FoodLogEntryEntity: NSManagedObject {
    static let entityName = "FoodLogEntryEntity"

    @NSManaged var entryID: String
    @NSManaged var profileID: String
    @NSManaged var category: String
    @NSManaged var customTitle: String?
    @NSManaged var createdAt: Date
}

@objc(HHQuestProgressEntity)
private final class QuestProgressEntity: NSManagedObject {
    static let entityName = "QuestProgressEntity"

    @NSManaged var questID: String
    @NSManaged var profileID: String
    @NSManaged var currentProgress: Int64
    @NSManaged var status: String
}

@objc(HHRewardUnlockEntity)
private final class RewardUnlockEntity: NSManagedObject {
    static let entityName = "RewardUnlockEntity"

    @NSManaged var rewardID: String
    @NSManaged var profileID: String
    @NSManaged var isOpened: Bool
    @NSManaged var sortIndex: Int64
    @NSManaged var unlockedAt: Date
    @NSManaged var openedAt: Date?
}

@objc(HHWardrobeStateEntity)
private final class WardrobeStateEntity: NSManagedObject {
    static let entityName = "WardrobeStateEntity"

    @NSManaged var itemID: String
    @NSManaged var profileID: String
    @NSManaged var isUnlocked: Bool
    @NSManaged var isEquipped: Bool
    @NSManaged var unlockedIndex: Int64
    @NSManaged var equippedIndex: Int64
}

@objc(HHLegacyImportEntity)
private final class LegacyImportEntity: NSManagedObject {
    static let entityName = "LegacyImportEntity"

    @NSManaged var migrationID: String
    @NSManaged var completedAt: Date
    @NSManaged var profileCount: Int64
    @NSManaged var foodLogEntryCount: Int64
}

final class CoreDataGameRepository: GameStateRepository, @unchecked Sendable {
    private static let legacyMigrationID = "legacy-v1"

    private let context: NSManagedObjectContext
    private let gameConfigRepository: any GameConfigRepository
    private let rewardCatalogRepository: any RewardCatalogRepository

    init(
        container: NSPersistentContainer,
        gameConfigRepository: any GameConfigRepository,
        rewardCatalogRepository: any RewardCatalogRepository
    ) {
        context = container.newBackgroundContext()
        context.name = "HealthyHeroes.CoreDataWriter"
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        self.gameConfigRepository = gameConfigRepository
        self.rewardCatalogRepository = rewardCatalogRepository
    }

    func loadProfile() async throws -> ChildProfile? {
        try await context.perform {
            guard let entity = try self.fetchProfileEntity() else { return nil }
            return try self.mapProfile(entity)
        }
    }

    func saveProfile(_ profile: ChildProfile) async throws {
        try await performTransaction {
            try self.upsertProfile(profile)
        }
    }

    func fetchEntries() async throws -> [FoodLogEntry] {
        try await context.perform {
            let request = NSFetchRequest<FoodLogEntryEntity>(
                entityName: FoodLogEntryEntity.entityName
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: true),
                NSSortDescriptor(key: "entryID", ascending: true)
            ]
            return try self.context.fetch(request).map(self.mapFoodLogEntry)
        }
    }

    func addEntry(_ entry: FoodLogEntry) async throws {
        try await performTransaction {
            guard let profileID = try self.fetchProfileEntity()?.profileID else {
                throw CoreDataPersistenceError.missingProfile
            }
            try self.insertFoodLogEntry(entry, profileID: profileID)
        }
    }

    func commitFoodLog(_ entry: FoodLogEntry, updatedProfile: ChildProfile) async throws {
        try await performTransaction {
            try self.upsertProfile(updatedProfile)
            try self.insertFoodLogEntry(entry, profileID: updatedProfile.id)
        }
    }

    func commitRewardOpened(_ rewardID: RewardID, updatedProfile: ChildProfile) async throws {
        try await performTransaction {
            try self.upsertProfile(updatedProfile)
            let request = NSFetchRequest<RewardUnlockEntity>(
                entityName: RewardUnlockEntity.entityName
            )
            request.predicate = NSPredicate(format: "rewardID == %@", rewardID)
            request.fetchLimit = 1
            guard let reward = try self.context.fetch(request).first else {
                throw CoreDataPersistenceError.rewardNotUnlocked(rewardID)
            }
            reward.isOpened = true
            reward.openedAt = Date()
        }
    }

    @discardableResult
    func migrateLegacyJSONIfNeeded(profileURL: URL, foodLogURL: URL) throws -> Bool {
        return try context.performAndWait {
            guard try fetchLegacyImportMarker() == nil else { return false }
            let legacyProfile = try Self.decodeLegacyProfile(at: profileURL)
            let legacyEntries = try Self.decodeLegacy([FoodLogEntry].self, at: foodLogURL) ?? []

            do {
                let existingProfileCount = try count(entityName: ChildProfileEntity.entityName)
                let existingEntryCount = try count(entityName: FoodLogEntryEntity.entityName)

                if existingProfileCount == 0, let legacyProfile {
                    try upsertProfile(legacyProfile)
                    for entry in legacyEntries {
                        try insertFoodLogEntry(entry, profileID: legacyProfile.id)
                    }
                    try verifyLegacyImport(profile: legacyProfile, entries: legacyEntries)
                }

                let marker = LegacyImportEntity(context: context)
                marker.migrationID = Self.legacyMigrationID
                marker.completedAt = Date()
                marker.profileCount = Int64(legacyProfile == nil ? existingProfileCount : 1)
                marker.foodLogEntryCount = Int64(
                    legacyProfile == nil ? existingEntryCount : legacyEntries.count
                )
                try context.save()
                return legacyProfile != nil || !legacyEntries.isEmpty
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func hasCompletedLegacyImport() throws -> Bool {
        try context.performAndWait {
            try fetchLegacyImportMarker() != nil
        }
    }

    private func performTransaction(_ changes: @escaping () throws -> Void) async throws {
        try await context.perform {
            do {
                try changes()
                if self.context.hasChanges {
                    try self.context.save()
                }
            } catch {
                self.context.rollback()
                throw error
            }
        }
    }

    private func mapProfile(_ entity: ChildProfileEntity) throws -> ChildProfile {
        let selectedClass: CharacterClass?
        if let rawValue = entity.selectedClass {
            guard let value = CharacterClass(rawValue: rawValue) else {
                throw CoreDataPersistenceError.invalidCharacterClass(rawValue)
            }
            selectedClass = value
        } else {
            selectedClass = nil
        }

        let questRequest = NSFetchRequest<QuestProgressEntity>(
            entityName: QuestProgressEntity.entityName
        )
        questRequest.predicate = NSPredicate(format: "profileID == %@", entity.profileID)
        let questProgress = Dictionary(
            uniqueKeysWithValues: try context.fetch(questRequest).map { ($0.questID, $0) }
        )
        let quests = try gameConfigRepository.starterQuests().map { definition in
            guard let progress = questProgress[definition.id] else { return definition }
            guard let status = QuestStatus(rawValue: progress.status) else {
                throw CoreDataPersistenceError.invalidQuestStatus(progress.status)
            }
            var quest = definition
            quest.currentProgress = Int(progress.currentProgress)
            quest.status = status
            return quest
        }

        let rewardRequest = NSFetchRequest<RewardUnlockEntity>(
            entityName: RewardUnlockEntity.entityName
        )
        rewardRequest.predicate = NSPredicate(format: "profileID == %@", entity.profileID)
        rewardRequest.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
        let rewardEntities = try context.fetch(rewardRequest)
        let unlockedRewardIDs = rewardEntities.map(\.rewardID)
        let rewardTypes = Dictionary(
            uniqueKeysWithValues: try rewardCatalogRepository.allRewards().map { ($0.id, $0.type) }
        )
        let stickerIDs = unlockedRewardIDs.filter { rewardTypes[$0] == .sticker }

        let wardrobeRequest = NSFetchRequest<WardrobeStateEntity>(
            entityName: WardrobeStateEntity.entityName
        )
        wardrobeRequest.predicate = NSPredicate(format: "profileID == %@", entity.profileID)
        let wardrobeEntities = try context.fetch(wardrobeRequest)
        let unlockedItems = wardrobeEntities
            .filter(\.isUnlocked)
            .sorted { $0.unlockedIndex < $1.unlockedIndex }
            .map(\.itemID)
        let equippedItems = wardrobeEntities
            .filter(\.isEquipped)
            .sorted { $0.equippedIndex < $1.equippedIndex }
            .map(\.itemID)

        return ChildProfile(
            id: entity.profileID,
            character: CharacterState(
                appearance: CharacterAppearance(
                    baseStyle: entity.baseStyle.flatMap(CharacterBaseStyle.init(rawValue:)),
                    hairStyle: entity.hairStyle,
                    faceStyle: entity.faceStyle,
                    browsStyle: entity.browsStyle,
                    eyesStyle: entity.eyesStyle,
                    noseStyle: entity.noseStyle,
                    mouthStyle: entity.mouthStyle,
                    earsStyle: entity.earsStyle
                ),
                selectedClass: selectedClass,
                equippedItemIDs: equippedItems
            ),
            progress: ProgressState(
                totalXP: Int(entity.totalXP),
                mapPosition: Int(entity.mapPosition)
            ),
            quests: quests,
            unlockedRewardIDs: unlockedRewardIDs,
            wardrobe: WardrobeState(
                unlockedItemIDs: unlockedItems,
                equippedItemIDs: equippedItems
            ),
            stickers: StickerAlbumState(unlockedStickerIDs: stickerIDs),
            onboarding: OnboardingState(
                hasSeenStart: entity.hasSeenStart,
                hasCreatedCharacter: entity.hasCreatedCharacter,
                hasSelectedClass: entity.hasSelectedClass,
                hasCompletedFirstFoodLog: entity.hasCompletedFirstFoodLog,
                hasCompletedFirstQuest: entity.hasCompletedFirstQuest,
                hasOpenedFirstReward: entity.hasOpenedFirstReward,
                hasEquippedFirstItem: entity.hasEquippedFirstItem,
                isFirstSessionCompleted: entity.isFirstSessionCompleted
            ),
            openedRewardIDs: rewardEntities.contains(where: \.isOpened)
                ? rewardEntities.filter(\.isOpened).map(\.rewardID) : nil
        )
    }

    private func mapFoodLogEntry(_ entity: FoodLogEntryEntity) throws -> FoodLogEntry {
        guard let category = FoodCategory(rawValue: entity.category) else {
            throw CoreDataPersistenceError.invalidFoodCategory(entity.category)
        }
        return FoodLogEntry(
            id: entity.entryID,
            category: category,
            customTitle: entity.customTitle,
            createdAt: entity.createdAt
        )
    }

    private func upsertProfile(_ profile: ChildProfile) throws {
        let request = NSFetchRequest<ChildProfileEntity>(entityName: ChildProfileEntity.entityName)
        request.predicate = NSPredicate(format: "profileID == %@", profile.id)
        request.fetchLimit = 1
        let entity = try context.fetch(request).first ?? ChildProfileEntity(context: context)

        entity.profileID = profile.id
        entity.selectedClass = profile.character.selectedClass?.rawValue
        entity.baseStyle = profile.character.appearance.baseStyle.rawValue
        entity.hairStyle = profile.character.appearance.hairStyle
        entity.faceStyle = profile.character.appearance.faceStyle
        entity.browsStyle = profile.character.appearance.browsStyle
        entity.eyesStyle = profile.character.appearance.eyesStyle
        entity.noseStyle = profile.character.appearance.noseStyle
        entity.mouthStyle = profile.character.appearance.mouthStyle
        entity.earsStyle = profile.character.appearance.earsStyle
        entity.totalXP = Int64(profile.progress.totalXP)
        entity.mapPosition = Int64(profile.progress.mapPosition)
        entity.hasSeenStart = profile.onboarding.hasSeenStart
        entity.hasCreatedCharacter = profile.onboarding.hasCreatedCharacter
        entity.hasSelectedClass = profile.onboarding.hasSelectedClass
        entity.hasCompletedFirstFoodLog = profile.onboarding.hasCompletedFirstFoodLog
        entity.hasCompletedFirstQuest = profile.onboarding.hasCompletedFirstQuest
        entity.hasOpenedFirstReward = profile.onboarding.hasOpenedFirstReward
        entity.hasEquippedFirstItem = profile.onboarding.hasEquippedFirstItem
        entity.isFirstSessionCompleted = profile.onboarding.isFirstSessionCompleted
        entity.updatedAt = Date()

        try syncQuestProgress(profile)
        try syncRewardUnlocks(profile)
        try syncWardrobe(profile)
    }

    private func syncQuestProgress(_ profile: ChildProfile) throws {
        let request = NSFetchRequest<QuestProgressEntity>(
            entityName: QuestProgressEntity.entityName
        )
        request.predicate = NSPredicate(format: "profileID == %@", profile.id)
        let existing = try context.fetch(request)
        var entitiesByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.questID, $0) })

        for quest in profile.quests {
            let entity = entitiesByID.removeValue(forKey: quest.id)
                ?? QuestProgressEntity(context: context)
            entity.questID = quest.id
            entity.profileID = profile.id
            entity.currentProgress = Int64(quest.currentProgress)
            entity.status = quest.status.rawValue
        }
        entitiesByID.values.forEach(context.delete)
    }

    private func syncRewardUnlocks(_ profile: ChildProfile) throws {
        let request = NSFetchRequest<RewardUnlockEntity>(
            entityName: RewardUnlockEntity.entityName
        )
        request.predicate = NSPredicate(format: "profileID == %@", profile.id)
        let existing = try context.fetch(request)
        var entitiesByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.rewardID, $0) })

        var rewardIDs = profile.unlockedRewardIDs
        for stickerID in profile.stickers.unlockedStickerIDs where !rewardIDs.contains(stickerID) {
            rewardIDs.append(stickerID)
        }

        for (index, rewardID) in rewardIDs.enumerated() {
            let existingEntity = entitiesByID.removeValue(forKey: rewardID)
            let entity = existingEntity ?? RewardUnlockEntity(context: context)
            entity.rewardID = rewardID
            entity.profileID = profile.id
            entity.sortIndex = Int64(index)
            if existingEntity == nil {
                entity.isOpened = false
                entity.unlockedAt = Date()
            }
            if profile.openedRewardIDs?.contains(rewardID) == true {
                entity.isOpened = true
            }
        }
        entitiesByID.values.forEach(context.delete)
    }

    private func syncWardrobe(_ profile: ChildProfile) throws {
        let request = NSFetchRequest<WardrobeStateEntity>(
            entityName: WardrobeStateEntity.entityName
        )
        request.predicate = NSPredicate(format: "profileID == %@", profile.id)
        let existing = try context.fetch(request)
        var entitiesByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.itemID, $0) })

        var itemIDs = profile.wardrobe.unlockedItemIDs
        let equippedIDs = profile.wardrobe.equippedItemIDs + profile.character.equippedItemIDs
        for itemID in equippedIDs where !itemIDs.contains(itemID) {
            itemIDs.append(itemID)
        }

        for itemID in itemIDs {
            let entity = entitiesByID.removeValue(forKey: itemID)
                ?? WardrobeStateEntity(context: context)
            entity.itemID = itemID
            entity.profileID = profile.id
            entity.isUnlocked = profile.wardrobe.unlockedItemIDs.contains(itemID)
            entity.isEquipped = equippedIDs.contains(itemID)
            entity.unlockedIndex = Int64(profile.wardrobe.unlockedItemIDs.firstIndex(of: itemID) ?? -1)
            entity.equippedIndex = Int64(equippedIDs.firstIndex(of: itemID) ?? -1)
        }
        entitiesByID.values.forEach(context.delete)
    }

    private func insertFoodLogEntry(_ entry: FoodLogEntry, profileID: String) throws {
        let request = NSFetchRequest<FoodLogEntryEntity>(
            entityName: FoodLogEntryEntity.entityName
        )
        request.predicate = NSPredicate(format: "entryID == %@", entry.id)
        request.fetchLimit = 1
        guard try context.fetch(request).isEmpty else {
            throw CoreDataPersistenceError.duplicateFoodLogEntry(entry.id)
        }

        let entity = FoodLogEntryEntity(context: context)
        entity.entryID = entry.id
        entity.profileID = profileID
        entity.category = entry.category.rawValue
        entity.customTitle = entry.customTitle
        entity.createdAt = entry.createdAt
    }

    private func fetchProfileEntity() throws -> ChildProfileEntity? {
        let request = NSFetchRequest<ChildProfileEntity>(entityName: ChildProfileEntity.entityName)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchLegacyImportMarker() throws -> LegacyImportEntity? {
        let request = NSFetchRequest<LegacyImportEntity>(entityName: LegacyImportEntity.entityName)
        request.predicate = NSPredicate(format: "migrationID == %@", Self.legacyMigrationID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func count(entityName: String) throws -> Int {
        try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entityName))
    }

    private func verifyLegacyImport(profile: ChildProfile, entries: [FoodLogEntry]) throws {
        guard let storedProfile = try fetchProfileEntity(),
              storedProfile.profileID == profile.id,
              storedProfile.totalXP == Int64(profile.progress.totalXP),
              storedProfile.mapPosition == Int64(profile.progress.mapPosition) else {
            throw CoreDataPersistenceError.legacyImportVerificationFailed
        }

        let request = NSFetchRequest<FoodLogEntryEntity>(
            entityName: FoodLogEntryEntity.entityName
        )
        let storedIDs = Set(try context.fetch(request).map(\.entryID))
        guard storedIDs == Set(entries.map(\.id)) else {
            throw CoreDataPersistenceError.legacyImportVerificationFailed
        }
    }

    private static func decodeLegacy<Value: Decodable>(
        _ type: Value.Type,
        at url: URL
    ) throws -> Value? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    private static func decodeLegacyProfile(at url: URL) throws -> ChildProfile? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let currentProfile = try? decoder.decode(ChildProfile.self, from: data) {
            return currentProfile
        }

        let legacyProfile = try decoder.decode(LegacyChildProfileV0.self, from: data)
        return legacyProfile.currentProfile
    }
}

private struct LegacyChildProfileV0: Decodable {
    let id: String
    let character: LegacyCharacterStateV0
    let progress: ProgressState
    let quests: [Quest]
    let unlockedRewardIDs: [RewardID]
    let wardrobe: WardrobeState
    let stickers: StickerAlbumState
    let onboarding: OnboardingState

    var currentProfile: ChildProfile {
        ChildProfile(
            id: id,
            character: CharacterState(
                appearance: character.appearance,
                selectedClass: character.currentClass,
                equippedItemIDs: character.equippedItemIDs
            ),
            progress: progress,
            quests: quests,
            unlockedRewardIDs: unlockedRewardIDs,
            wardrobe: wardrobe,
            stickers: stickers,
            onboarding: onboarding
        )
    }
}

private struct LegacyCharacterStateV0: Decodable {
    let appearance: CharacterAppearance
    let selectedClass: String?
    let equippedItemIDs: [WardrobeItemID]

    var currentClass: CharacterClass? {
        switch selectedClass {
        case "guardian": .knight
        case "explorer": .princess
        case "sproutMage": .wizard
        case let rawValue?: CharacterClass(rawValue: rawValue)
        case nil: nil
        }
    }
}
