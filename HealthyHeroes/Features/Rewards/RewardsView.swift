import Combine
import SwiftUI

struct RewardsView: View {
    @State private var rewards: [Reward] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let rewardCatalogRepository: any RewardCatalogRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(
            title: "REWARDS",
            backgroundAssetID: "rewards_background",
            fallbackColor: Color.orange.opacity(0.12),
            titleColor: GameDesign.purple
        ) { size in
            GamePanel(alignment: .leading) {
                if rewards.isEmpty {
                    GameEmptyStateView(
                        title: "No rewards yet",
                        systemImage: "gift",
                        message: "Complete quests to unlock mystery packs."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                            spacing: 12
                        ) {
                            ForEach(rewards) { reward in
                                RewardCard(reward: reward, systemImage: iconName(for: reward.type))
                            }
                        }
                    }
                }
            }
        }
        .task {
            await load()
        }
        .onAppear {
            cancellable = eventBus.events.sink { event in
                if case .rewardsUnlocked = event {
                    Task { @MainActor in
                        await load()
                    }
                }
            }
        }
    }

    @MainActor
    private func load() async {
        let unlockedIDs = (try? await profileRepository.loadProfile()?.unlockedRewardIDs) ?? []
        let allRewards = (try? rewardCatalogRepository.allRewards()) ?? []
        rewards = allRewards.filter { unlockedIDs.contains($0.id) }
    }

    private func iconName(for type: RewardType) -> String {
        switch type {
        case .wardrobeItem:
            "tshirt.fill"
        case .sticker:
            "star.square.fill"
        case .classUnlock:
            "shield.fill"
        }
    }
}

private struct RewardCard: View {
    let reward: Reward
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            DesignImageView(assetID: reward.assetID, contentMode: .fit) {
                Image(systemName: systemImage)
                    .font(.system(size: 42))
                    .foregroundStyle(GameDesign.purple)
            }
            .frame(width: 58, height: 58)
            Text(reward.title)
                .font(GameDesign.font(14, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(10)
        .background(GameDesign.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
    }
}
