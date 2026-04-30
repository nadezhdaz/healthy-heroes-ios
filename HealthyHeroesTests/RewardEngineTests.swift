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
}
