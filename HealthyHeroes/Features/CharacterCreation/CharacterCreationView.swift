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
            id: "bright",
            title: "Bright",
            appearance: CharacterAppearance(
                hairStyle: "hero_head_1",
                faceStyle: "hero_face_01",
                eyesStyle: "hero_eyes_01",
                noseStyle: "hero_nose_01",
                earsStyle: "hero_ears_01"
            )
        ),
        AppearancePreset(
            id: "bold",
            title: "Bold",
            appearance: CharacterAppearance(
                hairStyle: "hero_head_2",
                faceStyle: "hero_face_01",
                eyesStyle: "hero_eyes_02",
                noseStyle: "hero_nose_02",
                earsStyle: "hero_ears_01"
            )
        ),
        AppearancePreset(
            id: "calm",
            title: "Calm",
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

            VStack(spacing: -24) {
                DesignImageView(assetID: appearance.hairStyle, contentMode: .fit) {
                    DesignImageView(assetID: "hero_head_1", contentMode: .fit) {
                        Image(systemName: "face.smiling.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.yellow)
                    }
                }
                .frame(height: 104)

                ZStack(alignment: .top) {
                    DesignImageView(assetID: "hero_body", contentMode: .fit) {
                        Image(systemName: "figure.stand")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.green)
                    }

                    if equippedItemIDs.contains("wardrobe_leaf_cape") {
                        DesignImageView(assetID: "wardrobe_leaf_cape", contentMode: .fit) {
                            Image(systemName: "leaf.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.green)
                        }
                        .frame(width: 82, height: 82)
                        .offset(y: -4)
                    }
                }
                .frame(height: 160)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
