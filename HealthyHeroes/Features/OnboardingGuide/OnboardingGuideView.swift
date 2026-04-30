import SwiftUI

struct OnboardingGuideView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("First Session Guide")
                .font(.title.bold())
            Text("Log food, complete a quest, open a reward, and equip an item.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .navigationTitle("Guide")
    }
}
