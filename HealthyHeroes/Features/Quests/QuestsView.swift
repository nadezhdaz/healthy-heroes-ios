import Combine
import SwiftUI

struct QuestsView: View {
    @State private var quests: [Quest] = []
    @State private var selectedTab: QuestTab = .daily
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    private var visibleQuests: [Quest] {
        quests.filter { quest in
            switch selectedTab {
            case .daily: quest.type == .daily
            case .challenges: quest.type == .challenge
            case .milestones: quest.type == .milestone
            }
        }
    }

    var body: some View {
        LandscapeGameScreen(
            backgroundAssetID: "quests_background",
            fallbackColor: GameDesign.purple,
            showsBackButton: true
        ) { _ in
            VStack(spacing: 12) {
                QuestHeader(selectedTab: $selectedTab)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(GameDesign.cream.opacity(0.94))

                    if visibleQuests.isEmpty {
                        GameEmptyStateView(
                            title: "No quests yet",
                            systemImage: "sparkles",
                            message: "Complete healthy actions to unlock quests."
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                                spacing: 16
                            ) {
                                ForEach(visibleQuests) { quest in
                                    QuestCard(quest: quest)
                                }
                            }
                            .padding(.horizontal, 28)
                            .padding(.top, 24)
                            .padding(.bottom, 24)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
        .task { await load() }
        .onAppear {
            cancellable = eventBus.events.sink { event in
                if case .profileUpdated = event {
                    Task { @MainActor in
                        await load()
                    }
                }
            }
        }
        .onDisappear {
            cancellable?.cancel()
        }
    }

    @MainActor
    private func load() async {
        quests = (try? await profileRepository.loadProfile()?.quests) ?? []
    }
}

private enum QuestTab: String, CaseIterable, Identifiable {
    case milestones = "Milestones"
    case daily = "Daily"
    case challenges = "Challenges"
    var id: String { rawValue }
}

private struct QuestHeader: View {
    @Binding var selectedTab: QuestTab

    var body: some View {
        VStack(spacing: 10) {
            Text("QUESTS")
                .font(GameDesign.font(30, weight: .black))
                .foregroundStyle(.yellow)

            HStack(spacing: 14) {
                ForEach(QuestTab.allCases) { tab in
                    Button { selectedTab = tab } label: {
                        Text(tab.rawValue)
                            .font(GameDesign.font(16, weight: .bold))
                            .foregroundStyle(tab == selectedTab ? GameDesign.green : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(tabColor(for: tab).opacity(tab == selectedTab ? 1 : 0.82))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func tabColor(for tab: QuestTab) -> Color {
        switch tab {
        case .milestones: Color.pink.opacity(0.78)
        case .daily: Color.green.opacity(0.82)
        case .challenges: Color.cyan.opacity(0.82)
        }
    }
}

private struct QuestCard: View {
    let quest: Quest

    private var iconID: String {
        switch quest.trigger {
        case .logFruit: "quest_icon_fruit"
        case .logVegetable: "quest_icon_vegetable"
        case .logWater: "quest_icon_water"
        case .logHealthyMeal: "quest_icon_meal"
        case .logAnyHealthyFood: "quest_icon_five_day"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            DesignImageView(assetID: iconID, contentMode: .fit) {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(GameDesign.green)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 8) {
                Text(quest.title)
                    .font(GameDesign.font(18, weight: .black))
                    .foregroundStyle(GameDesign.purple)
                    .lineLimit(2)

                Text("\(quest.currentProgress)/\(quest.target)")
                    .font(GameDesign.font(15, weight: .bold))
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(quest.currentProgress), total: Double(max(quest.target, 1)))
                    .tint(quest.status == .completed ? .green : GameDesign.purple)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GameDesign.cream)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 6, y: 3)
    }
}
