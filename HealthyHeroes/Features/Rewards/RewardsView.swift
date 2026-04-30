import Combine
import SwiftUI

struct RewardsView: View {
    @State private var rewards: [Reward] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let rewardCatalogRepository: any RewardCatalogRepository
    let eventBus: AppEventBus

    var body: some View {
        List(rewards) { reward in
            Label(reward.title, systemImage: iconName(for: reward.type))
        }
        .overlay {
            if rewards.isEmpty {
                EmptyStateView(
                    title: "No rewards yet",
                    systemImage: "gift",
                    message: "Complete quests to unlock mystery packs."
                )
            }
        }
        .navigationTitle("Rewards")
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

private struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
