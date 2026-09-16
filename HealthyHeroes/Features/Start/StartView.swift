import SwiftUI

struct StartView: View {
    let router: AppRouter
    let eventBus: AppEventBus

    var body: some View {
        GeometryReader { proxy in
            let portrait = proxy.size.width < proxy.size.height
            VStack(spacing: 16) {
                DesignImageView(assetID: "start_wordmark", contentMode: .fit) {
                    Text("Healthy Heroes").font(.largeTitle.bold())
                }
                .frame(maxWidth: min(440, proxy.size.width * 0.82))
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
                    Color(red: 0.37, green: 0.79, blue: 0.94)
                    DesignImageView(assetID: portrait ? "Phone_Forest-background" : "start_scenery", contentMode: portrait ? .fill : .fit) {
                        GameDesign.green
                    }
                }
                .ignoresSafeArea()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}
