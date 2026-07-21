import SwiftUI

struct StartView: View {
    let router: AppRouter

    var body: some View {
        GeometryReader { proxy in
            let artworkSize = fittedArtworkSize(in: proxy.size)

            ZStack {
                DesignImageView(assetID: "start_background", contentMode: .fill) {
                    Color.green.opacity(0.2)
                }
                .scaleEffect(1.08)
                .blur(radius: 22)
                .overlay(GameDesign.green.opacity(0.1))
                .allowsHitTesting(false)

                Button {
                    router.show(.characterCreation)
                } label: {
                    DesignImageView(assetID: "start_background", contentMode: .fit) {
                        Color.green.opacity(0.2)
                    }
                        .frame(width: artworkSize.width, height: artworkSize.height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .zIndex(1)
                .accessibilityLabel("Play")
                .accessibilityHint("Create your hero")
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private func fittedArtworkSize(in containerSize: CGSize) -> CGSize {
        let artworkAspectRatio = 4.0 / 3.0
        let containerAspectRatio = containerSize.width / containerSize.height

        if containerAspectRatio > artworkAspectRatio {
            return CGSize(
                width: containerSize.height * artworkAspectRatio,
                height: containerSize.height
            )
        }

        return CGSize(
            width: containerSize.width,
            height: containerSize.width / artworkAspectRatio
        )
    }
}
