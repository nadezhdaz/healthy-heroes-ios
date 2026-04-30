import SwiftUI

struct CharacterCreationView: View {
    let router: AppRouter

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("Character Creation")
                .font(.title.bold())
            Text("MVP placeholder for choosing appearance options.")
                .foregroundStyle(.secondary)
            Button("Choose Class") {
                router.show(.classSelection)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .navigationTitle("Create Hero")
    }
}
