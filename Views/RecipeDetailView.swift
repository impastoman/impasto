import SwiftUI

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
                .font(.jakarta(.regular, size: 17))
            }

            Section(header: Text("Target").font(.jakarta(.semibold, size: 13))) {
                row("Balls",       "\(recipe.ballCount) × \(Int(recipe.ballWeight))g")
                row("Total dough", "\(Int(recipe.totalDoughWeight))g")
            }
            .listRowBackground(Color.clear)

            if recipe.method != .direct {
                Section(header: Text("① \(recipe.method.rawValue)").font(.jakarta(.semibold, size: 13))) {
                    row("Flour", "\(Int(recipe.bigaFlour))g")
                    row("Water", "\(Int(recipe.bigaWater))g")
                    row("Yeast", String(format: "%.1fg", recipe.bigaYeast))
                }
                .listRowBackground(Color.clear)
            }

            Section(recipe.method != .direct ? "② Final dough" : "Dough") {
                row("Flour", "\(Int(recipe.additionalFlour))g")
                row("Water", "\(Int(recipe.additionalWater))g")
                row("Salt",  "\(Int(recipe.totalSalt))g")
            }
            .listRowBackground(Color.clear)

            if !isReadOnly {
                Section {
                    Button("▶  Start Session") { showPreFlight = true }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(Color(hex: "D2B96A"))
                    Button("Edit Recipe") { showEditWizard = true }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.primary)
                    Button("Modify and Save as New") { showForkWizard = true }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isReadOnly {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        ShareLink(item: recipeExportString()) {
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
    }

    func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
            .font(.jakarta(.regular, size: 17))
    }

    func recipeExportString() -> String {
        var exportRecipe = recipe
        exportRecipe.bakeLogs = []   // strip bake history
        guard let data = try? JSONEncoder().encode(exportRecipe),
              let json = String(data: data, encoding: .utf8) else { return "{}" }
        return json
    }
}
