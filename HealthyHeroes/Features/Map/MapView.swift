import Combine
import SwiftUI

struct MapView: View {
    @State private var progress = ProgressState(totalXP: 0, mapPosition: 0)
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(
            title: "Map",
            backgroundAssetID: "map_background",
            fallbackColor: Color.green.opacity(0.1)
        ) { size in
            GamePanel {
                HStack(spacing: 22) {
                    Image(systemName: "map.fill")
                        .font(.system(size: min(82, size.height * 0.18)))
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Map Position \(progress.mapPosition)")
                            .font(.title2.bold())
                            .lineLimit(1)
                        Text("\(progress.totalXP) total XP")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        ProgressView(value: Double(progress.mapPosition), total: 20)
                            .tint(.green)
                    }
                    .frame(maxWidth: 440, alignment: .leading)
                }
            }
            .frame(maxWidth: min(620, size.width * 0.64), maxHeight: min(190, size.height * 0.48))
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
        progress = (try? profileRepository.loadProfile()?.progress)
            ?? ProgressState(totalXP: 0, mapPosition: 0)
    }
}
