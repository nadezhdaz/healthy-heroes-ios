import Combine
import SwiftUI

struct MapView: View {
    @State private var progress = ProgressState(totalXP: 0, mapPosition: 0)
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(
            backgroundAssetID: "map_background",
            backgroundContentMode: .fit,
            fallbackColor: Color(red: 0.39, green: 0.78, blue: 0.24),
            showsBackButton: true
        ) { size in
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("STEP \(progress.mapPosition)")
                            .font(GameDesign.font(18, weight: .black))
                            .foregroundStyle(GameDesign.green)
                        Text("\(progress.totalXP) XP")
                            .font(GameDesign.font(14, weight: .bold))
                            .foregroundStyle(GameDesign.green)
                        ProgressView(value: Double(progress.mapPosition), total: 20)
                            .tint(GameDesign.green)
                            .frame(width: min(220, size.width * 0.22))
                    }
                    .padding(16)
                    .background(GameDesign.cream.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.trailing, 24)
                .padding(.bottom, 18)
            }
        }
        .task {
            await load()
        }
        .onAppear {
            cancellable = eventBus.events.sink { event in
                if case .profileUpdated = event {
                    Task { @MainActor in
                        await load()
                    }
                }
            }
        }
    }

    @MainActor
    private func load() async {
        progress = (try? await profileRepository.loadProfile()?.progress)
            ?? ProgressState(totalXP: 0, mapPosition: 0)
    }
}
