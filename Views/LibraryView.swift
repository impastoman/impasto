import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: RecipeStore
    var onGoHome: (() -> Void)? = nil
    @State private var showAddMenu        = false
    @State private var showWizard         = false
    @State private var showBlendBuilder   = false
    @State private var showProcessBuilder = false
    @State private var showPrefBuilder    = false
    @State private var showStartDough     = false
    @State private var recipeToDelete: Recipe? = nil
    @State private var editingBlend: FlourBlend? = nil
    @State private var editingProcess: SavedProcess? = nil
    @State private var editingPreferment: SavedPreferment? = nil
    @State private var isReordering       = false
    @State private var showSectionReorder = false
    @State private var newFolderSection   = ""
    @State private var newFolderName      = ""
    @State private var showNewFolderAlert = false
    // Move-to-folder
    @State private var recipeToMove: Recipe? = nil
    @State private var blendToMove: FlourBlend? = nil
    @State private var processToMove: SavedProcess? = nil
    @State private var prefermentToMove: SavedPreferment? = nil

    // Folder option lists for move dialogs
    var recipeFolderOptions: [String] {
        Array(Set(store.recipeFolders + store.recipes.compactMap { $0.folderName.isEmpty ? nil : $0.folderName })).sorted()
    }
    var blendFolderOptions: [String] {
        Array(Set(store.blendFolders + store.savedBlends.compactMap { $0.folderName.isEmpty ? nil : $0.folderName })).sorted()
    }
    var processFolderOptions: [String] {
        Array(Set(store.processFolders + store.savedProcesses.compactMap { $0.folderName.isEmpty ? nil : $0.folderName })).sorted()
    }
    var prefermentFolderOptions: [String] {
        Array(Set(store.prefermentFolders + store.savedPreferments.compactMap { $0.folderName.isEmpty ? nil : $0.folderName })).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.librarySectionOrder, id: \.self) { section in
                    sectionView(for: section)
                }
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
                if isReordering {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { isReordering = false }
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.system(size: 13, design: .monospaced))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sections ↕") { showSectionReorder = true }
                            .foregroundColor(.secondary)
                            .font(.system(size: 13, design: .monospaced))
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Reorder") { isReordering = true }
                            .foregroundColor(.secondary)
                            .font(.system(size: 13, design: .monospaced))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showAddMenu = true } label: { Image(systemName: "plus") }
                    }
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
            .alert("New Folder", isPresented: $showNewFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    let name = newFolderName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    switch newFolderSection {
                    case "Recipes":
                        if !store.recipeFolders.contains(name) { store.recipeFolders.append(name); store.saveFolderRegistry() }
                    case "Flour Blends":
                        if !store.blendFolders.contains(name) { store.blendFolders.append(name); store.saveFolderRegistry() }
                    case "Processes":
                        if !store.processFolders.contains(name) { store.processFolders.append(name); store.saveFolderRegistry() }
                    case "Preferments":
                        if !store.prefermentFolders.contains(name) { store.prefermentFolders.append(name); store.saveFolderRegistry() }
                    default: break
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("New folder in \(newFolderSection)")
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
            // Move-to-folder dialogs
            .confirmationDialog(
                "Move \"\(recipeToMove?.name ?? "")\" to…",
                isPresented: Binding(get: { recipeToMove != nil }, set: { if !$0 { recipeToMove = nil } }),
                titleVisibility: .visible
            ) {
                Button("No Folder (root)") {
                    if let r = recipeToMove { store.moveRecipeToFolder(r, folder: "") }
                    recipeToMove = nil
                }
                ForEach(recipeFolderOptions, id: \.self) { folder in
                    Button(folder) {
                        if let r = recipeToMove { store.moveRecipeToFolder(r, folder: folder) }
                        recipeToMove = nil
                    }
                }
                Button("Cancel", role: .cancel) { recipeToMove = nil }
            }
            .confirmationDialog(
                "Move \"\(blendToMove?.name ?? "")\" to…",
                isPresented: Binding(get: { blendToMove != nil }, set: { if !$0 { blendToMove = nil } }),
                titleVisibility: .visible
            ) {
                Button("No Folder (root)") {
                    if let b = blendToMove { store.moveBlendToFolder(b, folder: "") }
                    blendToMove = nil
                }
                ForEach(blendFolderOptions, id: \.self) { folder in
                    Button(folder) {
                        if let b = blendToMove { store.moveBlendToFolder(b, folder: folder) }
                        blendToMove = nil
                    }
                }
                Button("Cancel", role: .cancel) { blendToMove = nil }
            }
            .confirmationDialog(
                "Move \"\(processToMove?.name ?? "")\" to…",
                isPresented: Binding(get: { processToMove != nil }, set: { if !$0 { processToMove = nil } }),
                titleVisibility: .visible
            ) {
                Button("No Folder (root)") {
                    if let p = processToMove { store.moveProcessToFolder(p, folder: "") }
                    processToMove = nil
                }
                ForEach(processFolderOptions, id: \.self) { folder in
                    Button(folder) {
                        if let p = processToMove { store.moveProcessToFolder(p, folder: folder) }
                        processToMove = nil
                    }
                }
                Button("Cancel", role: .cancel) { processToMove = nil }
            }
            .confirmationDialog(
                "Move \"\(prefermentToMove?.name ?? "")\" to…",
                isPresented: Binding(get: { prefermentToMove != nil }, set: { if !$0 { prefermentToMove = nil } }),
                titleVisibility: .visible
            ) {
                Button("No Folder (root)") {
                    if let p = prefermentToMove { store.movePrefermentToFolder(p, folder: "") }
                    prefermentToMove = nil
                }
                ForEach(prefermentFolderOptions, id: \.self) { folder in
                    Button(folder) {
                        if let p = prefermentToMove { store.movePrefermentToFolder(p, folder: folder) }
                        prefermentToMove = nil
                    }
                }
                Button("Cancel", role: .cancel) { prefermentToMove = nil }
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSectionReorder) {
            SectionReorderView(
                order: Binding(get: { store.librarySectionOrder },
                               set: { store.librarySectionOrder = $0 }),
                onSave: { store.saveSectionOrder() }
            )
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
    }

    // MARK: - Section routing

    @ViewBuilder
    func sectionView(for section: String) -> some View {
        switch section {
        case "Recipes":      recipesSection
        case "Processes":    processesSection
        case "Flour Blends": blendsSection
        case "Preferments":  prefermentsSection
        default:             EmptyView()
        }
    }

    // MARK: - Tappable type header

    func sectionTypeHeader(_ title: String) -> some View {
        Button {
            newFolderSection = title
            newFolderName    = ""
            showNewFolderAlert = true
        } label: {
            HStack(spacing: 5) {
                Text(title)
                Image(systemName: "folder.badge.plus")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recipes

    @ViewBuilder
    var recipesSection: some View {
        let grouped    = Dictionary(grouping: store.recipes) { $0.folderName }
        let allFolders = Array(Set(store.recipeFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header: sectionTypeHeader("Recipes")) {
            if store.recipes.isEmpty && allFolders.isEmpty {
                Text("No recipes yet — tap + to create one.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            ForEach(unfoldered) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeRowView(recipe: recipe)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { recipeToDelete = recipe } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    if !allFolders.isEmpty {
                        Button { recipeToMove = recipe } label: {
                            Label("Move", systemImage: "folder")
                        }
                        .tint(.blue)
                    }
                }
            }
            .onMove { src, dst in store.moveRecipes(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    let items = grouped[folder] ?? []
                    ForEach(items) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeRowView(recipe: recipe)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { recipeToDelete = recipe } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { recipeToMove = recipe } label: {
                                Label("Move", systemImage: "folder")
                            }
                            .tint(.blue)
                        }
                    }
                    .onMove { src, dst in store.moveRecipes(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Flour Blends

    @ViewBuilder
    var blendsSection: some View {
        let grouped    = Dictionary(grouping: store.savedBlends) { $0.folderName }
        let allFolders = Array(Set(store.blendFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header: sectionTypeHeader("Flour Blends")) {
            if store.savedBlends.isEmpty && allFolders.isEmpty {
                Text("No saved blends yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            ForEach(unfoldered) { blend in blendRow(blend, allFolders: allFolders) }
                .onMove { src, dst in store.moveBlends(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    let items = grouped[folder] ?? []
                    ForEach(items) { blend in blendRow(blend, allFolders: allFolders) }
                        .onMove { src, dst in store.moveBlends(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    func blendRow(_ blend: FlourBlend, allFolders: [String]) -> some View {
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { store.deleteBlend(blend) } label: {
                Label("Delete", systemImage: "trash")
            }
            if !allFolders.isEmpty {
                Button { blendToMove = blend } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(.blue)
            }
        }
    }

    // MARK: - Processes

    @ViewBuilder
    var processesSection: some View {
        let grouped    = Dictionary(grouping: store.savedProcesses) { $0.folderName }
        let allFolders = Array(Set(store.processFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header: sectionTypeHeader("Processes")) {
            if store.savedProcesses.isEmpty && allFolders.isEmpty {
                Text("No saved processes yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            ForEach(unfoldered) { process in processRow(process, allFolders: allFolders) }
                .onMove { src, dst in store.moveProcesses(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    let items = grouped[folder] ?? []
                    ForEach(items) { process in processRow(process, allFolders: allFolders) }
                        .onMove { src, dst in store.moveProcesses(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    func processRow(_ process: SavedProcess, allFolders: [String]) -> some View {
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { store.deleteProcess(process) } label: {
                Label("Delete", systemImage: "trash")
            }
            if !allFolders.isEmpty {
                Button { processToMove = process } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(.blue)
            }
        }
    }

    // MARK: - Preferments

    @ViewBuilder
    var prefermentsSection: some View {
        let grouped    = Dictionary(grouping: store.savedPreferments) { $0.folderName }
        let allFolders = Array(Set(store.prefermentFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header: sectionTypeHeader("Preferments")) {
            if store.savedPreferments.isEmpty && allFolders.isEmpty {
                Text("No saved preferments yet.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            ForEach(unfoldered) { pref in prefermentRow(pref, allFolders: allFolders) }
                .onMove { src, dst in store.movePreferments(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    let items = grouped[folder] ?? []
                    ForEach(items) { pref in prefermentRow(pref, allFolders: allFolders) }
                        .onMove { src, dst in store.movePreferments(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    func prefermentRow(_ pref: SavedPreferment, allFolders: [String]) -> some View {
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { store.deleteSavedPreferment(pref) } label: {
                Label("Delete", systemImage: "trash")
            }
            if !allFolders.isEmpty {
                Button { prefermentToMove = pref } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(.blue)
            }
        }
    }
}

// MARK: - Section Reorder Sheet

private struct SectionReorderView: View {
    @Binding var order: [String]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(order, id: \.self) { section in
                    Text(section)
                        .font(.system(.body, design: .monospaced))
                }
                .onMove { from, to in order.move(fromOffsets: from, toOffset: to) }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Section Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onSave(); dismiss() }
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        }
    }
}

// MARK: - Recipe Row

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
