import SwiftUI

struct StartView: View {
    @Environment(\.displayScale) private var displayScale
    let router: AppRouter
    let eventBus: AppEventBus

    var body: some View {
        GeometryReader { proxy in
            let portrait = proxy.size.width < proxy.size.height
            VStack(spacing: 16) {
                DesignImageView(assetID: "start_wordmark", contentMode: .fit) {
                    Text("Healthy Heroes").font(.largeTitle.bold())
                }
                .frame(maxWidth: min(440, 997 / displayScale, proxy.size.width * 0.82))
                .frame(height: min(200, proxy.size.height * 0.25))
                .accessibilityLabel("Healthy Heroes")

                Spacer(minLength: 12)

                Button {
                    eventBus.post(.playTapped)
                    router.show(.characterCreation)
                } label: {
                    DesignImageView(assetID: "start_play", contentMode: .fit) {
                        Image(systemName: "play.circle.fill").resizable().scaledToFit()
                    }
                    .frame(width: min(150, proxy.size.width * 0.30), height: min(150, proxy.size.height * 0.23))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Circle())
                }
                .buttonStyle(GameImageButtonStyle())
                .accessibilityLabel("Play")
                .accessibilityHint("Create your hero")

                Text("Little choices. Great adventures.")
                    .font(GameDesign.font(18, weight: .bold))
                    .foregroundStyle(GameDesign.green)
                    .padding(12)
                    .background(GameDesign.cream.opacity(0.95), in: Capsule())
            }
            .padding(.vertical, 24)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background {
                ZStack {
                    ForEach(0..<2) { index in
                        DesignImageView(assetID: index == 0 ? "start_knight" : "start_princess", contentMode: .fit) {
                            Color.clear
                        }
                        .frame(width: proxy.size.width * (portrait ? 0.35 : 0.20),
                               height: min(300, 600 / displayScale, proxy.size.height * (portrait ? 0.30 : 0.60)))
                        .position(x: proxy.size.width * (index == 0 ? 0.23 : 0.77),
                                  y: proxy.size.height * (portrait ? 0.48 : 0.62))
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .background {
                GeometryReader { backdrop in
                    DesignImageView(assetID: "start_scenery", contentMode: .fill) {
                        Color(red: 0.37, green: 0.79, blue: 0.94)
                    }
                    .frame(width: backdrop.size.width, height: backdrop.size.height)
                    .clipped()
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}
