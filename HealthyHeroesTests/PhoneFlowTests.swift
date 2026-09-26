import XCTest
import UIKit
import SwiftUI
@testable import HealthyHeroes

@MainActor
final class PhoneFlowTests: XCTestCase {
    func testRenderFirstSessionGuidanceBeforeAndAfterCompletion() async throws {
        for completed in [false, true] {
            var profile = makeProfile(selectedClass: .knight)
            profile.onboarding.hasCompletedFirstFoodLog = completed
            profile.onboarding.hasCompletedFirstQuest = completed
            let repository = InMemoryProfileRepository(profile: profile)
            for size in [CGSize(width: 320, height: 568), CGSize(width: 1194, height: 834)] {
                let model = MainViewModel(profileRepository: repository,
                                          gameConfigRepository: StaticGameConfigRepository(quests: [makeQuest()]),
                                          eventBus: AppEventBus(), router: AppRouter())
                await model.load()
                XCTAssertEqual(model.firstSessionCTA == nil, completed)
                let controller = UIHostingController(rootView: MainView(viewModel: model).frame(width: size.width, height: size.height).ignoresSafeArea())
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
                let attachment = XCTAttachment(image: image)
                attachment.name = "guidance-\(completed ? "completed" : "first")-\(Int(size.width))x\(Int(size.height))"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    func testLaunchScreenLoadsLogoWithoutPlayAndFitsPhoneAndTablet() throws {
        let controller = try XCTUnwrap(UIStoryboard(name: "LaunchScreen", bundle: .main).instantiateInitialViewController())
        controller.loadViewIfNeeded()
        let logo = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? UIImageView }.first)
        XCTAssertNotNil(logo.image)
        XCTAssertFalse(controller.view.subviews.contains { $0 is UIButton })
        for size in [CGSize(width: 320, height: 568), CGSize(width: 440, height: 956), CGSize(width: 1366, height: 1024), CGSize(width: 852, height: 393)] {
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            XCTAssertTrue(controller.view.bounds.contains(logo.frame), "Logo clipped at \(size)")
            XCTAssertGreaterThan(logo.bounds.width, 0)
            XCTAssertGreaterThan(logo.bounds.height, 0)
            let sourceWidth = try XCTUnwrap(logo.image?.cgImage).width
            XCTAssertLessThanOrEqual(logo.bounds.width * controller.traitCollection.displayScale,
                                     CGFloat(sourceWidth), "Launch logo is enlarged beyond its source pixels")
        }
    }

    func testRenderMilestoneRewardStatuses() async throws {
        let sticker = Reward(id: "sticker_star", type: .sticker, title: "Apple Sticker", assetID: "reward_star_sticker")
        let size = CGSize(width: 320, height: 568)
        for unlocked in [false, true] {
            var quest = makeQuest(id: "milestone", rewardID: sticker.id,
                                  status: unlocked ? .rewarded : .active)
            quest.type = .milestone
            quest.title = "Choose fruit five times"
            var profile = makeProfile(quests: [quest])
            if unlocked {
                profile.unlockedRewardIDs = [sticker.id]
                profile.stickers.unlockedStickerIDs = [sticker.id]
            }
            let repository = InMemoryProfileRepository(profile: profile)
            let view = RewardsView(profileRepository: repository,
                                   rewardCatalogRepository: StaticRewardCatalogRepository(rewards: [sticker]),
                                   eventBus: AppEventBus(), router: AppRouter(), foodLogRepository: repository)
                .frame(width: size.width, height: size.height)
            let controller = UIHostingController(rootView: view)
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
            attachment.name = "milestone-reward-\(unlocked ? "unlocked" : "locked")"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testRewardCatalogMatchesWardrobeAndAlbum() throws {
        let loader = BundledConfigLoader()
        let rewards = try loader.decode([Reward].self, fileName: "rewards")
        let wardrobe = try loader.decode([WardrobeItemDefinition].self, fileName: "wardrobe_items")
        let stickers = try loader.decode([StickerDefinition].self, fileName: "stickers")
        XCTAssertEqual(Set(wardrobe.map(\.id)), Set(rewards.filter { $0.type == .wardrobeItem }.map(\.id)))
        XCTAssertEqual(Set(stickers.map(\.id)), Set(rewards.filter { $0.type == .sticker }.map(\.id)))
        for item in wardrobe {
            let reward = try XCTUnwrap(rewards.first { $0.id == item.id })
            XCTAssertEqual(item.title, reward.title)
            XCTAssertEqual(item.assetID, reward.assetID)
        }
        for sticker in stickers {
            let reward = try XCTUnwrap(rewards.first { $0.id == sticker.id })
            XCTAssertEqual(sticker.title, reward.title)
            XCTAssertEqual(sticker.assetID, reward.assetID)
        }
    }

    func testGuidanceAdvancesAndAlbumCanBeOpened() async {
        var profile = makeProfile(selectedClass: .knight)
        let repository = InMemoryProfileRepository(profile: profile)
        let router = AppRouter()
        let viewModel = MainViewModel(
            profileRepository: repository,
            gameConfigRepository: StaticGameConfigRepository(quests: [makeQuest()]),
            eventBus: AppEventBus(),
            router: router
        )
        await viewModel.load()
        XCTAssertEqual(viewModel.firstSessionCTA, "Feed your hero to make them stronger")
        viewModel.followFirstSessionCTA()
        XCTAssertEqual(router.path.last, .foodLog)
        viewModel.openStickerAlbum()
        XCTAssertEqual(router.path.last, .stickerAlbum)

        profile.onboarding.hasCompletedFirstFoodLog = true
        try? await repository.saveProfile(profile)
        await viewModel.load()
        XCTAssertEqual(viewModel.firstSessionCTA, "Finish the first quest")

        profile.onboarding.hasCompletedFirstQuest = true
        try? await repository.saveProfile(profile)
        await viewModel.load()
        XCTAssertNil(viewModel.firstSessionCTA)
        XCTAssertFalse(profile.onboarding.hasOpenedFirstReward)
        XCTAssertFalse(profile.onboarding.hasEquippedFirstItem)
        viewModel.followFirstSessionCTA()
        XCTAssertEqual(router.path.last, .stickerAlbum)
    }
}
