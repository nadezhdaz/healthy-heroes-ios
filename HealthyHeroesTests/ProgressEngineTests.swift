import XCTest
@testable import HealthyHeroes

final class ProgressEngineTests: XCTestCase {
    func testSmallProgressUsesConfigValue() {
        let engine = ProgressEngine()
        let config = ProgressConfig(smallFoodLogXP: 7, completedQuestXP: 30)

        XCTAssertEqual(engine.smallProgressAward(config: config), 7)
    }

    func testBigProgressScalesByCompletedQuestCount() {
        let engine = ProgressEngine()
        let config = ProgressConfig(smallFoodLogXP: 5, completedQuestXP: 25)

        XCTAssertEqual(engine.bigProgressAward(completedQuestCount: 3, config: config), 75)
    }

    func testAddingXPDoesNotChangeMapPositionDirectly() {
        let engine = ProgressEngine()
        let progress = ProgressState(totalXP: 10, mapPosition: 2)

        XCTAssertEqual(
            engine.addingXP(15, to: progress),
            ProgressState(totalXP: 25, mapPosition: 2)
        )
    }

    func testMapEngineDerivesMapPositionFromXPThresholds() {
        let engine = MapEngine()
        let config = MapConfig(xpPerStep: 10, maxPosition: 4)

        XCTAssertEqual(engine.updatedMapPosition(totalXP: 35, config: config), 3)
        XCTAssertEqual(engine.updatedMapPosition(totalXP: 99, config: config), 4)
    }
}
