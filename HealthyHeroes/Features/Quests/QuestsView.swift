import Combine
import SwiftUI

struct QuestsView: View {
    @State private var quests: [Quest] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        List(quests) { quest in
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.headline)
                ProgressView(value: Double(quest.currentProgress), total: Double(quest.target))
                Text("\(quest.currentProgress)/\(quest.target) • \(quest.status.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Quests")
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
