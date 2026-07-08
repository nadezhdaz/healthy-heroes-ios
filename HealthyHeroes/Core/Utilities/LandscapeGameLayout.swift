import SwiftUI

struct LandscapeGameScreen<Content: View>: View {
    let title: String?
    let backgroundAssetID: String?
    let fallbackColor: Color
    let showsBackButton: Bool
    let content: (CGSize) -> Content

    @Environment(\.dismiss) private var dismiss

    init(
        title: String? = nil,
        backgroundAssetID: String? = nil,
        fallbackColor: Color = Color.green.opacity(0.12),
        showsBackButton: Bool = true,
        @ViewBuilder content: @escaping (CGSize) -> Content
    ) {
        self.title = title
        self.backgroundAssetID = backgroundAssetID
        self.fallbackColor = fallbackColor
        self.showsBackButton = showsBackButton
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                VStack(spacing: 12) {
                    if title != nil || showsBackButton {
                        header
                    }

                    content(proxy.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.leading, horizontalPadding(for: proxy, edgeInset: proxy.safeAreaInsets.leading))
                .padding(.trailing, horizontalPadding(for: proxy, edgeInset: proxy.safeAreaInsets.trailing))
                .padding(.top, max(12, proxy.safeAreaInsets.top + 8))
                .padding(.bottom, max(36, proxy.safeAreaInsets.bottom + 16))
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var background: some View {
        if let backgroundAssetID {
            DesignImageView(assetID: backgroundAssetID, contentMode: .fill) {
                fallbackColor
            }
            .ignoresSafeArea()
        } else {
            fallbackColor.ignoresSafeArea()
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                if showsBackButton {
                    Button {
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .labelStyle(.iconOnly)
                            .font(.headline)
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }

                Spacer()
            }

            if let title {
                Text(title)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 58)
            }
        }
        .frame(height: 44)
    }

    private func horizontalPadding(for proxy: GeometryProxy, edgeInset: CGFloat) -> CGFloat {
        max(24, edgeInset + 12, min(56, proxy.size.width * 0.035))
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
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
