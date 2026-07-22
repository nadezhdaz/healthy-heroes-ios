import XCTest
@testable import HealthyHeroes

final class CharacterCustomizationTests: XCTestCase {
    func testBaseOptionsUseGenderLabelsWithoutChangingStoredValues() {
        let options = CharacterCustomizationCatalog.options(for: .base, baseStyle: .boy)

        XCTAssertEqual(options.map(\.title), ["Boy", "Girl"])
        XCTAssertEqual(options.map(\.id), ["type_a", "type_b"])
    }

    func testCatalogContainsEveryFaceFeatureSourceForBothBaseTypes() {
        XCTAssertEqual(
            CharacterCustomizationCatalog.assetIDs(for: .hair, baseStyle: .boy),
            ["bhairstyle_1", "bhairstyle_2", "bhairstyle_3", "bhairstyle_4"]
        )
        XCTAssertEqual(
            CharacterCustomizationCatalog.assetIDs(for: .hair, baseStyle: .girl),
            ["ghairstyle_1", "ghairstyle_2", "ghairstyle_3", "ghairstyle_4"]
        )

        let featureExpectations: [(CharacterCustomizationCategory, String)] = [
            (.brows, "brows"),
            (.eyes, "eyes"),
            (.nose, "nose"),
            (.mouth, "mouth")
        ]

        for (category, assetName) in featureExpectations {
            XCTAssertEqual(
                CharacterCustomizationCatalog.assetIDs(for: category, baseStyle: .boy),
                (1...4).map { "b_\(assetName)\($0)" }
            )
            XCTAssertEqual(
                CharacterCustomizationCatalog.assetIDs(for: category, baseStyle: .girl),
                (1...4).map { "g_\(assetName)\($0)" }
            )
        }
    }

    func testChangingBaseKeepsSelectedOptionPositions() throws {
        let appearance = CharacterAppearance(
            baseStyle: .boy,
            hairStyle: "bhairstyle_4",
            browsStyle: "b_brows3",
            eyesStyle: "b_eyes2",
            noseStyle: "b_nose4",
            mouthStyle: "b_mouth2"
        )
        let typeBOption = try XCTUnwrap(
            CharacterCustomizationCatalog.options(for: .base, baseStyle: .boy).last
        )

        let updatedAppearance = CharacterCustomizationCatalog.appearance(
            appearance,
            selecting: typeBOption,
            in: .base
        )

        XCTAssertEqual(updatedAppearance.baseStyle, .girl)
        XCTAssertEqual(updatedAppearance.hairStyle, "ghairstyle_4")
        XCTAssertEqual(updatedAppearance.browsStyle, "g_brows3")
        XCTAssertEqual(updatedAppearance.eyesStyle, "g_eyes2")
        XCTAssertEqual(updatedAppearance.noseStyle, "g_nose4")
        XCTAssertEqual(updatedAppearance.mouthStyle, "g_mouth2")
    }

    func testLegacyPresetDecodingProvidesCurrentFeatureLayers() throws {
        let data = try XCTUnwrap(
            """
            {
              "hairStyle": "hero_head_2",
              "faceStyle": "hero_face_01",
              "eyesStyle": "hero_eyes_02",
              "noseStyle": "hero_nose_03",
              "earsStyle": "hero_ears_01"
            }
            """.data(using: .utf8)
        )

        let appearance = try JSONDecoder().decode(CharacterAppearance.self, from: data)

        XCTAssertEqual(appearance.baseStyle, .boy)
        XCTAssertEqual(appearance.faceStyle, "hero_head_2")
        XCTAssertEqual(appearance.hairStyle, "bhairstyle_1")
        XCTAssertEqual(appearance.browsStyle, "b_brows1")
        XCTAssertEqual(appearance.eyesStyle, "b_eyes2")
        XCTAssertEqual(appearance.noseStyle, "b_nose3")
        XCTAssertEqual(appearance.mouthStyle, "b_mouth1")
    }

    func testClassCostumesUseTheNudeBodyAsset() {
        XCTAssertEqual(
            AssetResolver().asset(for: "hero_body_nude_no_head")?.resourceName,
            "NUDE-bolvanka-No-head"
        )

        for characterClass in CharacterClass.allCases.filter(\.isAvailableAtStart) {
            let costumeAssetIDs = characterClass.starterClothingAssetIDs
                + characterClass.starterAccessoryAssetIDs
            XCTAssertFalse(costumeAssetIDs.isEmpty)
            XCTAssertTrue(costumeAssetIDs.allSatisfy { AssetResolver().asset(for: $0) != nil })
        }
    }
}
