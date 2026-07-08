import Combine
import SwiftUI

struct QuestsView: View {
    @State private var quests: [Quest] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(title: "Quests", fallbackColor: Color.green.opacity(0.08)) { _ in
            GamePanel(alignment: .leading) {
                if quests.isEmpty {
                    GameEmptyStateView(
                        title: "No quests",
                        systemImage: "checklist",
                        message: "Quests will appear here."
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
                            ForEach(quests) { quest in
                                QuestCard(quest: quest)
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
                if case .profileUpdated = event {
                    load()
                }
            }
        }
    }

    private func load() {
        quests = (try? profileRepository.loadProfile()?.quests) ?? []
    }
}

private struct QuestCard: View {
    let quest: Quest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quest.title)
                .font(.headline)
                .lineLimit(2)
            ProgressView(value: Double(quest.currentProgress), total: Double(quest.target))
                .tint(.green)
            Text("\(quest.currentProgress)/\(quest.target) - \(quest.status.rawValue)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
