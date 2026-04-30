import SwiftUI

struct StartView: View {
    let router: AppRouter

    var body: some View {
        VStack(spacing: 20) {
            Text("Healthy Heroes")
                .font(.largeTitle.bold())
            Text("Build helpful food habits with a parent-assisted hero journey.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Create Hero") {
                router.show(.characterCreation)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .navigationTitle("Start")
    }
}
