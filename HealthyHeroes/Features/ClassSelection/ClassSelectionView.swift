import SwiftUI

struct ClassSelectionView: View {
    let router: AppRouter

    var body: some View {
        List(CharacterClass.allCases) { characterClass in
            Button {
                router.popToRoot()
            } label: {
                Label(characterClass.title, systemImage: "shield.lefthalf.filled")
            }
        }
        .navigationTitle("Choose Class")
    }
}
