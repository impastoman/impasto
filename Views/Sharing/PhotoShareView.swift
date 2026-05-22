import SwiftUI
import PhotosUI
import UIKit

// MARK: - Models

/// The output canvas shape. ImageRenderer rasterizes at 3× for export.
enum ShareAspect: String, CaseIterable, Identifiable {
    case square   = "1:1"
    case portrait = "4:5"
    case vertical = "9:16"
    case native   = "Native"

    var id: String { rawValue }

    /// In-editor preview size (points). Export multiplies these by `exportScale`.
    /// 360pt × 3× scale = 1080px — matches Instagram standard sizes.
    func previewSize(for photoAspect: CGFloat) -> CGSize {
        switch self {
        case .square:   return CGSize(width: 360, height: 360)  // → 1080×1080
        case .portrait: return CGSize(width: 360, height: 450)  // → 1080×1350
        case .vertical: return CGSize(width: 360, height: 640)  // → 1080×1920
        case .native:
            // photoAspect = width / height; clamp to sensible bounds
            let clamped = max(0.5, min(2.0, photoAspect))
            return CGSize(width: 360, height: 360 / clamped)
        }
    }

    /// Pixel scale factor for export (ImageRenderer.scale).
    var exportScale: CGFloat { 3.0 }
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

    var emoji: String? {
        switch self {
        case .styleMethod:   return nil
        case .formula:       return nil
        case .flourBlend:    return "🌾"
        case .preferment:    return nil    // per spec — no emoji
        case .process:       return "📋"
        case .sessionNotes:  return nil
        }
    }
}

struct ShareBlock: Identifiable, Equatable {
    let id = UUID()
    let type: ShareBlockType
    let title: String
    let body: String
    var enabled: Bool
    /// Normalized 0…1 position within the canvas. Center anchor.
    var position: CGPoint

    static func == (lhs: ShareBlock, rhs: ShareBlock) -> Bool { lhs.id == rhs.id }
}

// MARK: - Block content extractor

struct ShareBlockExtractor {
    /// Builds the block list from a BakeLog + Recipe + scope.
    /// Style & Method and Formula default to enabled; the rest default to off
    /// per the spec. Blocks with no underlying data are omitted entirely.
    static func blocks(for log: BakeLog, recipe: Recipe, scope: ShareScope) -> [ShareBlock] {
        var out: [ShareBlock] = []
        // Stack the defaults in the lower third, centered.
        let centerX: CGFloat = 0.5
        var y: CGFloat = 0.66
        let yStep: CGFloat = 0.08

        // Style & method
        let styleName = recipe.style == .custom && !recipe.customStyleName.isEmpty
            ? recipe.customStyleName
            : recipe.style.rawValue
        let methodPart = recipe.method == .direct ? "Direct" : recipe.method.rawValue
        out.append(ShareBlock(
            type: .styleMethod,
            title: ShareBlockType.styleMethod.rawValue,
            body: "\(styleName) · \(methodPart)",
            enabled: true,
            position: CGPoint(x: centerX, y: y)
        ))
        y += yStep

        // Formula (NO buffer — production detail)
        let hyd   = "\(Int(recipe.finalHydration * 100))% hydration"
        let balls = "\(recipe.ballCount) × \(Int(recipe.ballWeight))g"
        let salt  = String(format: "%.1f%% salt", recipe.saltPct * 100)
        let yeast = recipe.yeastType.rawValue.lowercased()
        out.append(ShareBlock(
            type: .formula,
            title: ShareBlockType.formula.rawValue,
            body: "\(hyd) · \(balls) · \(salt) · \(yeast)",
            enabled: true,
            position: CGPoint(x: centerX, y: y)
        ))
        y += yStep

        // Flour blend (only if named)
        if !recipe.flourBlend.name.isEmpty {
            out.append(ShareBlock(
                type: .flourBlend,
                title: ShareBlockType.flourBlend.rawValue,
                body: recipe.flourBlend.name,
                enabled: false,
                position: CGPoint(x: centerX, y: y)
            ))
            y += yStep
        }

        // Preferment (skip on direct method)
        if recipe.method != .direct {
            let pct = Int(recipe.bigaRatio * 100)
            let body = pct > 0 ? "\(recipe.method.rawValue) · \(pct)%" : recipe.method.rawValue
            out.append(ShareBlock(
                type: .preferment,
                title: ShareBlockType.preferment.rawValue,
                body: body,
                enabled: false,
                position: CGPoint(x: centerX, y: y)
            ))
            y += yStep
        }

        // Process — show step count as a lightweight description
        // (Recipe doesn't currently store the linked SavedProcess name.)
        let enabledSteps = recipe.processCards.filter { $0.isEnabled }.count
        if enabledSteps > 0 {
            out.append(ShareBlock(
                type: .process,
                title: ShareBlockType.process.rawValue,
                body: "\(enabledSteps) steps",
                enabled: false,
                position: CGPoint(x: centerX, y: y)
            ))
            y += yStep
        }

        // Notes block — content depends on scope
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
                position: CGPoint(x: centerX, y: y)
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
                position: CGPoint(x: centerX, y: y)
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
    let photo: Data?
    @Binding var blocks: [ShareBlock]
    let canvasSize: CGSize
    var draggable: Bool = true

    var body: some View {
        ZStack {
            background
                .allowsHitTesting(false)   // photo / cream should never eat taps

            // ForEach($blocks) iterates with Binding<ShareBlock> — idiomatic
            // SwiftUI 16+ pattern that propagates per-element mutations.
            ForEach($blocks) { $block in
                if block.enabled {
                    DraggableShareBlock(
                        block: $block,
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
                .allowsHitTesting(false)  // critical — must not block block drags
        }
        .clipped()
    }

    @ViewBuilder
    private var background: some View {
        if let data = photo, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
        } else {
            Color(hex: "F5F1E8")
                .frame(width: canvasSize.width, height: canvasSize.height)
        }
    }

    /// "Baked with Stesura" pinned bottom-right. Not toggleable.
    /// Lives in an .overlay (NOT as a ZStack sibling sized to the canvas) so
    /// its frame can't intercept taps meant for the block tiles.
    private var watermarkLabel: some View {
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
struct DraggableShareBlock: View {
    @Binding var block: ShareBlock
    let canvasSize: CGSize
    var draggable: Bool

    @State private var dragOrigin: CGPoint? = nil

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let emoji = block.type.emoji {
                    Text(emoji).font(.system(size: 10))
                }
                Text(block.title.uppercased())
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.75))
            }
            Text(block.body)
                .font(.system(size: 11, design: .monospaced).weight(.medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray).opacity(0.55))
        .cornerRadius(6)
        .position(
            x: block.position.x * canvasSize.width,
            y: block.position.y * canvasSize.height
        )
        .if(draggable) { tile in
            tile.gesture(
                // minimumDistance: 1 — recognizes immediately but allows
                // a literal-zero touch to still pass to the parent if any.
                DragGesture(minimumDistance: 1, coordinateSpace: .local)
                    .onChanged { value in
                        if dragOrigin == nil { dragOrigin = block.position }
                        guard let origin = dragOrigin else { return }
                        let newX = origin.x + value.translation.width / canvasSize.width
                        let newY = origin.y + value.translation.height / canvasSize.height
                        block.position = CGPoint(
                            x: min(max(0.06, newX), 0.94),
                            y: min(max(0.06, newY), 0.94)
                        )
                    }
                    .onEnded { _ in dragOrigin = nil }
            )
        }
    }
}

// MARK: - Editor

struct PhotoShareView: View {
    let log: BakeLog
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss

    @State private var scope: ShareScope
    @State private var aspect: ShareAspect = .square
    @State private var blocks: [ShareBlock] = []
    @State private var selectedPhoto: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage? = nil
    private let isPerPizzaCapable: Bool

    init(log: BakeLog, recipe: Recipe, scope: ShareScope) {
        self.log = log
        self.recipe = recipe
        _scope = State(initialValue: scope)
        self.isPerPizzaCapable = {
            if case .singlePizza = scope { return true }
            return !log.pizzaEntries.isEmpty
        }()
    }

    /// Cached photo aspect ratio for the .native canvas.
    private var photoAspect: CGFloat {
        guard let data = selectedPhoto, let img = UIImage(data: data),
              img.size.height > 0 else { return 1.0 }
        return img.size.width / img.size.height
    }

    private var canvasSize: CGSize { aspect.previewSize(for: photoAspect) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1A1A1A").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        aspectPicker

                        canvasFrame

                        if photoIsMissing {
                            pickPhotoPrompt
                        } else {
                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                Label("Replace photo", systemImage: "photo")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        if isPerPizzaCapable {
                            scopePicker
                        }

                        blockTogglesSection

                        helperFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
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
            if blocks.isEmpty {
                blocks = ShareBlockExtractor.blocks(for: log, recipe: recipe, scope: scope)
            }
            if selectedPhoto == nil {
                selectedPhoto = log.displayPhotos.first ?? coverFromPizza()
            }
        }
        .onChange(of: scope) { _, newScope in
            blocks = ShareBlockExtractor.blocks(for: log, recipe: recipe, scope: newScope)
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    await MainActor.run { selectedPhoto = data }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = renderedImage {
                ActivityShareSheet(items: [image])
            }
        }
    }

    private func coverFromPizza() -> Data? {
        if case .singlePizza(let entry) = scope {
            return entry.displayPhotos.first
        }
        return log.pizzaEntries.flatMap(\.displayPhotos).first
    }

    private var photoIsMissing: Bool { selectedPhoto == nil }

    // MARK: subviews

    private var aspectPicker: some View {
        // Custom segmented row. Uses .onTapGesture on a styled Text rather
        // than Button(.plain) — the latter had inconsistent hit detection
        // inside a ScrollView on some iOS builds. Gold pill on the active
        // aspect, dim white on the rest.
        HStack(spacing: 6) {
            ForEach(ShareAspect.allCases) { a in
                Text(a.rawValue)
                    .font(.system(size: 12, design: .monospaced).weight(aspect == a ? .semibold : .regular))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(aspect == a ? Color(hex: "D2B96A") : Color.white.opacity(0.08))
                    .foregroundColor(aspect == a ? .black : .white.opacity(0.7))
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .onTapGesture { aspect = a }
            }
        }
    }

    private var canvasFrame: some View {
        ShareCanvasView(
            photo: selectedPhoto,
            blocks: $blocks,
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
                if case .singlePizza(let entry) = scope,
                   let i = log.pizzaEntries.firstIndex(where: { $0.id == entry.id }) {
                    return i + 1
                }
                return 0
            },
            set: { newTag in
                if newTag == 0 {
                    scope = .wholeSession
                } else if log.pizzaEntries.indices.contains(newTag - 1) {
                    scope = .singlePizza(log.pizzaEntries[newTag - 1])
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
                ForEach($blocks) { $block in
                    Toggle(isOn: $block.enabled) {
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
        // ImageRenderer rasterizes the canvas at the aspect's export scale
        // (360pt × 3× = 1080px on the long side).
        //
        // The first uiImage call after a renderer is constructed sometimes
        // returns a black/empty image because SwiftUI hasn't laid out the
        // proposed-size view yet. We trigger a warmup render (discarded),
        // then capture the real one. Both calls are sync — total cost is
        // a few ms on device.
        let canvas = ShareCanvasView(
            photo: selectedPhoto,
            blocks: $blocks,
            canvasSize: canvasSize,
            draggable: false
        )
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = aspect.exportScale
        renderer.proposedSize = ProposedViewSize(canvasSize)

        _ = renderer.uiImage   // warmup — discard result
        guard let uiImage = renderer.uiImage else { return }

        renderedImage = uiImage
        // Defer presenting the sheet until the next runloop so SwiftUI
        // observes renderedImage being set BEFORE the sheet evaluates
        // its content closure. Without this, the first present can show
        // a black sheet because renderedImage was still nil when the
        // closure ran.
        DispatchQueue.main.async {
            showShareSheet = true
        }
    }
}

// MARK: - UIActivityViewController bridge

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
