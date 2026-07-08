import SwiftUI

struct StartView: View {
    let router: AppRouter

    var body: some View {
        LandscapeGameScreen(
            backgroundAssetID: "start_background",
            fallbackColor: Color.green.opacity(0.2),
            showsBackButton: false
        ) { size in
            HStack(spacing: 44) {
                DesignImageView(assetID: "start_logo", contentMode: .fit) {
                    Text("Healthy Heroes")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.green)
                }
                .frame(width: min(380, size.width * 0.38), height: min(210, size.height * 0.48))

                Button {
                    router.show(.characterCreation)
                } label: {
                    Text("Play")
                        .font(.title2.bold())
                        .frame(maxWidth: 220, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}
