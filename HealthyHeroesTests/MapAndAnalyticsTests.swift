import XCTest
import SwiftUI
@testable import HealthyHeroes

@MainActor
final class MapAndAnalyticsTests: XCTestCase {
    func testRenderAdaptiveMapCompositions() async throws {
        for asset in ["map_phone_top", "map_phone_bottom", "map_hero_marker", "map_tile_2", "map_tile_3", "map_tile_4", "map_tile_5", "map_tile_6"] {
            let image = await AssetResolver().uiImage(for: asset)
            XCTAssertNotNil(image, "Missing map asset: \(asset)")
        }
        for size in [CGSize(width: 393, height: 852), CGSize(width: 1194, height: 834), CGSize(width: 500, height: 400)] {
            for position in [7, 14, 20] {
            let scene = AdaptiveMapScene(
                progress: ProgressState(totalXP: position * 10, mapPosition: position), displayedPosition: Double(position),
                config: MapConfig(xpPerStep: 10, maxPosition: 20),
                safeAreaInsets: EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0),
                selectedNode: .constant(nil)
            ).frame(width: size.width, height: size.height)
            let controller = UIHostingController(rootView: scene)
            let window = UIWindow(frame: CGRect(origin: .zero, size: size))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = CGRect(origin: .zero, size: size)
            try await Task.sleep(for: .seconds(1))
            controller.view.layoutIfNeeded()
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                controller.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            }
            window.isHidden = true
            XCTAssertEqual(image.size, size)
            let attachment = XCTAttachment(image: image)
            attachment.name = "map-\(Int(size.width))x\(Int(size.height))-step-\(position)"
            attachment.lifetime = .keepAlways
            add(attachment)
            }
        }
    }

    func testInterruptedMapMovementPreservesLastSeenPosition() async throws {
        let suite = UserDefaults(suiteName: #function)!
        suite.removePersistentDomain(forName: #function)
        defer { suite.removePersistentDomain(forName: #function) }
        suite.set(3, forKey: "position")
        let started = expectation(description: "Movement started")
        let movement = Task {
            try await MapView.showProgress(position: 7, storageKey: "position", reduceMotion: false,
                                           defaults: suite) { position in
                XCTAssertEqual(position, 7)
                started.fulfill()
            }
        }
        await fulfillment(of: [started], timeout: 2)
        movement.cancel()
        do {
            try await movement.value
            XCTFail("Interrupted movement must be cancelled")
        } catch is CancellationError {}
        XCTAssertEqual(suite.integer(forKey: "position"), 3)
        try await MapView.showProgress(position: 8, storageKey: "position", reduceMotion: true,
                                       defaults: suite) { XCTAssertEqual($0, 8) }
        XCTAssertEqual(suite.integer(forKey: "position"), 8)
    }

    func testRouteAndRewardTargetsRespectAsymmetricSafeAreas() {
        for size in [CGSize(width: 393, height: 852), CGSize(width: 852, height: 393), CGSize(width: 500, height: 400)] {
            for insets in [EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
                           EdgeInsets(top: 24, leading: 59, bottom: 21, trailing: 0),
                           EdgeInsets(top: 24, leading: 0, bottom: 21, trailing: 59)] {
                let layout = AdaptiveMapLayout(size: size, safeAreaInsets: insets)
                let safeBounds = CGRect(x: insets.leading, y: insets.top,
                                        width: size.width - insets.leading - insets.trailing,
                                        height: size.height - insets.top - insets.bottom)
                for step in 0...200 {
                    let center = layout.point(at: Double(step) / 10)
                    // Enclose the larger hero as well as each reward target.
                    let diameter = max(50, 288 * layout.scale)
                    let target = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2,
                                        width: diameter, height: diameter)
                    XCTAssertTrue(safeBounds.contains(target), "Outside safe area at \(size), step \(step)")
                }
            }
        }
    }

    func testAdaptiveRouteFitsPhonesTabletsAndResizableWindows() {
        let sizes: [CGSize] = [
            // App Store phone canvases are portrait after the Telegram orientation decision.
            .init(width: 1_320, height: 2_868), .init(width: 1_290, height: 2_796),
            .init(width: 1_260, height: 2_736), .init(width: 1_206, height: 2_622),
            .init(width: 1_179, height: 2_556), .init(width: 1_284, height: 2_778),
            .init(width: 1_242, height: 2_688), .init(width: 1_170, height: 2_532),
            .init(width: 1_125, height: 2_436), .init(width: 1_080, height: 2_340),
            .init(width: 1_242, height: 2_208), .init(width: 750, height: 1_334),
            .init(width: 640, height: 1_136), .init(width: 600, height: 1_136),
            // iPad canvases stay landscape.
            .init(width: 2_752, height: 2_064), .init(width: 2_732, height: 2_048),
            .init(width: 2_266, height: 1_488), .init(width: 2_420, height: 1_668),
            .init(width: 2_388, height: 1_668), .init(width: 2_360, height: 1_640),
            .init(width: 2_224, height: 1_668), .init(width: 2_048, height: 1_536),
            .init(width: 2_048, height: 1_496), .init(width: 1_024, height: 768),
            .init(width: 1_024, height: 748),
            // Resizable and compact smoke sizes.
            .init(width: 320, height: 568), .init(width: 393, height: 852),
            .init(width: 440, height: 956), .init(width: 1_366, height: 1_024),
            .init(width: 744, height: 1_133), .init(width: 500, height: 400)
        ]
        for (index, canvas) in sizes.enumerated() {
            // UIKit proposes points: @3x phones, @2x older phones/Retina iPads.
            // The final two legacy iPad canvases and smoke sizes are already points.
            let displayScale: CGFloat = index < 11 ? 3 : index < 23 ? 2 : 1
            let size = CGSize(width: canvas.width / displayScale, height: canvas.height / displayScale)
            let layout = AdaptiveMapLayout(size: size)
            let bounds = CGRect(origin: .zero, size: size)
            XCTAssertGreaterThan(layout.scale, 0)
            XCTAssertGreaterThanOrEqual(layout.tiles.count, 20)
            XCTAssertTrue(layout.tiles.allSatisfy { $0.assetID.hasPrefix("map_tile_") })
            XCTAssertEqual(Set(layout.tiles.map(\.id)).count, layout.tiles.count)
            for tile in layout.tiles {
                let center = layout.screenPoint(x: tile.x + tile.width / 2, y: tile.y + tile.height / 2)
                let width = tile.renderedWidth * layout.scale
                let height = tile.renderedHeight * layout.scale
                XCTAssertTrue(bounds.contains(CGRect(x: center.x - width / 2, y: center.y - height / 2,
                                                      width: width, height: height)), "Tile clipped at \(size): \(tile.id)")
            }
            for position in [14, 20] {
                let center = layout.point(at: Double(position))
                let diameter = max(44, 269 * layout.scale)
                XCTAssertTrue(bounds.contains(CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2,
                                                      width: diameter, height: diameter)), "Reward target clipped at \(size)")
            }
            for step in 0...200 {
                let point = layout.point(at: Double(step) / 10)
                XCTAssertTrue((0...size.width).contains(point.x), "\(size): \(point)")
                XCTAssertTrue((0...size.height).contains(point.y), "\(size): \(point)")
            }
            XCTAssertEqual(layout.point(at: -1), layout.point(at: 0))
            XCTAssertEqual(layout.point(at: 21), layout.point(at: 20))
        }
        XCTAssertNotEqual(AdaptiveMapLayout(size: sizes[0]).columns, AdaptiveMapLayout(size: sizes[14]).columns)
    }

    func testVerticalStraightTilePreservesSourceAspectBeforeRotation() {
        let tile = FigmaMapTile(id: "vertical", assetID: "map_tile_2", x: 118, y: 996, width: 184, height: 249)
        XCTAssertTrue(tile.isVerticalStraight)
        // The supplied PNG is 259 x 194; shrinking it into a portrait frame breaks the route.
        XCTAssertEqual(tile.imageSize.width, 259)
        XCTAssertEqual(tile.imageSize.height, 194)
        XCTAssertEqual(tile.renderedHeight, 259)
    }

    func testMapAnchorsClampAndAnalyticsRecordsFunnelEvents() {
        let config = MapConfig(xpPerStep: 10, maxPosition: 20)
        XCTAssertEqual(config.routeAnchors.count, 21)
        XCTAssertEqual(config.anchor(at: -1), config.routeAnchors[0])
        XCTAssertEqual(config.anchor(at: 999), config.routeAnchors[20])

        let suite = UserDefaults(suiteName: #function)!
        suite.removePersistentDomain(forName: #function)
        let bus = AppEventBus()
        let analytics = AppAnalytics(eventBus: bus, defaults: suite)
        bus.post(.playTapped)
        bus.post(.firstSessionProgressUpdated(OnboardingState(
            hasCompletedFirstFoodLog: true,
            hasCompletedFirstQuest: true,
            hasOpenedFirstReward: true,
            hasEquippedFirstItem: true
        )))
        XCTAssertEqual(analytics.eventNames, ["app_opened", "play_tapped", "first_session_completed"])
    }

    func testFirstSessionFunnelSurvivesLogRolloverAndRelaunch() {
        let suite = UserDefaults(suiteName: #function)!
        suite.removePersistentDomain(forName: #function)
        defer { suite.removePersistentDomain(forName: #function) }
        let bus = AppEventBus()
        var analytics: AppAnalytics? = AppAnalytics(eventBus: bus, defaults: suite)
        bus.post(.playTapped)
        bus.post(.characterCreated)
        for _ in 0..<501 { bus.post(.appOpened) }
        XCTAssertEqual(analytics?.eventNames.count, 500)
        XCTAssertFalse(analytics!.eventNames.contains("play_tapped"))
        XCTAssertEqual(analytics?.firstSessionEventNames, ["app_opened", "play_tapped", "character_created"])
        analytics = nil
        analytics = AppAnalytics(eventBus: bus, defaults: suite)
        bus.post(.firstFoodLogged)
        let completed = OnboardingState(hasCompletedFirstFoodLog: true, hasCompletedFirstQuest: true,
                                        hasOpenedFirstReward: true, hasEquippedFirstItem: true)
        bus.post(.firstSessionProgressUpdated(completed))
        let funnel = analytics!.firstSessionEventNames
        XCTAssertEqual(funnel, ["app_opened", "play_tapped", "character_created", "first_food_logged", "first_session_completed"])
        analytics = nil
        analytics = AppAnalytics(eventBus: bus, defaults: suite)
        bus.post(.firstSessionProgressUpdated(completed))
        bus.post(.classSelected(.knight))
        XCTAssertEqual(analytics?.firstSessionEventNames, funnel)
        XCTAssertEqual(analytics!.eventNames.filter { $0 == "first_session_completed" }.count, 1)
    }
    func testAnalyticsDeliveryPerformanceWithFullHistory() {
        let suite = UserDefaults(suiteName: #function)!
        suite.removePersistentDomain(forName: #function)
        defer { suite.removePersistentDomain(forName: #function) }
        let bus = AppEventBus()
        let analytics = AppAnalytics(eventBus: bus, defaults: suite)
        for _ in 0..<500 { bus.post(.appOpened) }
        measure {
            for _ in 0..<100 { bus.post(.playTapped) }
        }
        XCTAssertEqual(analytics.eventNames.count, 500)
        XCTAssertEqual(analytics.eventNames.last, "play_tapped")
    }

}
