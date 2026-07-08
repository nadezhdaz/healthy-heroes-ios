import Combine
import SwiftUI

struct RewardsView: View {
    @State private var rewards: [Reward] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let rewardCatalogRepository: any RewardCatalogRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(title: "Rewards", fallbackColor: Color.green.opacity(0.08)) { _ in
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
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
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
            load()
        }
        .onAppear {
            cancellable = eventBus.events.sink { event in
                if case .rewardsUnlocked = event {
                    load()
                }
            }
        }
    }

    private func load() {
        let unlockedIDs = (try? profileRepository.loadProfile()?.unlockedRewardIDs) ?? []
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
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundStyle(.green)
            Text(reward.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 128)
        .padding(14)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
