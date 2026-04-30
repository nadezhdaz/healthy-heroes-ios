import Combine
import SwiftUI

struct MapView: View {
    @State private var progress = ProgressState(totalXP: 0, mapPosition: 0)
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("Map Position \(progress.mapPosition)")
                .font(.title.bold())
            Text("\(progress.totalXP) total XP")
                .foregroundStyle(.secondary)
            ProgressView(value: Double(progress.mapPosition), total: 20)
                .padding(.horizontal)
        }
        .padding(24)
        .navigationTitle("Map")
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
        progress = (try? profileRepository.loadProfile()?.progress)
            ?? ProgressState(totalXP: 0, mapPosition: 0)
    }
}
