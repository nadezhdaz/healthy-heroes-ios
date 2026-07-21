import SwiftUI

struct CharacterCreationView: View {
    let router: AppRouter
    let createCharacterUseCase: any CreateCharacterUseCase
    let eventBus: AppEventBus

    @State private var selectedPreset = AppearancePreset.defaults[0]
    @State private var errorMessage: String?

    var body: some View {
        LandscapeGameScreen(title: "Create Hero", fallbackColor: Color.green.opacity(0.08)) { size in
            HStack(spacing: 18) {
                GamePanel {
                    HeroPreview(appearance: selectedPreset.appearance, equippedItemIDs: [])
                        .frame(width: min(260, size.width * 0.28), height: min(300, size.height * 0.66))
                }
                .frame(width: min(360, size.width * 0.38))

                GamePanel(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Choose a look")
                            .font(.title3.bold())

                        HStack(spacing: 12) {
                            ForEach(AppearancePreset.defaults) { preset in
                                Button {
                                    selectedPreset = preset
                                } label: {
                                    VStack(spacing: 8) {
                                        HeroPreview(
                                            appearance: preset.appearance,
                                            equippedItemIDs: []
                                        )
                                        .frame(height: min(120, size.height * 0.24))
                                        Text(preset.title)
                                            .font(.caption.bold())
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(
                                        selectedPreset.id == preset.id
                                            ? Color.green.opacity(0.22)
                                            : Color.white.opacity(0.42)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(preset.title) hero appearance")
                                .accessibilityValue(
                                    selectedPreset.id == preset.id ? "Selected" : "Not selected"
                                )
                            }
                        }

                        Spacer(minLength: 0)

                        Button {
                            saveAppearance()
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(GameDesign.green)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
    }

    private func saveAppearance() {
        do {
            let profile = try createCharacterUseCase.create(appearance: selectedPreset.appearance)
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
            router.show(.classSelection)
        } catch {
            errorMessage = "Could not save this hero."
        }
    }
}

struct AppearancePreset: Identifiable, Equatable {
    let id: String
    let title: String
    let appearance: CharacterAppearance

    static let defaults: [AppearancePreset] = [
        AppearancePreset(
            id: "look-1",
            title: "Look 1",
            appearance: CharacterAppearance(
                hairStyle: "hero_head_1",
                faceStyle: "hero_face_01",
                eyesStyle: "hero_eyes_01",
                noseStyle: "hero_nose_01",
                earsStyle: "hero_ears_01"
            )
        ),
        AppearancePreset(
            id: "look-2",
            title: "Look 2",
            appearance: CharacterAppearance(
                hairStyle: "hero_head_2",
                faceStyle: "hero_face_01",
                eyesStyle: "hero_eyes_02",
                noseStyle: "hero_nose_02",
                earsStyle: "hero_ears_01"
            )
        ),
        AppearancePreset(
            id: "look-3",
            title: "Look 3",
            appearance: CharacterAppearance(
                hairStyle: "hero_head_3",
                faceStyle: "hero_face_01",
                eyesStyle: "hero_eyes_03",
                noseStyle: "hero_nose_03",
                earsStyle: "hero_ears_01"
            )
        )
    ]
}

struct HeroPreview: View {
    let appearance: CharacterAppearance
    let equippedItemIDs: [WardrobeItemID]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.5))

            HeroArtwork(
                headAssetID: appearance.hairStyle,
                equippedItemIDs: equippedItemIDs
            )
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hero preview")
    }
}

private struct HeroArtwork: View {
    // The base artwork already contains a head. Show only the lower body so
    // the selected head replaces it instead of blending with it.
    private static let visibleBodyFraction: CGFloat = 0.64

    let headAssetID: String
    let equippedItemIDs: [WardrobeItemID]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                DesignImageView(assetID: "hero_body", contentMode: .fit) {
                    Image(systemName: "figure.stand")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.green)
                }
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(
                            height: proxy.size.height * Self.visibleBodyFraction
                        )
                }

                DesignImageView(assetID: headAssetID, contentMode: .fit) {
                    Color.clear
                }

                if equippedItemIDs.contains("wardrobe_leaf_cape") {
                    DesignImageView(assetID: "wardrobe_leaf_cape", contentMode: .fit) {
                        Color.clear
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
