import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: RecipeStore
    var onGoHome: (() -> Void)? = nil
    @State private var showAddMenu = false
    @State private var showWizard = false
    @State private var showBlendBuilder = false
    @State private var showProcessBuilder = false
    @State private var showPrefBuilder = false
    @State private var showStartDough = false
    @State private var recipeToDelete: Recipe? = nil

    var body: some View {
        NavigationStack {
            List {
                recipesSection
                blendsSection
                processesSection
                prefermentsSection
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let goHome = onGoHome {
                        Button("⌂ Home") { goHome() }
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddMenu = true } label: { Image(systemName: "plus") }
                }
            }
            .confirmationDialog("", isPresented: $showAddMenu, titleVisibility: .hidden) {
                Button("New Recipe") { showWizard = true }
                Button("New Flour Blend") { showBlendBuilder = true }
                Button("New Process") { showProcessBuilder = true }
                Button("New Preferment") { showPrefBuilder = true }
                Button("Start New Session") { showStartDough = true }
                Button("Cancel", role: .cancel) {}
            }
        }
        .sheet(isPresented: $showWizard) {
            WizardContainerView { recipe in
                store.add(recipe)
                showWizard = false
            }
        }
        .sheet(isPresented: $showBlendBuilder) {
            StandaloneBlendBuilderView().environmentObject(store)
        }
        .sheet(isPresented: $showProcessBuilder) {
            StandaloneProcessBuilderView().environmentObject(store)
        }
        .sheet(isPresented: $showPrefBuilder) {
            StandalonePrefermentBuilderView().environmentObject(store)
        }
        .sheet(isPresented: $showStartDough) {
            StartDoughView().environmentObject(store)
        }
        .alert("Delete Recipe?", isPresented: Binding(
            get: { recipeToDelete != nil },
            set: { if !$0 { recipeToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let r = recipeToDelete { store.delete(r) }
                recipeToDelete = nil
            }
            Button("Cancel", role: .cancel) { recipeToDelete = nil }
        } message: {
            Text("\"\(recipeToDelete?.name ?? "")\" will be permanently removed.")
        }
    }

    var recipesSection: some View {
        Section {
            if store.recipes.isEmpty {
                Text("No recipes yet — tap + to create one.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.recipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeRowView(recipe: recipe)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { recipeToDelete = recipe } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: { Text("Recipes") }
    }

    var blendsSection: some View {
        Section {
            if store.savedBlends.isEmpty {
                Text("No saved blends yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.savedBlends) { blend in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(blend.name.isEmpty ? "Untitled Blend" : blend.name)
                            .font(.system(.body, design: .monospaced))
                        Text(blend.components.map { "\(Int($0.percentage))% \($0.type.rawValue)" }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 2)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { store.deleteBlend(blend) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: { Text("Flour Blends") }
    }

    var processesSection: some View {
        Section {
            if store.savedProcesses.isEmpty {
                Text("No saved processes yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.savedProcesses) { process in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(process.name.isEmpty ? "Untitled Process" : process.name)
                            .font(.system(.body, design: .monospaced))
                        Text("\(process.cards.count) steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { store.deleteProcess(process) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: { Text("Processes") }
    }

    var prefermentsSection: some View {
        Section {
            if store.savedPreferments.isEmpty {
                Text("No saved preferments yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.savedPreferments) { pref in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pref.name.isEmpty ? "Untitled Preferment" : pref.name)
                            .font(.system(.body, design: .monospaced))
                        Text("\(pref.label)  ·  \(Int(pref.hydration * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { store.deleteSavedPreferment(pref) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: { Text("Preferments") }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe

    var styleLabel: String {
        recipe.style == .custom && !recipe.customStyleName.isEmpty
            ? recipe.customStyleName
            : recipe.style.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(recipe.name).font(.headline)
                Spacer()
                Text(styleLabel)
                    .font(.caption2)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color(hex: "D2B96A").opacity(0.15))
                    .foregroundColor(Color(hex: "D2B96A"))
                    .cornerRadius(4)
            }
            Text("\(Int(recipe.finalHydration * 100))% · \(recipe.ballCount) × \(Int(recipe.ballWeight))g · \(recipe.timeline.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(recipe.bakeLogs.isEmpty ? "Untested" : "Tested ×\(recipe.bakeLogs.count)")
                .font(.caption2)
                .foregroundColor(recipe.bakeLogs.isEmpty ? .orange : .green)
        }
        .padding(.vertical, 4)
    }
}
