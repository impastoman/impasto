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
    @State private var editingBlend: FlourBlend? = nil
    @State private var editingProcess: SavedProcess? = nil
    @State private var editingPreferment: SavedPreferment? = nil
    @State private var isReordering = false

    var body: some View {
        NavigationStack {
            List {
                recipesSection
                blendsSection
                processesSection
                prefermentsSection
            }
            .environment(\.editMode, .constant(isReordering ? .active : .inactive))
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
                    Button(isReordering ? "Done" : "Reorder") {
                        isReordering.toggle()
                    }
                    .foregroundColor(isReordering ? Color(hex: "D2B96A") : .secondary)
                    .font(.system(size: 13, design: .monospaced))
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
        .preferredColorScheme(.light)
        .sheet(isPresented: $showWizard) {
            WizardContainerView { recipe in
                store.add(recipe)
                showWizard = false
            }
        }
        .sheet(isPresented: $showBlendBuilder) {
            StandaloneBlendBuilderView().environmentObject(store)
        }
        .sheet(item: $editingBlend) { blend in
            StandaloneBlendBuilderView(editing: blend).environmentObject(store)
        }
        .sheet(isPresented: $showProcessBuilder) {
            StandaloneProcessBuilderView().environmentObject(store)
        }
        .sheet(item: $editingProcess) { process in
            StandaloneProcessBuilderView(editing: process).environmentObject(store)
        }
        .sheet(isPresented: $showPrefBuilder) {
            StandalonePrefermentBuilderView().environmentObject(store)
        }
        .sheet(item: $editingPreferment) { pref in
            StandalonePrefermentBuilderView(editing: pref).environmentObject(store)
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

    // MARK: - Recipes (folder-grouped for onMove support)

    @ViewBuilder
    var recipesSection: some View {
        let grouped = Dictionary(grouping: store.recipes) { $0.folderName }
        let folders = grouped.keys.filter { !$0.isEmpty }.sorted()
        let unfoldered = grouped[""] ?? []

        if store.recipes.isEmpty {
            Section(header: Text("Recipes")) {
                Text("No recipes yet — tap + to create one.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        } else {
            if !unfoldered.isEmpty || folders.isEmpty {
                Section(header: Text("Recipes")) {
                    ForEach(unfoldered) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeRowView(recipe: recipe)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { recipeToDelete = recipe } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { src, dst in
                        store.moveRecipes(inFolder: "", from: src, to: dst)
                    }
                }
            }
            ForEach(folders, id: \.self) { folder in
                let items = grouped[folder] ?? []
                Section(header: folderHeader("Recipes", folder: folder)) {
                    ForEach(items) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeRowView(recipe: recipe)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { recipeToDelete = recipe } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { src, dst in
                        store.moveRecipes(inFolder: folder, from: src, to: dst)
                    }
                }
            }
        }
    }

    // MARK: - Blends (folder-grouped for onMove support)

    @ViewBuilder
    var blendsSection: some View {
        let grouped = Dictionary(grouping: store.savedBlends) { $0.folderName }
        let folders = grouped.keys.filter { !$0.isEmpty }.sorted()
        let unfoldered = grouped[""] ?? []

        if store.savedBlends.isEmpty {
            Section(header: Text("Flour Blends")) {
                Text("No saved blends yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        } else {
            if !unfoldered.isEmpty || folders.isEmpty {
                Section(header: Text("Flour Blends")) {
                    ForEach(unfoldered) { blend in blendRow(blend) }
                        .onMove { src, dst in store.moveBlends(inFolder: "", from: src, to: dst) }
                }
            }
            ForEach(folders, id: \.self) { folder in
                let items = grouped[folder] ?? []
                Section(header: folderHeader("Flour Blends", folder: folder)) {
                    ForEach(items) { blend in blendRow(blend) }
                        .onMove { src, dst in store.moveBlends(inFolder: folder, from: src, to: dst) }
                }
            }
        }
    }

    func blendRow(_ blend: FlourBlend) -> some View {
        Button { editingBlend = blend } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(blend.name.isEmpty ? "Untitled Blend" : blend.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text(blend.components.map { "\(Int($0.percentage))% \($0.type.rawValue)" }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteBlend(blend) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Processes (folder-grouped for onMove support)

    @ViewBuilder
    var processesSection: some View {
        let grouped = Dictionary(grouping: store.savedProcesses) { $0.folderName }
        let folders = grouped.keys.filter { !$0.isEmpty }.sorted()
        let unfoldered = grouped[""] ?? []

        if store.savedProcesses.isEmpty {
            Section(header: Text("Processes")) {
                Text("No saved processes yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        } else {
            if !unfoldered.isEmpty || folders.isEmpty {
                Section(header: Text("Processes")) {
                    ForEach(unfoldered) { process in processRow(process) }
                        .onMove { src, dst in store.moveProcesses(inFolder: "", from: src, to: dst) }
                }
            }
            ForEach(folders, id: \.self) { folder in
                let items = grouped[folder] ?? []
                Section(header: folderHeader("Processes", folder: folder)) {
                    ForEach(items) { process in processRow(process) }
                        .onMove { src, dst in store.moveProcesses(inFolder: folder, from: src, to: dst) }
                }
            }
        }
    }

    func processRow(_ process: SavedProcess) -> some View {
        Button { editingProcess = process } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(process.name.isEmpty ? "Untitled Process" : process.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("\(process.cards.count) steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteProcess(process) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Preferments (folder-grouped for onMove support)

    @ViewBuilder
    var prefermentsSection: some View {
        let grouped = Dictionary(grouping: store.savedPreferments) { $0.folderName }
        let folders = grouped.keys.filter { !$0.isEmpty }.sorted()
        let unfoldered = grouped[""] ?? []

        if store.savedPreferments.isEmpty {
            Section(header: Text("Preferments")) {
                Text("No saved preferments yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        } else {
            if !unfoldered.isEmpty || folders.isEmpty {
                Section(header: Text("Preferments")) {
                    ForEach(unfoldered) { pref in prefermentRow(pref) }
                        .onMove { src, dst in store.movePreferments(inFolder: "", from: src, to: dst) }
                }
            }
            ForEach(folders, id: \.self) { folder in
                let items = grouped[folder] ?? []
                Section(header: folderHeader("Preferments", folder: folder)) {
                    ForEach(items) { pref in prefermentRow(pref) }
                        .onMove { src, dst in store.movePreferments(inFolder: folder, from: src, to: dst) }
                }
            }
        }
    }

    func prefermentRow(_ pref: SavedPreferment) -> some View {
        Button { editingPreferment = pref } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(pref.name.isEmpty ? "Untitled Preferment" : pref.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("\(pref.label)  ·  \(Int(pref.hydration * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteSavedPreferment(pref) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    func folderHeader(_ type: String, folder: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "folder").font(.caption2)
            Text(folder)
        }
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
