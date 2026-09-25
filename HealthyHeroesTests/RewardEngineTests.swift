import XCTest
@testable import HealthyHeroes

final class RewardEngineTests: XCTestCase {
    func testUnlocksRewardForCompletedQuest() {
        let engine = RewardEngine()
        let profile = makeProfile(quests: [
            makeQuest(id: "quest", rewardID: "wardrobe_leaf_cape", status: .completed)
        ])

        let result = engine.unlockRewards(for: ["quest"], in: profile)

        XCTAssertEqual(result.unlockedRewardIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(result.profile.unlockedRewardIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(result.profile.wardrobe.unlockedItemIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(result.profile.quests.first?.status, .rewarded)
    }

    func testDoesNotUnlockSameRewardTwice() {
        let engine = RewardEngine()
        var profile = makeProfile(quests: [
            makeQuest(id: "quest", rewardID: "wardrobe_leaf_cape", status: .completed)
        ])
        profile.unlockedRewardIDs = ["wardrobe_leaf_cape"]

        let result = engine.unlockRewards(for: ["quest"], in: profile)

        XCTAssertTrue(result.unlockedRewardIDs.isEmpty)
        XCTAssertEqual(result.profile.unlockedRewardIDs, ["wardrobe_leaf_cape"])
    }

    func testStickerRewardUpdatesStickerAlbum() {
        let engine = RewardEngine()
        let profile = makeProfile(quests: [
            makeQuest(id: "quest", rewardID: "sticker_star", status: .completed)
        ])

        let result = engine.unlockRewards(for: ["quest"], in: profile)

        XCTAssertEqual(result.profile.stickers.unlockedStickerIDs, ["sticker_star"])
        XCTAssertTrue(result.profile.wardrobe.unlockedItemIDs.isEmpty)
    }
    func testSimultaneousQuestsGrantEachSharedRewardOnlyOnce() {
        let quests = [
            makeQuest(id: "first", rewardID: "wardrobe_leaf_cape", status: .completed),
            makeQuest(id: "second", rewardID: "wardrobe_leaf_cape", status: .completed),
            makeQuest(id: "third", rewardID: "sticker_star", status: .completed),
            makeQuest(id: "fourth", rewardID: "sticker_star", status: .completed)
        ]
        let engine = RewardEngine()
        let result = engine.unlockRewards(for: quests.map(\.id), in: makeProfile(quests: quests))
        XCTAssertEqual(result.unlockedRewardIDs, ["wardrobe_leaf_cape", "sticker_star"])
        XCTAssertEqual(result.profile.unlockedRewardIDs, result.unlockedRewardIDs)
        XCTAssertEqual(result.profile.wardrobe.unlockedItemIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(result.profile.stickers.unlockedStickerIDs, ["sticker_star"])
        XCTAssertTrue(result.profile.quests.allSatisfy { $0.status == .rewarded })
        let repeated = engine.unlockRewards(for: quests.map(\.id), in: result.profile)
        XCTAssertTrue(repeated.unlockedRewardIDs.isEmpty)
        XCTAssertEqual(repeated.profile, result.profile)
    }

}
