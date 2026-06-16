import SwiftUI
import UniformTypeIdentifiers

// MARK: - Import Recipe

struct ImportRecipeView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var premium: PremiumStore
    @Environment(\.dismiss) private var dismiss

    @State private var pastedText = ""
    @State private var parsedRecipe: Recipe? = nil
    @State private var sharedBy: String? = nil
    @State private var parseError: String? = nil
    @State private var showDocPicker = false
    @State private var showAdvanced = false
    @State private var saved = false
    /// Set when an import is blocked by the free recipe cap; shows an
    /// inline upgrade prompt rather than the global paywall (avoids a
    /// sheet-over-sheet conflict, since this view is itself a sheet).
    @State private var blockedByLimit = false
    @State private var showPaywall = false

    /// When `initialRecipe` is supplied (a tapped .stesura file/link routed
    /// in via StesuraApp's .onOpenURL), the view opens straight to the
    /// preview — the user never sees the source/paste step or any JSON.
    /// `author` is the optional "Shared by …" sender name.
    init(initialRecipe: Recipe? = nil, author: String? = nil) {
        _parsedRecipe = State(initialValue: initialRecipe)
        _sharedBy = State(initialValue: author)
    }

    var body: some View {
        NavigationStack {
            if let recipe = parsedRecipe {
                previewView(recipe)
            } else {
                sourceView
            }
        }
        .sheet(isPresented: $showDocPicker) {
            JSONDocumentPicker { data in
                attemptParse(data: data)
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Source view (step 1 + 2)

    var sourceView: some View {
        List {
            Section {
                Text("Open a recipe someone shared with you. The easiest way is to just tap the shared file — it opens here automatically. You can also browse for it below.")
                    .font(.jakarta(.regular, size: 12))
                    .foregroundColor(.secondary)
                    .tipText()
            }
            .listRowBackground(Color.clear)

            Section {
                Button {
                    showDocPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(Color(hex: "7FA2BD"))
                        Text("Browse for a recipe file")
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(Color(hex: "7FA2BD"))
                    }
                }

                if let error = parseError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red).font(.jakarta(.regular, size: 12))
                        Text(error)
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text("Import from file")
            } footer: {
                Text("Recipe files end in .stesura. Tap one in Messages, Mail, or Files and it opens straight into Stesura.")
                    .font(.jakarta(.regular, size: 11))
                    .tipText()
            }
            .listRowBackground(Color.clear)

            // Advanced: paste raw JSON. Tucked away so the common path
            // (tap a file) stays front-and-centre and non-technical.
            Section {
                DisclosureGroup(isExpanded: $showAdvanced) {
                    TextEditor(text: $pastedText)
                        .font(.jakarta(.regular, size: 12))
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color(hex: "F0EDE4"))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "7FA2BD").opacity(0.4), lineWidth: 1)
                        )

                    Button("Preview Recipe →") {
                        attemptParse(text: pastedText)
                    }
                    .foregroundColor(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? .secondary : Color(hex: "7FA2BD"))
                    .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } label: {
                    Text("Advanced: paste recipe text")
                        .font(.jakarta(.regular, size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Import Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Preview view (step 3 + 4)

    func previewView(_ recipe: Recipe) -> some View {
        List {
            // Photo placeholder
            Section(header: Text("Overview").font(.jakarta(.semibold, size: 13))) {
                if let sharedBy {
                    LabeledContent("Shared by", value: sharedBy)
                        .font(.jakarta(.regular, size: 17))
                        .foregroundColor(Color(hex: "7FA2BD"))
                }
                LabeledContent("Name",        value: recipe.name)
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Style",       value: recipe.style == .custom && !recipe.customStyleName.isEmpty ? recipe.customStyleName : recipe.style.rawValue)
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Method",      value: recipe.method.rawValue)
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Timeline",    value: "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Target",      value: "\(recipe.ballCount) × \(Int(recipe.ballWeight))g")
                    .font(.jakarta(.regular, size: 17))
            }
            .listRowBackground(Color.clear)

            Section(header: Text("Formula").font(.jakarta(.semibold, size: 13))) {
                LabeledContent("Hydration",   value: "\(Int(recipe.finalHydration * 100))%")
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Salt",        value: String(format: "%.1f%%", recipe.saltPct * 100))
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Yeast",       value: "\(recipe.yeastType.rawValue)  ·  \(String(format: "%.2f%%", recipe.yeastPct * 100))")
                    .font(.jakarta(.regular, size: 17))
            }
            .listRowBackground(Color.clear)

            if !recipe.processCards.isEmpty {
                Section(header: Text("Process").font(.jakarta(.semibold, size: 13))) {
                    ForEach(recipe.processCards.filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }) { card in
                        HStack {
                            Text(card.title).font(.jakarta(.regular, size: 13))
                            Spacer()
                            if card.duration > 0 {
                                Text(shortDuration(card.duration))
                                    .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                            } else {
                                Text("action").font(.jakarta(.regular, size: 11)).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }

            Section {
                if saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "7FA2BD"))
                        Text("Saved to library!")
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(Color(hex: "7FA2BD"))
                    }
                } else if blockedByLimit {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your free library is full (2 recipes). Unlock Stesura Premium to import this one.")
                            .font(.jakarta(.regular, size: 13))
                            .foregroundColor(.primary)
                        Button("Unlock Premium →") { showPaywall = true }
                            .foregroundColor(Color(hex: "7FA2BD"))
                            .font(.jakarta(.semibold, size: 14))
                    }
                } else {
                    Button("Save to Library →") {
                        saveRecipe(recipe)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(hex: "7FA2BD"))
                    .font(.jakarta(.regular, size: 14))
                }
            } footer: {
                Text("Saving also adds this recipe's flour blend, process, and preferment to your libraries.")
                    .font(.jakarta(.regular, size: 11))
                    .tipText()
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("← Back") { parsedRecipe = nil }
            }
        }
        // Local paywall (sheet-from-sheet is reliable; the global one
        // would conflict with this import sheet). On unlock, the blocked
        // flag clears so the user can tap Save.
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(premium)
        }
        .onChange(of: premium.isPremium) { _, now in
            if now { blockedByLimit = false }
        }
    }

    // MARK: - Parse

    func attemptParse(text: String) {
        guard let data = text.data(using: .utf8) else {
            parseError = "Could not read the text."
            return
        }
        attemptParse(data: data)
    }

    func attemptParse(data: Data) {
        do {
            var recipe = try StesuraExport.decodeRecipe(from: data)
            recipe.id = UUID()       // fresh ID — never overwrite an existing recipe
            recipe.bakeLogs = []     // don't import historical bake logs
            sharedBy = StesuraExport.author(from: data)
            parsedRecipe = recipe
            parseError = nil
        } catch let e as StesuraExport.ImportError {
            parseError = e.errorDescription
        } catch {
            parseError = "Couldn't parse — check the file is a valid Stesura recipe export."
        }
    }

    // MARK: - Save

    func saveRecipe(_ recipe: Recipe) {
        // Free tier: block the import if it would exceed the recipe cap.
        // Check directly (not via store.add's global paywall) so we can
        // show an inline prompt without a sheet-over-sheet conflict.
        guard premium.isPremium || store.recipes.count < store.freeRecipeLimit else {
            blockedByLimit = true
            return
        }
        store.add(recipe)
        importComponents(from: recipe)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }

    /// Fan-out: a recipe import also materializes its embedded flour
    /// blend, process, and preferment as standalone items in the
    /// receiver's libraries, each named after the source recipe and
    /// given a fresh id. Keeps the imported recipe fully reproducible
    /// and lets the receiver reuse the pieces independently.
    private func importComponents(from recipe: Recipe) {
        var blend = recipe.flourBlend
        blend.id = UUID()
        blend.folderName = ""
        blend.name = "\(recipe.name) — Blend"
        store.addBlend(blend)

        let process = SavedProcess(
            name: "\(recipe.name) — Process",
            cards: recipe.processCards
        )
        store.addProcess(process)

        // Direct-method recipes have no preferment to extract.
        if recipe.method != .direct {
            let pref = SavedPreferment(
                name: "\(recipe.name) — Preferment",
                method: recipe.method,
                hydration: recipe.prefermentHydration,
                flourBlend: recipe.prefermentFlourBlend,
                ratioPercent: recipe.bigaRatio
            )
            store.addSavedPreferment(pref)
        }
    }

    func shortDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// MARK: - Document picker

struct JSONDocumentPicker: UIViewControllerRepresentable {
    let onPick: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Accept the custom .stesura type plus plain .json (so files
        // exported by older builds, or saved as .json, still pick).
        var types: [UTType] = [.json]
        if let stesura = UTType(filenameExtension: StesuraExport.fileExtension) {
            types.insert(stesura, at: 0)
        }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: JSONDocumentPicker
        init(_ parent: JSONDocumentPicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first,
                  let data = try? Data(contentsOf: url) else { return }
            parent.onPick(data)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
