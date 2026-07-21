import XCTest
@testable import HealthyHeroes

final class QuestEngineTests: XCTestCase {
    func testLoggingMatchingCategoryCompletesQuestAtTarget() {
        let engine = QuestEngine()
        let quest = makeQuest(
            id: "fruit",
            target: 2,
            currentProgress: 1,
            trigger: .logFruit
        )

        let result = engine.updateQuests(afterLogging: .fruit, quests: [quest])

        XCTAssertEqual(result.completedQuestIDs, ["fruit"])
        XCTAssertEqual(result.quests.first?.currentProgress, 2)
        XCTAssertEqual(result.quests.first?.status, .completed)
    }

    func testLoggingDifferentCategoryDoesNotAdvanceQuest() {
        let engine = QuestEngine()
        let quest = makeQuest(
            id: "water",
            target: 2,
            currentProgress: 0,
            trigger: .logWater
        )

        let result = engine.updateQuests(afterLogging: .fruit, quests: [quest])

        XCTAssertTrue(result.completedQuestIDs.isEmpty)
        XCTAssertEqual(result.quests.first?.currentProgress, 0)
        XCTAssertEqual(result.quests.first?.status, .active)
    }

    func testCompletedQuestDoesNotCompleteAgain() {
        let engine = QuestEngine()
        let quest = makeQuest(
            id: "done",
            target: 1,
            currentProgress: 1,
            status: .rewarded,
            trigger: .logAnyHealthyFood
        )

        let result = engine.updateQuests(afterLogging: .vegetable, quests: [quest])

        XCTAssertTrue(result.completedQuestIDs.isEmpty)
        XCTAssertEqual(result.quests.first?.currentProgress, 1)
        XCTAssertEqual(result.quests.first?.status, .rewarded)
    }
}
