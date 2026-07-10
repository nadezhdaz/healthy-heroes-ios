import SwiftUI

struct StartView: View {
    let router: AppRouter

    var body: some View {
        LandscapeGameScreen(
            backgroundAssetID: "start_background",
            fallbackColor: Color.green.opacity(0.2),
            showsBackButton: false
        ) { size in
            // The supplied Start-screen artwork already contains the logo and Play button.
            // Keep only a transparent hit target so the artwork remains pixel-faithful.
            Button { router.show(.characterCreation) } label: {
                Color.clear
            }
            .frame(width: min(260, size.width * 0.25), height: min(220, size.height * 0.32))
            .contentShape(Rectangle())
            .offset(x: size.width * 0.06, y: size.height * 0.20)
        }
    }
}
