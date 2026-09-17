import SwiftUI

struct MapView: View {
    @State private var progress = ProgressState(totalXP: 0, mapPosition: 0)
    @State private var mapConfig = MapConfig(xpPerStep: 10, maxPosition: 20)
    @State private var selectedNode: MapNode?
    @State private var isLoaded = false
    @State private var errorMessage: String?
    @State private var displayedPosition: Double = 0
    @State private var positionStorageKey: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let profileRepository: any ProfileRepository
    let mapConfigRepository: any GameConfigRepository
    let eventBus: AppEventBus

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                GameDesign.green.ignoresSafeArea()
                if isLoaded {
                    AdaptiveMapScene(progress: progress, displayedPosition: displayedPosition, config: mapConfig, safeAreaInsets: proxy.safeAreaInsets, selectedNode: $selectedNode)
                        .ignoresSafeArea()
                }
                if let errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage).multilineTextAlignment(.center)
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: 44)
                    }
                    .padding(24)
                    .background(GameDesign.cream, in: RoundedRectangle(cornerRadius: 20))
                    .padding(24)
                } else if !isLoaded {
                    ProgressView("Loading your map…")
                }

                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.25), in: Circle())
                        }
                        .accessibilityLabel("Back")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("STEP \(progress.mapPosition)/\(mapConfig.maxPosition)")
                                .font(GameDesign.font(16, weight: .black))
                            Text("\(progress.totalXP) XP")
                                .font(GameDesign.font(13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
                        .opacity(isLoaded ? 1 : 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert(item: $selectedNode) { node in
            Alert(title: Text(node.title), message: Text(node.message), dismissButton: .default(Text("OK")))
        }
        .task { await load() }
        .task(id: isLoaded ? progress.mapPosition : nil) {
            guard isLoaded, let positionStorageKey else { return }
            do {
                try await Self.showProgress(position: progress.mapPosition, storageKey: positionStorageKey,
                                            reduceMotion: reduceMotion) { displayedPosition = $0 }
            } catch is CancellationError {
                // Leaving or receiving newer progress preserves the last finished movement.
            } catch {
                errorMessage = "Could not show your map progress. Please try again."
            }
        }
        .onReceive(eventBus.events) { event in
            if case let .profileUpdated(profile) = event {
                progress = profile.progress
            }
        }
    }

    @MainActor
    private func load() async {
        do {
            let config = try mapConfigRepository.mapConfig()
            guard let profile = try await profileRepository.loadProfile() else {
                throw UseCaseError.missingProfile
            }
            mapConfig = config
            progress = profile.progress
            let key = "healthyHeroes.map.lastViewedPosition.\(profile.id)"
            positionStorageKey = key
            displayedPosition = Double(min(profile.progress.mapPosition, max(0, UserDefaults.standard.integer(forKey: key))))
            errorMessage = nil
            isLoaded = true
        } catch is CancellationError {
            // Leaving early keeps the previous position so unseen progress can replay.
        } catch {
            errorMessage = "Could not load your map progress. Please try again."
        }
    }

    @MainActor
    static func showProgress(position: Int, storageKey: String, reduceMotion: Bool,
                             defaults: UserDefaults = .standard, display: (Double) -> Void) async throws {
        // Mount the route before starting either initial or live progress movement.
        try await Task.sleep(for: .milliseconds(100))
        display(Double(position))
        if !reduceMotion { try await Task.sleep(for: .milliseconds(1_200)) }
        try Task.checkCancellation()
        defaults.set(position, forKey: storageKey)
    }
}

struct FigmaMapTile: Identifiable {
    let id: String
    let assetID: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    var renderedWidth: CGFloat { needsBleed ? width + 10 : width }
    var renderedHeight: CGFloat { needsBleed ? height + 10 : height }

    var isVerticalStraight: Bool { assetID == "map_tile_2" && height > width }
    var imageSize: CGSize {
        isVerticalStraight
            ? CGSize(width: renderedHeight, height: renderedWidth)
            : CGSize(width: renderedWidth, height: renderedHeight)
    }

    private var needsBleed: Bool {
        ["map_tile_1", "map_tile_2", "map_tile_7", "map_tile_8", "map_tile_9", "map_tile_10", "map_tile_11", "map_tile_12"].contains(assetID)
    }
}

struct AdaptiveMapScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: ProgressState
    let displayedPosition: Double
    let config: MapConfig
    let safeAreaInsets: EdgeInsets
    @Binding var selectedNode: MapNode?

    var body: some View {
        GeometryReader { proxy in
            let layout = AdaptiveMapLayout(size: proxy.size, safeAreaInsets: safeAreaInsets)
            ZStack {
                DesignImageView(assetID: "map_phone_empty", contentMode: .fill) {
                    LinearGradient(
                        colors: [.init(red: 0.65, green: 0.9, blue: 0.1), .init(red: 0.15, green: 0.65, blue: 0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                // These exports contain scenery only; their transparent bodies leave
                // the route itself to the independently assembled tiles below.
                let gutter = max(0, (proxy.size.width - layout.sceneryWidth) / 2)
                HStack(spacing: 0) {
                    MapSceneryEdge(width: gutter, sceneryWidth: layout.sceneryWidth, leading: true)
                    DesignImageView(assetID: "map_phone_top", contentMode: .fit) { Color.clear }
                        .frame(width: layout.sceneryWidth, height: layout.sceneryWidth * 2556 / 1179)
                    MapSceneryEdge(width: gutter, sceneryWidth: layout.sceneryWidth, leading: false)
                }
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    .clipped()
                    .accessibilityHidden(true)
                DesignImageView(assetID: "map_phone_bottom", contentMode: .fit) { Color.clear }
                    .frame(width: layout.sceneryWidth, height: layout.sceneryWidth * 2556 / 1179)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                    .clipped()
                    .accessibilityHidden(true)
                ForEach(layout.tiles) { tile in
                    DesignImageView(assetID: tile.assetID, contentMode: .fit) { Color.clear }
                        .frame(width: tile.imageSize.width * layout.scale, height: tile.imageSize.height * layout.scale)
                        .position(layout.screenPoint(x: tile.x + tile.width / 2, y: tile.y + tile.height / 2))
                        .accessibilityHidden(true)
                }
                ForEach([14, 20], id: \.self) { position in
                    let point = layout.point(at: Double(position), maxPosition: config.maxPosition)
                    let isCompleted = position < progress.mapPosition
                    let isCurrent = position == progress.mapPosition
                    Button {
                        selectedNode = MapNode(id: position,
                            title: isCompleted ? "Path complete" : isCurrent ? "Current step" : "Upcoming reward",
                            message: isCompleted || isCurrent ? "Your hero has reached this step." : "Keep making healthy choices to unlock this node.")
                    } label: {
                        DesignImageView(assetID: position == 14 ? "map_epic_marker" : "map_simple_marker", contentMode: .fit) { Image(systemName: "star.circle.fill") }
                            .frame(width: max(44, 269 * layout.scale), height: max(44, 269 * layout.scale))
                            .opacity(isCompleted || isCurrent ? 1 : 0.65)
                            .overlay {
                                if isCurrent {
                                    Circle().strokeBorder(GameDesign.cream, lineWidth: 3)
                                }
                            }
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : isCurrent ? "location.circle.fill" : "lock.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(isCompleted ? GameDesign.green : GameDesign.purple)
                                    .background(GameDesign.cream, in: Circle())
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(GameImageButtonStyle())
                    .position(point)
                    .accessibilityLabel(isCompleted ? "Completed map node" : isCurrent ? "Current map node" : "Locked map node")
                }
                DesignImageView(assetID: "map_hero_marker", contentMode: .fit) { Image(systemName: "figure.walk.circle.fill") }
                    .frame(width: max(44, 252 * layout.scale), height: max(50, 288 * layout.scale))
                    .modifier(MapRoutePosition(position: displayedPosition, maxPosition: config.maxPosition, layout: layout))
                    .animation(reduceMotion ? nil : .linear(duration: 1.2), value: displayedPosition)
                    .allowsHitTesting(false)
                    .accessibilityLabel("Your hero, map step \(progress.mapPosition)")
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }
}

private struct MapSceneryEdge: View {
    let width: CGFloat
    let sceneryWidth: CGFloat
    let leading: Bool

    var body: some View {
        let height = sceneryWidth * 2556 / 1179
        // Only the outer 18% contains scenery without castle towers.
        let stripWidth = sceneryWidth * 0.18
        ZStack {
            ForEach(0..<Int(ceil(width / stripWidth)), id: \.self) { index in
                DesignImageView(assetID: "map_phone_top", contentMode: .fit) { Color.clear }
                    .frame(width: sceneryWidth, height: height)
                    .frame(width: stripWidth, alignment: leading ? .leading : .trailing)
                    .clipped()
                    .scaleEffect(x: index.isMultiple(of: 2) ? -1 : 1, y: 1)
                    .position(x: leading ? width - stripWidth * (CGFloat(index) + 0.5) : stripWidth * (CGFloat(index) + 0.5), y: height / 2)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

// Animate distance along the route, so turns never become straight-line shortcuts.
private struct MapRoutePosition: AnimatableModifier {
    var position: Double
    let maxPosition: Int
    let layout: AdaptiveMapLayout
    var animatableData: Double {
        get { position }
        set { position = newValue }
    }
    func body(content: Content) -> some View {
        content.position(layout.point(at: position, maxPosition: maxPosition))
    }
}

struct AdaptiveMapLayout {
    let size: CGSize
    let columns: Int
    let rows: Int
    let scale: CGFloat
    let sceneryWidth: CGFloat
    let offset: CGPoint
    let tiles: [FigmaMapTile]
    private let route: [CGPoint]
    private let distances: [CGFloat]

    init(size: CGSize, safeAreaInsets: EdgeInsets = EdgeInsets()) {
        self.size = size
        let usableWidth = max(1, size.width - safeAreaInsets.leading - safeAreaInsets.trailing)
        let usableHeight = max(1, size.height - safeAreaInsets.top - safeAreaInsets.bottom)
        // Keep roughly twenty straight tiles, rearranging them for the actual window.
        columns = min(8, max(2, Int(usableWidth / usableHeight * 4)))
        rows = max(3, Int(ceil(20.0 / Double(columns))))
        let worldWidth = CGFloat(columns * 259 + 602)
        let worldHeight = CGFloat((rows - 1) * 258 + 194)
        // Keep the castle above the route, including short landscape windows.
        sceneryWidth = min(size.width, size.height * 0.8)
        let top = max(140, sceneryWidth * 422 / 1179 + 24, safeAreaInsets.top + 80)
        let bottom = max(100, sceneryWidth * 0.24 + 16, safeAreaInsets.bottom + 30)
        let availableHeight = max(1, size.height - top - bottom)
        scale = max(0, min((usableWidth - 44) / worldWidth, availableHeight / worldHeight))
        offset = CGPoint(x: safeAreaInsets.leading + (usableWidth - worldWidth * scale) / 2, y: top + max(0, (availableHeight - worldHeight * scale) / 2))
        let left: CGFloat = 301
        let right = left + CGFloat(columns * 259)
        var pieces: [FigmaMapTile] = []
        var points: [CGPoint] = []
        for row in 0..<rows {
            let y = CGFloat(row * 258)
            for column in 0..<columns {
                pieces.append(FigmaMapTile(id: "row-\(row)-\(column)", assetID: "map_tile_2", x: left + CGFloat(column * 259) + 5, y: y + 5, width: 249, height: 184))
            }
            let goesRight = row.isMultiple(of: 2)
            points.append(CGPoint(x: goesRight ? left : right, y: y + 97))
            points.append(CGPoint(x: goesRight ? right : left, y: y + 97))
            if row < rows - 1 {
                let x = goesRight ? right : left - 261
                pieces.append(FigmaMapTile(id: "turn-\(row)-top", assetID: goesRight ? "map_tile_5" : "map_tile_3", x: x, y: y, width: 261, height: 226))
                pieces.append(FigmaMapTile(id: "turn-\(row)-bottom", assetID: goesRight ? "map_tile_4" : "map_tile_6", x: x, y: y + 226, width: 261, height: 226))
                for sample in 1...24 {
                    let angle = CGFloat(sample) / 24 * .pi
                    points.append(CGPoint(x: (goesRight ? right : left) + (goesRight ? 1 : -1) * 164 * sin(angle), y: y + 226 - 129 * cos(angle)))
                }
            }
        }
        tiles = pieces
        route = points
        var lengths: [CGFloat] = [0]
        for index in 1..<points.count {
            lengths.append(lengths[index - 1] + hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y))
        }
        distances = lengths
    }

    func screenPoint(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: offset.x + x * scale, y: offset.y + y * scale)
    }

    func point(at position: Double, maxPosition: Int = 20) -> CGPoint {
        let fraction = min(1, max(0, position / Double(max(1, maxPosition))))
        let distance = CGFloat(fraction) * (distances.last ?? 0)
        let index = distances.firstIndex(where: { $0 >= distance }) ?? distances.count - 1
        guard index > 0 else { return screenPoint(x: route[0].x, y: route[0].y) }
        let previous = index - 1
        let t = (distance - distances[previous]) / max(0.001, distances[index] - distances[previous])
        return screenPoint(x: route[previous].x + (route[index].x - route[previous].x) * t,
                           y: route[previous].y + (route[index].y - route[previous].y) * t)
    }
}

struct MapNode: Identifiable {
    let id: Int
    let title: String
    let message: String
}
