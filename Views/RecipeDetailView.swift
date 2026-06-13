import SwiftUI
import UIKit
import LinkPresentation

struct RecipeDetailView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @State var recipe: Recipe
    var isReadOnly: Bool = false
    @State private var showPreFlight = false
    @State private var showEditWizard = false
    @State private var showForkWizard = false
    @State private var isRenamingTitle = false
    @State private var pendingName = ""
    @State private var exportShare: ExportShareURL? = nil

    /// Identifiable wrapper so .sheet(item:) presents the share sheet
    /// atomically once the export file has been written.
    struct ExportShareURL: Identifiable {
        let id = UUID()
        let url: URL
    }

    var styleLabel: String {
        recipe.style == .custom && !recipe.customStyleName.isEmpty
            ? recipe.customStyleName
            : recipe.style.rawValue
    }

    var body: some View {
        List {
            Section(header: Text("Style & Method").font(.jakarta(.semibold, size: 13))) {
                row("Style",    styleLabel)
                row("Method",   recipe.method.rawValue)
                row("Mixer",    recipe.mixerType.rawValue)
                row("Autolyse", recipe.autolyse ? "\(recipe.autolyseMinutes) min" : "None")
                row("Timeline", "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
            }
            .listRowBackground(Color.clear)
            .meadSection()

            Section(header: Text("Formula").font(.jakarta(.semibold, size: 13))) {
                row("Final hydration", "\(Int(recipe.finalHydration * 100))%")
                if recipe.bigaRatio > 0 {
                    row("Biga hydration",  "\(Int(recipe.bigaHydration * 100))%")
                    row("Biga percentage", "\(Int(recipe.bigaRatio * 100))%")
                }
                row("Salt",  String(format: "%.1f%%", recipe.saltPct * 100))
                row("Yeast", "\(recipe.yeastType.rawValue)  ·  \(String(format: "%.2f%%", recipe.yeastPct * 100))")
            }
            .listRowBackground(Color.clear)
            .meadSection()

            if !recipe.flourBlend.components.isEmpty {
                Section(header: Text("Flour blend").font(.jakarta(.semibold, size: 13))) {
                    ForEach(recipe.flourBlend.components) { c in
                        row(c.type.rawValue, "\(Int(c.percentage))%")
                    }
                    ForEach(recipe.flourBlend.additives) { a in
                        row(a.type.rawValue, "\(a.percentage)%")
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            .meadSection()
                .font(.jakarta(.regular, size: 17))
            }

            Section(header: Text("Target").font(.jakarta(.semibold, size: 13))) {
                row("Balls",       "\(recipe.ballCount) × \(Int(recipe.ballWeight))g")
                row("Total dough", "\(Int(recipe.totalDoughWeight))g")
            }
            .listRowBackground(Color.clear)
            .meadSection()

            if recipe.method != .direct {
                Section(header: Text("① \(recipe.method.rawValue)").font(.jakarta(.semibold, size: 13))) {
                    row("Flour", "\(Int(recipe.bigaFlour))g")
                    row("Water", "\(Int(recipe.bigaWater))g")
                    row("Yeast", String(format: "%.1fg", recipe.bigaYeast))
                }
                .listRowBackground(Color.clear)
            .meadSection()
            }

            Section(recipe.method != .direct ? "② Final dough" : "Dough") {
                row("Flour", "\(Int(recipe.additionalFlour))g")
                row("Water", "\(Int(recipe.additionalWater))g")
                row("Salt",  "\(Int(recipe.totalSalt))g")
            }
            .listRowBackground(Color.clear)
            .meadSection()

            if !isReadOnly {
                Section {
                    Button("▶  Start Session") { showPreFlight = true }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(Color(hex: "7FA2BD"))
                        .meadRow()
                    Button("Edit Recipe") { showEditWizard = true }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.primary)
                        .meadRow()
                    Button("Modify and Save as New") { showForkWizard = true }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.secondary)
                        .meadRow()
                }
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color.ruleBlue)
            }
        }
        .meadList()
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isReadOnly {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Button {
                            exportRecipe()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button {
                            pendingName = recipe.name
                            isRenamingTitle = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
        }
        .alert("Rename Recipe", isPresented: $isRenamingTitle) {
            TextField("Recipe name", text: $pendingName)
            Button("Save") {
                guard !pendingName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                recipe.name = pendingName
                store.update(recipe)
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showPreFlight) {
            PreFlightView(recipe: recipe)
                .environmentObject(store)
                .environmentObject(sessionManager)
                .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showEditWizard) {
            WizardContainerView(
                mode: .edit(recipe),
                onComplete: { updated in
                    store.update(updated)
                    recipe = updated
                    showEditWizard = false
                },
                onSaveAsNew: { forked in
                    store.add(forked)
                    showEditWizard = false
                }
            )
            .environmentObject(store)
        }
        .sheet(isPresented: $showForkWizard) {
            WizardContainerView(
                mode: .fork(recipe),
                onComplete: { forked in
                    store.add(forked)
                    showForkWizard = false
                }
            )
            .environmentObject(store)
        }
        .sheet(item: $exportShare) { payload in
            ActivityShareSheet(items: [
                RecipeLinkActivityItemSource(
                    url: payload.url,
                    title: "Stesura Recipe: \(recipe.name)"
                )
            ])
        }
    }

    /// Spec row — label on the left, value on the right. The red
    /// margin line is drawn as a single continuous strip behind the
    /// whole List. .alignmentGuide moves the blue inter-row separator's
    /// leading edge LEFT (negative value) into the row's inset/padding
    /// area, so it meets the red strip flush instead of starting at
    /// the content leading edge with a gap between.
    func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
            .font(.jakarta(.regular, size: 17))
            .meadRow()
    }

    /// Builds a stesura://import?d=… deep link and presents the share
    /// sheet. Sharing a LINK (not a file) means tapping it in Messages
    /// opens Stesura directly into the import preview; on import the
    /// receiver gets the recipe plus its flour blend / process /
    /// preferment fanned out into their libraries. Bake logs are stripped.
    func exportRecipe() {
        let author = UserDefaults.standard.string(forKey: "stesura_author_name")
        // Universal Link (https) — renders a clean tappable card in Messages
        // and opens the app directly. Falls back to the custom-scheme link
        // only if building the https URL somehow fails.
        let url = StesuraExport.encodeRecipeUniversalLink(recipe, author: author)
            ?? StesuraExport.encodeRecipeLink(recipe, author: author)
        guard let url else { return }
        exportShare = ExportShareURL(url: url)
    }
}

// MARK: - Rich link share

/// Wraps the stesura:// recipe link with LPLinkMetadata so the share
/// sheet and Messages render a clean preview card (title + icon)
/// instead of the raw deep-link string. Tapping the card opens Stesura.
final class RecipeLinkActivityItemSource: NSObject, UIActivityItemSource {
    let url: URL
    let title: String

    init(url: URL, title: String) {
        self.url = url
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { url }

    func activityViewController(_ controller: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { url }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let md = LPLinkMetadata()
        md.title = title
        md.originalURL = url
        md.url = url
        let icon = StesuraShareIcon.image()
        md.iconProvider = NSItemProvider(object: icon)
        md.imageProvider = NSItemProvider(object: icon)
        return md
    }
}

/// Icon shown in the recipe-share preview card. Prefers the real app
/// icon once one is set (#39); until then renders a Mead-paper
/// placeholder so the card never looks like a bare link.
enum StesuraShareIcon {
    static func image() -> UIImage {
        appIcon() ?? placeholder()
    }

    private static func appIcon() -> UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else { return nil }
        return UIImage(named: name)
    }

    private static func placeholder() -> UIImage {
        let size = CGSize(width: 320, height: 320)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0xFA/255, green: 0xFA/255, blue: 0xF5/255, alpha: 1).setFill()  // paperWhite
            UIRectFill(rect)
            UIColor(red: 0xD4/255, green: 0x75/255, blue: 0x6A/255, alpha: 1).setFill()  // marginRed
            UIRectFill(CGRect(x: 86, y: 0, width: 3, height: size.height))
            let para = NSMutableParagraphStyle(); para.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Fraunces-SemiBold", size: 190)
                    ?? UIFont.systemFont(ofSize: 190, weight: .semibold),
                .foregroundColor: UIColor(red: 0x2C/255, green: 0x2A/255, blue: 0x24/255, alpha: 1),
                .paragraphStyle: para
            ]
            ("S" as NSString).draw(in: CGRect(x: 0, y: 55, width: size.width, height: 230),
                                   withAttributes: attrs)
        }
    }
}
