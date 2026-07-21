import SwiftUI

struct OnboardingGuideView: View {
    var body: some View {
        LandscapeGameScreen(title: "Guide", fallbackColor: Color.green.opacity(0.08)) { size in
            GamePanel {
                HStack(spacing: 24) {
                    Image(systemName: "sparkles")
                        .font(.system(size: min(90, size.height * 0.22)))
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("First Session Guide")
                            .font(.title.bold())
                        Text("Log food, complete a quest, open a reward, and equip an item.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: 480, alignment: .leading)
                }
            }
            .frame(maxWidth: min(720, size.width * 0.74), maxHeight: min(260, size.height * 0.58))
        }
    }
}
