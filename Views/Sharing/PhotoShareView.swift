import SwiftUI
import PhotosUI
import UIKit
import Combine

// MARK: - Models

/// The output canvas shape. ImageRenderer rasterizes at 3× for export.
enum ShareAspect: String, CaseIterable, Identifiable {
    case square   = "1:1"
    case portrait = "4:5"
    case vertical = "9:16"
    case native   = "Native"

    var id: String { rawValue }

    /// In-editor preview size (points). Smaller than before (was 360pt) so
    /// the canvas doesn't dominate the screen on tall aspects and the
    /// scrollable controls still have visible room. Export scale is bumped
    /// to compensate so output stays ~1080px on the long edge.
    func previewSize(for photoAspect: CGFloat) -> CGSize {
        switch self {
        case .square:   return CGSize(width: 280, height: 280)   // → 1120×1120 at 4×
        case .portrait: return CGSize(width: 280, height: 350)   // → 1120×1400 at 4×
        case .vertical: return CGSize(width: 240, height: 427)   // → 1080×1920 at 4.5×
        case .native:
            // photoAspect = width / height; clamp to sensible bounds
            let clamped = max(0.5, min(2.0, photoAspect))
            return CGSize(width: 280, height: 280 / clamped)
        }
    }

    /// Pixel scale factor used by the rasterizer. ~4× keeps export close
    /// to 1080px on the long edge despite the smaller preview canvas.
    var exportScale: CGFloat {
        switch self {
        case .vertical: return 4.5
        default:        return 4.0
        }
    }
}

/// Which subject the share blocks describe.
enum ShareScope: Equatable {
    case wholeSession
    case singlePizza(PizzaEntry)

    // Custom == because PizzaEntry doesn't conform to Equatable.
    // Comparing by the pizza's UUID is sufficient — two scopes are
    // "the same" iff they point at the same pizza (or both are whole-session).
    static func == (lhs: ShareScope, rhs: ShareScope) -> Bool {
        switch (lhs, rhs) {
        case (.wholeSession, .wholeSession):
            return true
        case let (.singlePizza(a), .singlePizza(b)):
            return a.id == b.id
        default:
            return false
        }
    }
}

enum ShareBlockType: String, CaseIterable, Identifiable, Hashable {
    case styleMethod  = "Style & method"
    case formula      = "Formula"
    case flourBlend   = "Flour blend"
    case preferment   = "Preferment"
    case process      = "Process"
    case sessionNotes = "Notes"

    var id: String { rawValue }

    /// Emojis removed per user — block titles read cleaner without them.
    /// Keeping the property in case we want to add them back later.
    var emoji: String? { nil }
}

struct ShareBlock: Identifiable, Equatable {
    let id = UUID()
    let type: ShareBlockType
    let title: String
    let body: String
    var enabled: Bool
    /// Normalized 0…1 position within the canvas. Center anchor.
    var position: CGPoint
    /// 1.0 = default size. Adjusted by dragging the block's corner handle.
    var scale: CGFloat = 1.0
    /// Text alignment within the tile. Cycles on tap.
    var alignment: TextAlignment = .center

    /// Horizontal alignment derived from `alignment`, for VStack/HStack
    /// content positioning (title row + body match the chosen alignment).
    var hAlignment: HorizontalAlignment {
        switch alignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        case .center:   return .center
        }
    }

    /// Frame alignment value for `.frame(maxWidth:alignment:)`.
    var frameAlignment: Alignment {
        switch alignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        case .center:   return .center
        }
    }

    static func == (lhs: ShareBlock, rhs: ShareBlock) -> Bool { lhs.id == rhs.id }
}

// MARK: - Block content extractor

struct ShareBlockExtractor {
    /// Builds the block list from a BakeLog + Recipe + scope.
    /// Style & Method and Formula default to enabled; the rest default to off
    /// per the spec. Blocks with no underlying data are omitted entirely.
    /// Defaults stagger horizontally (alternating left/right of center) and
    /// vertically (yStep 0.10) so newly toggled blocks don't land underneath
    /// already-visible ones.
    static func blocks(for log: BakeLog, recipe: Recipe, scope: ShareScope) -> [ShareBlock] {
        var out: [ShareBlock] = []
        var y: CGFloat = 0.50
        let yStep: CGFloat = 0.10
        // Alternate x to keep stacked toggles visually distinct out of the box.
        var leftSide = false
        func nextX() -> CGFloat {
            defer { leftSide.toggle() }
            return leftSide ? 0.32 : 0.68
        }

        // Style & method (pre-enabled — keep centered)
        let styleName = recipe.style == .custom && !recipe.customStyleName.isEmpty
            ? recipe.customStyleName
            : recipe.style.rawValue
        let methodPart = recipe.method == .direct ? "Direct" : recipe.method.rawValue
        out.append(ShareBlock(
            type: .styleMethod,
            title: ShareBlockType.styleMethod.rawValue,
            body: "\(styleName) · \(methodPart)",
            enabled: true,
            position: CGPoint(x: 0.5, y: y)
        ))
        y += yStep

        // Formula (pre-enabled — keep centered).
        // Excluded: buffer (production detail) + ball count × weight.
        let hyd   = "\(Int(recipe.finalHydration * 100))% hydration"
        let salt  = String(format: "%.1f%% salt", recipe.saltPct * 100)
        let yeast = recipe.yeastType.rawValue.lowercased()
        out.append(ShareBlock(
            type: .formula,
            title: ShareBlockType.formula.rawValue,
            body: "\(hyd) · \(salt) · \(yeast)",
            enabled: true,
            position: CGPoint(x: 0.5, y: y)
        ))
        y += yStep

        // Remaining blocks default-off + stagger horizontally so toggling
        // a couple on doesn't land them directly underneath the centered
        // pair above.

        if !recipe.flourBlend.name.isEmpty {
            out.append(ShareBlock(
                type: .flourBlend,
                title: ShareBlockType.flourBlend.rawValue,
                body: recipe.flourBlend.name,
                enabled: false,
                position: CGPoint(x: nextX(), y: y)
            ))
            y += yStep
        }

        if recipe.method != .direct {
            let pct = Int(recipe.bigaRatio * 100)
            let body = pct > 0 ? "\(recipe.method.rawValue) · \(pct)%" : recipe.method.rawValue
            out.append(ShareBlock(
                type: .preferment,
                title: ShareBlockType.preferment.rawValue,
                body: body,
                enabled: false,
                position: CGPoint(x: nextX(), y: y)
            ))
            y += yStep
        }

        let enabledSteps = recipe.processCards.filter { $0.isEnabled }.count
        if enabledSteps > 0 {
            out.append(ShareBlock(
                type: .process,
                title: ShareBlockType.process.rawValue,
                body: "\(enabledSteps) steps",
                enabled: false,
                position: CGPoint(x: nextX(), y: y)
            ))
            y += yStep
        }

        switch scope {
        case .wholeSession:
            var parts: [String] = [starGlyphs(log.rating)]
            if log.bakeTimeSeconds > 0 { parts.append(shortTime(log.bakeTimeSeconds)) }
            if let temp = log.ovenTempAchieved { parts.append("\(Int(temp))°") }
            let body = parts.joined(separator: " · ")
            out.append(ShareBlock(
                type: .sessionNotes,
                title: "Session",
                body: body,
                enabled: false,
                position: CGPoint(x: nextX(), y: y)
            ))
        case .singlePizza(let entry):
            var parts: [String] = [starGlyphs(log.rating)]
            if entry.bakeTimeSeconds > 0 { parts.append(shortTime(entry.bakeTimeSeconds)) }
            if let temp = entry.ovenTempAchieved { parts.append("\(Int(temp))°") }
            parts.append(entry.crustColor.rawValue.lowercased())
            out.append(ShareBlock(
                type: .sessionNotes,
                title: "Bake #\(entry.pizzaNumber)",
                body: parts.joined(separator: " · "),
                enabled: false,
                position: CGPoint(x: nextX(), y: y)
            ))
        }

        return out
    }

    private static func starGlyphs(_ rating: Int) -> String {
        let r = max(0, min(5, rating))
        return String(repeating: "★", count: r) + String(repeating: "☆", count: 5 - r)
    }

    private static func shortTime(_ t: TimeInterval) -> String {
        let total = Int(t)
        let h = total / 3600; let m = (total % 3600) / 60; let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, s)
    }
}

// MARK: - Canvas (used for both preview and rasterization)

struct ShareCanvasView: View {
    @ObservedObject var editor: ShareEditorModel
    let canvasSize: CGSize
    var draggable: Bool = true

    // Snapshots taken at gesture start so consecutive pinches/pans compose.
    @State private var zoomBase: CGFloat = 1.0
    @State private var panBase: CGSize = .zero

    var body: some View {
        ZStack {
            // Background is now hit-testable (only in editor mode) so the
            // pan + pinch gestures attached to it can fire. Block tiles
            // sit ABOVE the background in the ZStack so their own taps /
            // drags still win — only touches on bare photo area reach
            // these gestures.
            background
                .allowsHitTesting(draggable)
                .if(draggable) { bg in
                    bg.gesture(
                        SimultaneousGesture(magnification, pan)
                    )
                }

            ForEach(Array(editor.blocks.enumerated()), id: \.element.id) { idx, block in
                if block.enabled {
                    DraggableShareBlock(
                        editor: editor,
                        index: idx,
                        canvasSize: canvasSize,
                        draggable: draggable
                    )
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .overlay(alignment: .bottomTrailing) {
            watermarkLabel
                .padding(.trailing, 10)
                .padding(.bottom, 8)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    @ViewBuilder
    private var background: some View {
        if let data = editor.selectedPhoto, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: canvasSize.width, height: canvasSize.height)
                // Pinch + pan: scale the image then offset it. The ZStack's
                // outer .clipped() crops overflow to the canvas frame, so
                // edges never show through.
                .scaleEffect(editor.photoZoom, anchor: .center)
                .offset(editor.photoOffset)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
        } else {
            Color(hex: "F5F1E8")
                .frame(width: canvasSize.width, height: canvasSize.height)
        }
    }

    /// Two-finger pinch to zoom. Multiplies zoomBase (snapshot at start)
    /// by the gesture's value, clamped to 1.0…3.0. onEnded snapshots the
    /// final zoom so the next pinch composes on top.
    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newZoom = max(1.0, min(3.0, zoomBase * value))
                editor.photoZoom = newZoom
                editor.photoOffset = clampOffset(panBase, zoom: newZoom)
            }
            .onEnded { _ in
                zoomBase = editor.photoZoom
                panBase = editor.photoOffset
            }
    }

    /// One-finger drag to pan the (zoomed) photo. Inert at zoom 1.0.
    /// Edge-clamped so the photo can't be moved past its own edges.
    private var pan: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard editor.photoZoom > 1.0 else { return }
                let candidate = CGSize(
                    width: panBase.width + value.translation.width,
                    height: panBase.height + value.translation.height
                )
                editor.photoOffset = clampOffset(candidate, zoom: editor.photoZoom)
            }
            .onEnded { _ in
                panBase = editor.photoOffset
            }
    }

    /// Constrain offset so the visible canvas never extends past the
    /// photo's edges. At zoom 1.0 the photo exactly fills the canvas →
    /// only valid offset is (0, 0). At zoom > 1.0 there's overhang on
    /// every side; offset can range within ±overhang.
    private func clampOffset(_ offset: CGSize, zoom: CGFloat) -> CGSize {
        let overflowX = max(0, (canvasSize.width * zoom - canvasSize.width) / 2)
        let overflowY = max(0, (canvasSize.height * zoom - canvasSize.height) / 2)
        return CGSize(
            width:  min(max(-overflowX, offset.width),  overflowX),
            height: min(max(-overflowY, offset.height), overflowY)
        )
    }

    /// "Baked with Stesura" pinned bottom-right. Not toggleable.
    /// Lives in an .overlay (NOT as a ZStack sibling sized to the canvas) so
    /// its frame can't intercept taps meant for the block tiles.
    private var watermarkLabel: some View {
        // Reverted to original (smaller) sizing per user preference.
        HStack(spacing: 3) {
            Text("Baked with")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.72))
                .tracking(0.5)
            Text("Stesura")
                .font(.system(size: 13, design: .monospaced).weight(.bold))
                .foregroundColor(.white)
                .tracking(1)
        }
        .shadow(color: .black.opacity(0.5), radius: 2.5, x: 0, y: 1)
    }
}

/// One draggable, normalized-position block tile.
/// Reads + writes through editor.blocks[index] directly — no SwiftUI
/// Binding chain, no risk of toggle/drag mutations being lost in transit.
struct DraggableShareBlock: View {
    @ObservedObject var editor: ShareEditorModel
    let index: Int
    let canvasSize: CGSize
    var draggable: Bool

    @State private var dragOrigin: CGPoint? = nil
    @State private var scaleOrigin: CGFloat? = nil

    private var block: ShareBlock {
        guard editor.blocks.indices.contains(index) else {
            // Defensive fallback for race during re-render.
            return ShareBlock(type: .styleMethod, title: "", body: "", enabled: false, position: .zero)
        }
        return editor.blocks[index]
    }

    /// The visible tile. Font sizes and padding are multiplied by
    /// block.scale so the tile's ACTUAL layout frame grows/shrinks —
    /// not just the visual rendering. Means the overlay resize handle
    /// follows the real bottom-right corner, and the tap area (the
    /// content shape) matches what the user sees.
    /// Inner content alignment follows block.alignment so the title +
    /// body both move to leading / center / trailing together.
    private var tile: some View {
        let s = block.scale
        return VStack(alignment: block.hAlignment, spacing: 3 * s) {
            HStack(spacing: 5 * s) {
                if let emoji = block.type.emoji {
                    Text(emoji).font(.system(size: 12 * s))
                }
                Text(block.title.uppercased())
                    .font(.system(size: 10 * s, design: .monospaced))
                    .tracking(1.4 * s)
                    .foregroundColor(.white.opacity(0.78))
            }
            Text(block.body)
                .font(.system(size: 13 * s, design: .monospaced).weight(.medium))
                .foregroundColor(.white)
                .multilineTextAlignment(block.alignment)
                .lineLimit(2)
        }
        .padding(.horizontal, 12 * s)
        .padding(.vertical, 8 * s)
        .background(Color.black.opacity(0.55))
        .cornerRadius(6 * s)
    }

    var body: some View {
        tile
            .contentShape(Rectangle())
            // Bottom-right resize handle. Only when draggable (editor),
            // never in the rasterized export. Anchored to the tile's
            // ACTUAL bottom-trailing corner — since the tile's frame
            // is what grew, the handle follows.
            .overlay(alignment: .bottomTrailing) {
                if draggable {
                    resizeHandle
                        .offset(x: 6, y: 6)  // half-outside the corner
                }
            }
            .offset(
                x: (block.position.x - 0.5) * canvasSize.width,
                y: (block.position.y - 0.5) * canvasSize.height
            )
            // Move gesture on the tile body. Resize handle's gesture is on
            // its own child view (on top) and wins for touches that start
            // on the handle.
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .local)
                    .onChanged { value in
                        guard draggable else { return }
                        guard editor.blocks.indices.contains(index) else { return }
                        if dragOrigin == nil { dragOrigin = editor.blocks[index].position }
                        guard let origin = dragOrigin else { return }
                        let newX = origin.x + value.translation.width / canvasSize.width
                        let newY = origin.y + value.translation.height / canvasSize.height
                        editor.blocks[index].position = CGPoint(
                            x: min(max(0.08, newX), 0.92),
                            y: min(max(0.08, newY), 0.92)
                        )
                    }
                    .onEnded { _ in dragOrigin = nil }
            )
            // Tap cycles text alignment: center → leading → trailing → center.
            // .simultaneousGesture so it doesn't block the DragGesture above.
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        guard draggable else { return }
                        guard editor.blocks.indices.contains(index) else { return }
                        editor.blocks[index].alignment = nextAlignment(editor.blocks[index].alignment)
                    }
            )
    }

    private func nextAlignment(_ current: TextAlignment) -> TextAlignment {
        switch current {
        case .center:   return .leading
        case .leading:  return .trailing
        case .trailing: return .center
        }
    }

    /// Small gold circle with a diagonal-arrow icon. Drag it diagonally
    /// to scale the tile — out for bigger, in for smaller. Clamped to
    /// 0.5×…2.5× so blocks can't disappear or eat the canvas.
    private var resizeHandle: some View {
        Circle()
            .fill(Color(hex: "D2B96A"))
            .frame(width: 18, height: 18)
            .overlay(
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .local)
                    .onChanged { value in
                        guard editor.blocks.indices.contains(index) else { return }
                        if scaleOrigin == nil { scaleOrigin = editor.blocks[index].scale }
                        guard let origin = scaleOrigin else { return }
                        // Sum dx + dy / 160 → ~+1.0 scale per 160pt diagonal.
                        let delta = (value.translation.width + value.translation.height) / 160
                        let newScale = max(0.5, min(2.5, origin + delta))
                        editor.blocks[index].scale = newScale
                    }
                    .onEnded { _ in scaleOrigin = nil }
            )
    }
}

// MARK: - Editor

/// Holds the editor's mutable state outside of SwiftUI's @State machinery.
/// @State + ForEach($collection) binding propagation was unreliable for
/// this view on iOS 26 — toggle animations completed but binding writes
/// didn't reach the underlying array. Switched to @Published on an
/// ObservableObject, which uses Combine for explicit change notification.
final class ShareEditorModel: ObservableObject {
    @Published var blocks: [ShareBlock] = []
    @Published var aspect: ShareAspect = .square
    @Published var scope: ShareScope
    @Published var selectedPhoto: Data? = nil

    /// Photo zoom inside the canvas, 1.0…3.0. 1.0 = fits the canvas
    /// per scaledToFill; > 1.0 crops tighter via pinch/spread.
    @Published var photoZoom: CGFloat = 1.0

    /// Pan offset for the (zoomed) photo within the canvas. Edge-clamped
    /// so the user can't reveal canvas background past the photo edges.
    @Published var photoOffset: CGSize = .zero

    init(scope: ShareScope) {
        self.scope = scope
    }
}

struct PhotoShareView: View {
    let log: BakeLog
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @StateObject private var editor: ShareEditorModel

    @State private var pickerItem: PhotosPickerItem?
    @State private var shareItem: SharePayload? = nil
    @State private var rendering = false
    private let isPerPizzaCapable: Bool

    init(log: BakeLog, recipe: Recipe, scope: ShareScope) {
        self.log = log
        self.recipe = recipe
        _editor = StateObject(wrappedValue: ShareEditorModel(scope: scope))
        self.isPerPizzaCapable = {
            if case .singlePizza = scope { return true }
            return !log.pizzaEntries.isEmpty
        }()
    }

    /// Cached photo aspect ratio for the .native canvas.
    private var photoAspect: CGFloat {
        guard let data = editor.selectedPhoto, let img = UIImage(data: data),
              img.size.height > 0 else { return 1.0 }
        return img.size.width / img.size.height
    }

    private var canvasSize: CGSize { editor.aspect.previewSize(for: photoAspect) }

    var body: some View {
        NavigationStack {
            // Flat VStack layout — no ZStack-for-background hack, no nested
            // VStack inside ZStack which made the ScrollView seem to scroll
            // BEHIND the canvas. Background applied via .background modifier
            // on the outer VStack. Explicit Divider + .layoutPriority give
            // SwiftUI an unambiguous answer to "what owns the screen height".
            VStack(spacing: 0) {
                aspectPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                canvasFrame
                    .layoutPriority(1)   // canvas always gets its requested height

                // Explicit visual separator so the canvas can't visually
                // bleed into the scrolling area below.
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)

                ScrollView {
                    VStack(spacing: 20) {
                        if photoIsMissing {
                            pickPhotoPrompt
                        } else {
                            HStack(spacing: 16) {
                                PhotosPicker(selection: $pickerItem, matching: .images) {
                                    Label("Replace photo", systemImage: "photo")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                if editor.photoZoom > 1.0 || editor.photoOffset != .zero {
                                    Button {
                                        editor.photoZoom = 1.0
                                        editor.photoOffset = .zero
                                    } label: {
                                        Label("Reset zoom", systemImage: "arrow.counterclockwise")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(Color(hex: "D2B96A"))
                                    }
                                }
                            }
                        }

                        if isPerPizzaCapable {
                            scopePicker
                        }

                        blockTogglesSection

                        helperFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
                .layoutPriority(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "1A1A1A").ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share →") { renderAndShare() }
                        .foregroundColor(Color(hex: "D2B96A"))
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color(hex: "1A1A1A"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if editor.blocks.isEmpty {
                editor.blocks = ShareBlockExtractor.blocks(for: log, recipe: recipe, scope: editor.scope)
            }
            if editor.selectedPhoto == nil {
                editor.selectedPhoto = log.displayPhotos.first ?? coverFromPizza()
            }
        }
        .onChange(of: editor.scope) { _, newScope in
            editor.blocks = ShareBlockExtractor.blocks(for: log, recipe: recipe, scope: newScope)
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    await MainActor.run { editor.selectedPhoto = data }
                }
            }
        }
        .sheet(item: $shareItem) { payload in
            ActivityShareSheet(items: [payload.image])
        }
    }

    private func coverFromPizza() -> Data? {
        if case .singlePizza(let entry) = editor.scope {
            return entry.displayPhotos.first
        }
        return log.pizzaEntries.flatMap(\.displayPhotos).first
    }

    private var photoIsMissing: Bool { editor.selectedPhoto == nil }

    // MARK: subviews

    private var aspectPicker: some View {
        HStack(spacing: 6) {
            ForEach(ShareAspect.allCases) { a in
                Text(a.rawValue)
                    .font(.system(size: 12, design: .monospaced).weight(editor.aspect == a ? .semibold : .regular))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(editor.aspect == a ? Color(hex: "D2B96A") : Color.white.opacity(0.08))
                    .foregroundColor(editor.aspect == a ? .black : .white.opacity(0.7))
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .onTapGesture { editor.aspect = a }
            }
        }
    }

    private var canvasFrame: some View {
        ShareCanvasView(
            editor: editor,
            canvasSize: canvasSize,
            draggable: true
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var pickPhotoPrompt: some View {
        VStack(spacing: 10) {
            Text("No photo attached to this bake.")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Pick a photo from library →")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "D2B96A"), lineWidth: 1)
                    )
            }
            Text("Won't be saved back to this bake — used for this share only.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var scopePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stats reflect")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.2)

            // Same custom segmented style as aspectPicker for consistent
            // contrast and reliable tap handling.
            let binding = scopeBinding()
            HStack(spacing: 6) {
                segmentTile(label: "Whole session", isSelected: binding.wrappedValue == 0) {
                    binding.wrappedValue = 0
                }
                ForEach(Array(log.pizzaEntries.enumerated()), id: \.offset) { idx, entry in
                    let tag = idx + 1
                    segmentTile(label: "Bake #\(entry.pizzaNumber)", isSelected: binding.wrappedValue == tag) {
                        binding.wrappedValue = tag
                    }
                }
            }
        }
    }

    /// Shared tile used by the scope segmented row. Same .onTapGesture
    /// approach as the aspect picker for hit-detection reliability.
    private func segmentTile(label: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Text(label)
            .font(.system(size: 11, design: .monospaced).weight(isSelected ? .semibold : .regular))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(isSelected ? Color(hex: "D2B96A") : Color.white.opacity(0.08))
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .cornerRadius(6)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }

    private func scopeBinding() -> Binding<Int> {
        Binding(
            get: {
                if case .singlePizza(let entry) = editor.scope,
                   let i = log.pizzaEntries.firstIndex(where: { $0.id == entry.id }) {
                    return i + 1
                }
                return 0
            },
            set: { newTag in
                if newTag == 0 {
                    editor.scope = .wholeSession
                } else if log.pizzaEntries.indices.contains(newTag - 1) {
                    editor.scope = .singlePizza(log.pizzaEntries[newTag - 1])
                }
            }
        )
    }

    @ViewBuilder
    private var blockTogglesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Blocks")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.2)
            VStack(spacing: 8) {
                // Iterate by index so we can mutate editor.blocks[i] directly
                // through the ObservableObject @Published path — no
                // intermediate SwiftUI Binding chain to potentially drop
                // the write.
                ForEach(Array(editor.blocks.enumerated()), id: \.element.id) { idx, block in
                    Toggle(isOn: Binding(
                        get: { editor.blocks[idx].enabled },
                        set: { editor.blocks[idx].enabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(block.title)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white)
                            Text(block.body)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    .tint(Color(hex: "D2B96A"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
    }

    private var helperFooter: some View {
        Text("Drag any enabled block on the canvas to reposition. The watermark is always shown.")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.white.opacity(0.4))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .tipText()
    }

    // MARK: render + share

    @MainActor
    private func renderAndShare() {
        // Render to UIImage via UIHostingController + drawHierarchy
        // (afterScreenUpdates: true). Sheet presentation is via
        // .sheet(item: $shareItem) — setting shareItem to a non-nil
        // value atomically triggers the sheet WITH the image already
        // baked into the payload. No more nil-race between setting
        // an image and toggling a boolean.
        if let image = renderViaHostingController() {
            shareItem = SharePayload(image: image)
        }
    }

    @MainActor
    private func renderViaHostingController() -> UIImage? {
        // Pre-decode the photo so it can't be caught mid-load.
        if let data = editor.selectedPhoto {
            _ = UIImage(data: data)?.preparingForDisplay()
        }

        let canvas = ShareCanvasView(
            editor: editor,
            canvasSize: canvasSize,
            draggable: false
        )
        .frame(width: canvasSize.width, height: canvasSize.height)
        .environment(\.colorScheme, .light)

        let controller = UIHostingController(rootView: canvas)
        let bounds = CGRect(origin: .zero, size: canvasSize)
        controller.view.bounds = bounds
        controller.view.backgroundColor = .clear

        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: { $0.isKeyWindow })
                ?? scene.windows.first
        else { return nil }

        controller.view.frame = CGRect(
            x: 0,
            y: window.bounds.height + 10,
            width: canvasSize.width,
            height: canvasSize.height
        )
        window.addSubview(controller.view)

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        // Double-snapshot: first draw warms SwiftUI's layout pass for any
        // pending updates (image decode, font glyphs, blur layers).
        // Second draw is the one we keep. Both calls are sync — total
        // overhead is a couple ms.
        let format = UIGraphicsImageRendererFormat()
        format.scale = editor.aspect.exportScale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        _ = renderer.image { _ in
            controller.view.drawHierarchy(
                in: controller.view.bounds,
                afterScreenUpdates: true
            )
        }

        let image = renderer.image { _ in
            controller.view.drawHierarchy(
                in: controller.view.bounds,
                afterScreenUpdates: true
            )
        }

        controller.view.removeFromSuperview()
        return image
    }
}

// MARK: - UIActivityViewController bridge

/// Identifiable wrapper so .sheet(item:) can present the share sheet
/// atomically — the sheet and its image are bound together; the sheet
/// doesn't open until the image is set, eliminating the race that made
/// the first tap show a black sheet.
struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
