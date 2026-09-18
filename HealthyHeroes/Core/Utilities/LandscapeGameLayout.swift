import SwiftUI

struct GameImageButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .brightness(configuration.isPressed ? -0.08 : 0)
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

enum GameDesign {
    static let cream = Color(red: 0.99, green: 0.96, blue: 0.78)
    static let green = Color(red: 0.25, green: 0.55, blue: 0.12)
    static let purple = Color(red: 0.43, green: 0.30, blue: 0.90)
    static let cornerRadius: CGFloat = 22

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("MPLUSRounded1c-\(weight.fontName)", size: size)
    }
}

private extension Font.Weight {
    var fontName: String {
        switch self {
        case .black: return "Black"
        case .heavy: return "Black"
        case .bold: return "Bold"
        case .semibold, .medium: return "Bold"
        default: return "Regular"
        }
    }
}

struct LandscapeGameScreen<Content: View>: View {
    let title: String?
    let backgroundAssetID: String?
    let backgroundContentMode: ContentMode
    let fallbackColor: Color
    let titleColor: Color
    let showsBackButton: Bool
    let content: (CGSize) -> Content

    @Environment(\.dismiss) private var dismiss

    init(
        title: String? = nil,
        backgroundAssetID: String? = nil,
        backgroundContentMode: ContentMode = .fill,
        fallbackColor: Color = Color.green.opacity(0.12),
        titleColor: Color = .primary,
        showsBackButton: Bool = true,
        @ViewBuilder content: @escaping (CGSize) -> Content
    ) {
        self.title = title
        self.backgroundAssetID = backgroundAssetID
        self.backgroundContentMode = backgroundContentMode
        self.fallbackColor = fallbackColor
        self.titleColor = titleColor
        self.showsBackButton = showsBackButton
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear.background { screenBackdrop }

                if backgroundContentMode == .fit {
                    fittedBackground(in: proxy)
                }

                VStack(spacing: 10) {
                    if title != nil || showsBackButton {
                        header
                    }

                    GeometryReader { contentProxy in
                        content(contentProxy.size)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
                .padding(.leading, horizontalPadding(for: proxy, edgeInset: proxy.safeAreaInsets.leading))
                .padding(.trailing, horizontalPadding(for: proxy, edgeInset: proxy.safeAreaInsets.trailing))
                .padding(.top, verticalTopPadding(for: proxy))
                .padding(.bottom, verticalBottomPadding(for: proxy))
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var screenBackdrop: some View {
        ZStack {
            fallbackColor

            if let backgroundAssetID {
                if backgroundContentMode == .fit {
                    DesignImageView(assetID: backgroundAssetID, contentMode: .fill) {
                        fallbackColor
                    }
                    .scaleEffect(1.08)
                    .blur(radius: 22)
                    .overlay(GameDesign.green.opacity(0.10))
                } else {
                    DesignImageView(assetID: backgroundAssetID, contentMode: .fill) {
                        fallbackColor
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func fittedBackground(in proxy: GeometryProxy) -> some View {
        if let backgroundAssetID {
            DesignImageView(assetID: backgroundAssetID, contentMode: .fit) {
                fallbackColor
            }
            .frame(
                width: min(proxy.size.width, proxy.size.height * 4 / 3),
                height: proxy.size.height
            )
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                if showsBackButton {
                    Button {
                        dismiss()
                    } label: {
                        DesignImageView(assetID: "back_button", contentMode: .fit) {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                        .frame(width: 54, height: 54)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }

                Spacer()
            }

            if let title {
                Text(title)
                    .font(GameDesign.font(28, weight: .black))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 58)
            }
        }
        .frame(height: 54)
    }

    private func horizontalPadding(for proxy: GeometryProxy, edgeInset: CGFloat) -> CGFloat {
        max(12, edgeInset + 8, min(40, proxy.size.width * 0.025))
    }

    private func verticalTopPadding(for proxy: GeometryProxy) -> CGFloat {
        max(6, proxy.safeAreaInsets.top + 4)
    }

    private func verticalBottomPadding(for proxy: GeometryProxy) -> CGFloat {
        // GeometryReader already receives the keyboard-reduced safe-area height.
        10
    }
}

struct GamePanel<Content: View>: View {
    let alignment: Alignment
    let content: () -> Content

    init(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(18)
            .background(GameDesign.cream.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: GameDesign.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
    }
}

struct GameEmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(18)
    }
}
