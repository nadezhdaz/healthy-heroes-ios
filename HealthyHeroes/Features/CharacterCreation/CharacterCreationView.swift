import SwiftUI

struct CharacterCreationView: View {
    let router: AppRouter
    let createCharacterUseCase: any CreateCharacterUseCase
    let eventBus: AppEventBus

    @State private var appearance = CharacterAppearance()
    @State private var selectedCategory = CharacterCustomizationCategory.base
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        LandscapeGameScreen(title: "Create Hero", fallbackColor: Color.green.opacity(0.08)) { size in
            let portrait = size.width < 600
            let layout = portrait ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 18))
            layout {
                GamePanel {
                    HeroPreview(appearance: appearance, equippedItemIDs: [])
                        .frame(
                            width: portrait ? min(240, size.width * 0.7) : min(280, size.width * 0.30),
                            height: portrait ? max(100, min(220, size.height * 0.29)) : min(320, size.height * 0.70)
                        )
                }
                .frame(width: portrait ? size.width : min(360, size.width * 0.38))
                .frame(height: portrait ? max(130, min(250, size.height * 0.34)) : nil)

                GamePanel(alignment: .leading) {
                    customizationPanel
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

    private var customizationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Customize your hero")
                .font(.title3.bold())

            categoryPicker

            HStack {
                Text(selectedCategory.title)
                    .font(.headline)
                Spacer()
                Text("Choose an option")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            optionPicker

            Spacer(minLength: 0)

            Button {
                Task {
                    await saveAppearance()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSaving ? "Saving…" : "Continue")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(GameDesign.green)
            .disabled(isSaving)
            .accessibilityHint("Saves this appearance and opens class selection")
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CharacterCustomizationCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedCategory = category
                        }
                    } label: {
                        Label(category.title, systemImage: category.systemImage)
                            .font(.caption.bold())
                            .lineLimit(1)
                            .padding(.horizontal, 11)
                            .frame(minHeight: 40)
                            .background(
                                selectedCategory == category
                                    ? GameDesign.green.opacity(0.22)
                                    : Color.white.opacity(0.48)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(
                        selectedCategory == category ? "Selected" : "Not selected"
                    )
                }
            }
        }
    }

    private var optionPicker: some View {
        let options = CharacterCustomizationCatalog.options(
            for: selectedCategory,
            baseStyle: appearance.baseStyle
        )
        let selectedOptionID = CharacterCustomizationCatalog.selectedOptionID(
            for: selectedCategory,
            appearance: appearance
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(options) { option in
                    let previewAppearance = CharacterCustomizationCatalog.previewAppearance(
                        for: option,
                        category: selectedCategory,
                        currentAppearance: appearance
                    )

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            appearance = previewAppearance
                        }
                    } label: {
                        CharacterOptionCard(
                            option: option,
                            category: selectedCategory,
                            appearance: previewAppearance,
                            isSelected: option.id == selectedOptionID
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "\(selectedCategory.title) \(option.title)"
                    )
                    .accessibilityValue(
                        option.id == selectedOptionID ? "Selected" : "Not selected"
                    )
                }
            }
        }
        .frame(height: 108)
    }

    private func saveAppearance() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let profile = try await createCharacterUseCase.create(appearance: appearance)
            eventBus.post(.characterCreated)
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
            router.show(.classSelection)
        } catch {
            errorMessage = "Could not save this hero."
        }
    }
}

private struct CharacterOptionCard: View {
    let option: CharacterCustomizationOption
    let category: CharacterCustomizationCategory
    let appearance: CharacterAppearance
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                HeroFaceThumbnail(appearance: appearance)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(GameDesign.green, .white)
                        .padding(4)
                }
            }
            .frame(height: 76)

            Text(option.title)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(width: category == .base ? 116 : 92, height: 104)
        .background(
            isSelected
                ? GameDesign.green.opacity(0.22)
                : Color.white.opacity(0.50)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isSelected ? GameDesign.green : Color.clear,
                    lineWidth: 2
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct HeroPreview: View {
    let appearance: CharacterAppearance
    let equippedItemIDs: [WardrobeItemID]
    let selectedClass: CharacterClass?

    init(
        appearance: CharacterAppearance,
        equippedItemIDs: [WardrobeItemID],
        selectedClass: CharacterClass? = nil
    ) {
        self.appearance = appearance
        self.equippedItemIDs = equippedItemIDs
        self.selectedClass = selectedClass
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.5))

            HeroArtwork(
                appearance: appearance,
                equippedItemIDs: equippedItemIDs,
                selectedClass: selectedClass
            )
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hero preview")
    }
}

private struct HeroFaceThumbnail: View {
    let appearance: CharacterAppearance

    var body: some View {
        GeometryReader { proxy in
            let artworkWidth = proxy.size.width * 1.68
            let artworkHeight = artworkWidth * HeroArtwork.canvasAspectHeight

            HeroArtwork(appearance: appearance, equippedItemIDs: [])
                .frame(width: artworkWidth, height: artworkHeight)
                .position(
                    x: proxy.size.width / 2,
                    y: artworkHeight / 2
                )
        }
        .background(Color.white.opacity(0.34))
        .clipped()
    }
}

struct HeroArtwork: View {
    static let canvasAspectHeight: CGFloat = 2_632 / 2_500

    let appearance: CharacterAppearance
    let equippedItemIDs: [WardrobeItemID]
    let selectedClass: CharacterClass?

    init(
        appearance: CharacterAppearance,
        equippedItemIDs: [WardrobeItemID],
        selectedClass: CharacterClass? = nil
    ) {
        self.appearance = appearance
        self.equippedItemIDs = equippedItemIDs
        self.selectedClass = selectedClass
    }

    var body: some View {
        GeometryReader { proxy in
            let canvasWidth = min(
                proxy.size.width,
                proxy.size.height / Self.canvasAspectHeight
            )
            let canvasHeight = canvasWidth * Self.canvasAspectHeight

            ZStack(alignment: .top) {
                squareLayer(
                    assetID: bodyAssetID,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )
                squareLayer(
                    assetID: appearance.faceStyle,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )
                canvasLayer(
                    assetID: appearance.browsStyle,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )
                canvasLayer(
                    assetID: appearance.eyesStyle,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )
                canvasLayer(
                    assetID: appearance.noseStyle,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )
                canvasLayer(
                    assetID: appearance.mouthStyle,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )

                ForEach(selectedClass?.starterClothingAssetIDs ?? [], id: \.self) { assetID in
                    canvasLayer(
                        assetID: assetID,
                        canvasWidth: canvasWidth,
                        canvasHeight: canvasHeight
                    )
                }

                canvasLayer(
                    assetID: appearance.hairStyle,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )

                ForEach(selectedClass?.starterAccessoryAssetIDs ?? [], id: \.self) { assetID in
                    canvasLayer(
                        assetID: assetID,
                        canvasWidth: canvasWidth,
                        canvasHeight: canvasHeight
                    )
                }

                if equippedItemIDs.contains("wardrobe_leaf_cape") {
                    squareLayer(
                        assetID: "wardrobe_leaf_cape",
                        canvasWidth: canvasWidth,
                        canvasHeight: canvasHeight
                    )
                }
            }
            .frame(width: canvasWidth, height: canvasHeight, alignment: .top)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1 / Self.canvasAspectHeight, contentMode: .fit)
    }

    private var bodyAssetID: String {
        selectedClass == nil ? "hero_body_no_head" : "hero_body_nude_no_head"
    }

    private func squareLayer(
        assetID: String,
        canvasWidth: CGFloat,
        canvasHeight: CGFloat
    ) -> some View {
        DesignImageView(assetID: assetID, contentMode: .fit) {
            Color.clear
        }
        .frame(width: canvasWidth, height: canvasWidth)
        .frame(width: canvasWidth, height: canvasHeight, alignment: .top)
    }

    private func canvasLayer(
        assetID: String,
        canvasWidth: CGFloat,
        canvasHeight: CGFloat
    ) -> some View {
        DesignImageView(assetID: assetID, contentMode: .fit) {
            Color.clear
        }
        .frame(width: canvasWidth, height: canvasHeight)
    }
}
