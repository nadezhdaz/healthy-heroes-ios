import SwiftUI

struct ClassSelectionView: View {
    private static let gridColumns = Array(
        repeating: GridItem(.flexible(minimum: 88), spacing: 12),
        count: 4
    )

    let router: AppRouter
    let selectStarterClassUseCase: any SelectStarterClassUseCase
    let eventBus: AppEventBus

    @State private var selectedClass: CharacterClass = .knight
    @State private var errorMessage: String?

    var body: some View {
        LandscapeGameScreen(
            title: "Which Hero Are You?",
            backgroundAssetID: "classes_background",
            fallbackColor: Color.cyan.opacity(0.1)
        ) { size in
            let cardHeight = max(92, min(132, size.height * 0.24))

            VStack(spacing: 10) {
                ScrollView {
                    LazyVGrid(columns: Self.gridColumns, spacing: 10) {
                        ForEach(CharacterClass.allCases) { characterClass in
                            ClassCard(
                                characterClass: characterClass,
                                isSelected: selectedClass == characterClass,
                                height: cardHeight
                            ) {
                                selectedClass = characterClass
                                errorMessage = nil
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)

                HStack(spacing: 16) {
                    Text("Knight and Princess are ready. More heroes unlock later.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Button {
                        Task {
                            await confirm()
                        }
                    } label: {
                        Text("Choose \(selectedClass.title)")
                            .font(.headline)
                            .frame(minWidth: 160, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GameDesign.green)
                    .accessibilityHint("Saves this class and continues")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
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

    private func confirm() async {
        do {
            let updatedProfile = try await selectStarterClassUseCase.select(selectedClass)
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
    let height: CGFloat
    let action: () -> Void

    private var borderColor: Color {
        if isSelected {
            return GameDesign.green
        }
        return characterClass.isLocked ? Color.secondary.opacity(0.35) : Color.white.opacity(0.8)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    DesignImageView(assetID: characterClass.assetID, contentMode: .fit) {
                        Image(systemName: characterClass.isLocked ? "lock.fill" : "shield.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(characterClass.isLocked ? Color.secondary : GameDesign.green)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(characterClass.isLocked ? 0.48 : 1)

                    if characterClass.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(Color.black.opacity(0.64), in: Circle())
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(GameDesign.green)
                            .background(.white, in: Circle())
                    }
                }

                Text(characterClass.title)
                    .font(GameDesign.font(14, weight: .bold))
                    .foregroundStyle(characterClass.isLocked ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(characterClass.isLocked ? "Locked" : (isSelected ? "Selected" : "Ready"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(characterClass.isLocked ? Color.secondary : GameDesign.green)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .background(GameDesign.cream.opacity(characterClass.isLocked ? 0.78 : 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1.5)
            }
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(characterClass.isLocked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(characterClass.title)
        .accessibilityValue(
            characterClass.isLocked ? "Locked" : (isSelected ? "Selected" : "Available")
        )
        .accessibilityHint(characterClass.isLocked ? "Unlocks later" : "Selects this class")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
