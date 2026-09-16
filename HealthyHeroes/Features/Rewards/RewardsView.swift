import SwiftUI

struct RewardsView: View {
    @State private var rewards: [Reward] = []
    @State private var profile: ChildProfile?
    @State private var entries: [FoodLogEntry] = []
    @State private var errorMessage: String?

    let profileRepository: any ProfileRepository
    let rewardCatalogRepository: any RewardCatalogRepository
    let eventBus: AppEventBus
    let router: AppRouter
    let foodLogRepository: any FoodLogRepository

    var body: some View {
        LandscapeGameScreen(title: "REWARDS", backgroundAssetID: "rewards_background", titleColor: GameDesign.purple) { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button("Wardrobe") { router.show(.wardrobe) }
                        Button("Sticker Album") { router.show(.stickerAlbum) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GameDesign.green)
                    .frame(minHeight: 44)

                    Text("\(profile?.progress.totalXP ?? 0) XP earned")
                        .font(GameDesign.font(24, weight: .bold))
                    if let errorMessage {
                        Text(errorMessage)
                        Button("Retry") { Task { await load() } }
                    }
                    if rewards.isEmpty {
                        Text("Complete a quest to discover your first reward.")
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(rewards) { reward in
                            Button { router.present(.mysteryPack([reward.id])) } label: {
                                VStack(spacing: 10) {
                                    DesignImageView(assetID: reward.assetID, contentMode: .fit) {
                                        Image(systemName: "gift.fill").resizable().scaledToFit()
                                    }
                                    .frame(height: 76)
                                    Text(reward.title).font(.headline)
                                    Text(profile?.openedRewardIDs?.contains(reward.id) == true ? "View reward" : "Open gift").font(.caption)
                                }
                                .foregroundStyle(GameDesign.purple)
                                .padding(14)
                                .frame(maxWidth: .infinity, minHeight: 160)
                                .background(GameDesign.cream, in: RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("Achievements").font(.title2.bold())
                    ForEach(profile?.quests.filter { $0.status != .active } ?? []) { quest in
                        Label(quest.title, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(GameDesign.green)
                    }
                    Text("Your healthy choices").font(.title2.bold())
                    if entries.isEmpty { Text("Your progress story starts with your first healthy choice.") }
                    ForEach(entries.reversed()) { entry in
                        HStack {
                            Text(entry.customTitle ?? entry.category.title)
                            Spacer()
                            Text(entry.createdAt, format: .dateTime.month().day().hour().minute())
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(GameDesign.cream, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(4)
            }
        }
        .task { await load() }
        .onReceive(eventBus.events) { event in
            if case .profileUpdated = event { Task { await load() } }
        }
    }

    @MainActor
    private func load() async {
        do {
            profile = try await profileRepository.loadProfile()
            let unlocked = Set(profile?.unlockedRewardIDs ?? [])
            rewards = try rewardCatalogRepository.allRewards().filter { unlocked.contains($0.id) }
            entries = try await foodLogRepository.fetchEntries()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load your rewards. Please try again."
        }
    }
}
