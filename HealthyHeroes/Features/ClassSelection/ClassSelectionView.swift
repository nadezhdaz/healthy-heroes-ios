import SwiftUI

struct ClassSelectionView: View {
    let router: AppRouter
    let selectStarterClassUseCase: any SelectStarterClassUseCase
    let eventBus: AppEventBus

    @State private var errorMessage: String?

    var body: some View {
        List(CharacterClass.allCases) { characterClass in
            Button {
                do {
                    let updatedProfile = try selectStarterClassUseCase.select(characterClass)
                    eventBus.post(.profileUpdated(updatedProfile))
                    eventBus.post(.firstSessionProgressUpdated(updatedProfile.onboarding))
                    router.popToRoot()
                } catch {
                    errorMessage = "Could not save class choice."
                }
            } label: {
                Label(characterClass.title, systemImage: "shield.lefthalf.filled")
            }
        }
        .navigationTitle("Choose Class")
        .overlay(alignment: .bottom) {
            if let errorMessage {
                Text(errorMessage)
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
    }
}
