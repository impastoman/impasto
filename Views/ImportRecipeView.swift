import SwiftUI
import UniformTypeIdentifiers

// MARK: - Import Recipe

struct ImportRecipeView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var pastedText = ""
    @State private var parsedRecipe: Recipe? = nil
    @State private var parseError: String? = nil
    @State private var showDocPicker = false
    @State private var saved = false

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
                Text("Import a recipe that was exported from Stesura. Paste the JSON below, or pick a .json file.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)

            Section("Paste recipe JSON") {
                TextEditor(text: $pastedText)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: "F0EDE4"))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "D2B96A").opacity(0.4), lineWidth: 1)
                    )

                if let error = parseError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red).font(.caption)
                        Text(error)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }

                Button("Preview Recipe →") {
                    attemptParse(text: pastedText)
                }
                .foregroundColor(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                 ? .secondary : Color(hex: "D2B96A"))
                .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .listRowBackground(Color.clear)

            Section {
                Button {
                    showDocPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(Color(hex: "D2B96A"))
                        Text("Browse files (.json)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                }
            } header: {
                Text("Or import from file")
            } footer: {
                Text("Use the Share → Export button in Recipe Detail to get the JSON for any recipe.")
                    .font(.system(size: 11, design: .monospaced))
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .fillerPaper(title: "Import Recipe")
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
            Section("Overview") {
                LabeledContent("Name",        value: recipe.name)
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Style",       value: recipe.style.rawValue)
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Method",      value: recipe.method.rawValue)
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Timeline",    value: "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Target",      value: "\(recipe.ballCount) × \(Int(recipe.ballWeight))g")
                    .font(.system(.body, design: .monospaced))
            }
            .listRowBackground(Color.clear)

            Section("Formula") {
                LabeledContent("Hydration",   value: "\(Int(recipe.finalHydration * 100))%")
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Salt",        value: String(format: "%.1f%%", recipe.saltPct * 100))
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Yeast",       value: "\(recipe.yeastType.rawValue)  ·  \(String(format: "%.2f%%", recipe.yeastPct * 100))")
                    .font(.system(.body, design: .monospaced))
            }
            .listRowBackground(Color.clear)

            if !recipe.processCards.isEmpty {
                Section("Process") {
                    ForEach(recipe.processCards.filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }) { card in
                        HStack {
                            Text(card.title).font(.system(size: 13, design: .monospaced))
                            Spacer()
                            if card.duration > 0 {
                                Text(shortDuration(card.duration))
                                    .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                            } else {
                                Text("action").font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
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
                            .foregroundColor(Color(hex: "D2B96A"))
                        Text("Saved to library!")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                } else {
                    Button("Save to Library →") {
                        saveRecipe(recipe)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(hex: "D2B96A"))
                    .font(.system(size: 14, design: .monospaced))
                }
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .fillerPaper(title: recipe.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("← Back") { parsedRecipe = nil }
            }
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
            var recipe = try JSONDecoder().decode(Recipe.self, from: data)
            recipe.id = UUID()       // fresh ID — never overwrite an existing recipe
            recipe.bakeLogs = []     // don't import historical bake logs
            parsedRecipe = recipe
            parseError = nil
        } catch {
            parseError = "Couldn't parse — check the JSON is a valid Stesura recipe export."
        }
    }

    // MARK: - Save

    func saveRecipe(_ recipe: Recipe) {
        store.add(recipe)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
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
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
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
