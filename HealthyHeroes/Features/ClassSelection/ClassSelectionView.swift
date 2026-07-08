import SwiftUI

struct ClassSelectionView: View {
    let router: AppRouter
    let selectStarterClassUseCase: any SelectStarterClassUseCase
    let eventBus: AppEventBus

    @State private var selectedClass: CharacterClass = .guardian
    @State private var errorMessage: String?

    var body: some View {
        LandscapeGameScreen(title: "Choose Class", fallbackColor: Color.cyan.opacity(0.1)) { size in
            HStack(spacing: 18) {
                GamePanel {
                    DesignImageView(assetID: selectedClass.assetID, contentMode: .fit) {
                        Image(systemName: "shield.lefthalf.filled")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.green)
                    }
                    .frame(width: min(260, size.width * 0.28), height: min(250, size.height * 0.58))
                }
                .frame(width: min(360, size.width * 0.38))

                GamePanel(alignment: .leading) {
                    VStack(spacing: 12) {
                        ForEach(CharacterClass.allCases) { characterClass in
                            ClassCard(
                                characterClass: characterClass,
                                isSelected: selectedClass == characterClass
                            ) {
                                guard characterClass.isAvailableAtStart else { return }
                                selectedClass = characterClass
                            }
                        }

                        Spacer(minLength: 0)

                        Button {
                            confirm()
                        } label: {
                            Text("Confirm")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
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

    private func confirm() {
        do {
            let updatedProfile = try selectStarterClassUseCase.select(selectedClass)
            eventBus.post(.profileUpdated(updatedProfile))
            eventBus.post(.firstSessionProgressUpdated(updatedProfile.onboarding))
            router.popToRoot()
        } catch {
            errorMessage = "Choose an unlocked class to continue."
        }
    }
}

private struct ClassCard: View {
    let characterClass: CharacterClass
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                DesignImageView(assetID: characterClass.assetID, contentMode: .fit) {
                    Image(systemName: characterClass.isLocked ? "lock.fill" : "shield.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(characterClass.isLocked ? Color.secondary : Color.green)
                }
                .frame(width: 56, height: 56)
                .opacity(characterClass.isLocked ? 0.45 : 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(characterClass.title)
                        .font(.headline)
                    Text(characterClass.isLocked ? "Locked" : "Ready to play")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: characterClass.isLocked ? "lock.fill" : "checkmark.circle.fill")
                    .foregroundStyle(isSelected ? Color.green : Color.secondary)
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.18) : Color.white.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(characterClass.isLocked)
    }
}
