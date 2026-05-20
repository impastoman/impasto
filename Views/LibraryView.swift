import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
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
    @State private var showVolumeConverter = false
    @State private var pendingFormula: ConvertedFormula? = nil
    @State private var showFormulaWizard  = false
    @State private var showSettings       = false
    // Folder-move sheets
    @State private var recipeToMove: Recipe? = nil
    @State private var blendToMove: FlourBlend? = nil
    @State private var processToMove: SavedProcess? = nil
    @State private var prefermentToMove: SavedPreferment? = nil

    // MARK: - Folder option lists

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
                        Button { goHome() } label: {
                            Image(systemName: "house")
                        }
                        .foregroundColor(.secondary)
                    }
                }
                if isReordering {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sections ↕") { showSectionReorder = true }
                            .foregroundColor(.secondary)
                            .font(.system(size: 13, design: .monospaced))
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showAddMenu = true } label: { Image(systemName: "plus") }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .confirmationDialog("", isPresented: $showAddMenu, titleVisibility: .hidden) {
                Button("New Recipe") { showWizard = true }
                Button("Convert a Volume Recipe") { showVolumeConverter = true }
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
        }
        .preferredColorScheme(.light)
        .safeAreaInset(edge: .bottom) {
            if isReordering {
                Button {
                    isReordering = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done Sorting")
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "D2B96A"))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
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
        .sheet(isPresented: $showVolumeConverter, onDismiss: {
            if pendingFormula != nil { showFormulaWizard = true }
        }) {
            VolumeConverterView { formula in
                pendingFormula = formula
                showVolumeConverter = false
            }
        }
        .sheet(isPresented: $showFormulaWizard) {
            if let formula = pendingFormula {
                WizardContainerView(convertedFormula: formula) { recipe in
                    store.add(recipe)
                    pendingFormula = nil
                    showFormulaWizard = false
                }
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
            StartDoughView()
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
        .sheet(item: $recipeToMove) { recipe in
            FolderPickerSheet(
                itemName: recipe.name,
                currentFolder: recipe.folderName,
                folders: recipeFolderOptions
            ) { folder in
                store.moveRecipeToFolder(recipe, folder: folder)
            }
        }
        .sheet(item: $blendToMove) { blend in
            FolderPickerSheet(
                itemName: blend.name.isEmpty ? "Untitled Blend" : blend.name,
                currentFolder: blend.folderName,
                folders: blendFolderOptions
            ) { folder in
                store.moveBlendToFolder(blend, folder: folder)
            }
        }
        .sheet(item: $processToMove) { process in
            FolderPickerSheet(
                itemName: process.name.isEmpty ? "Untitled Process" : process.name,
                currentFolder: process.folderName,
                folders: processFolderOptions
            ) { folder in
                store.moveProcessToFolder(process, folder: folder)
            }
        }
        .sheet(item: $prefermentToMove) { pref in
            FolderPickerSheet(
                itemName: pref.name.isEmpty ? "Untitled Preferment" : pref.name,
                currentFolder: pref.folderName,
                folders: prefermentFolderOptions
            ) { folder in
                store.movePrefermentToFolder(pref, folder: folder)
            }
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

    // MARK: - Section header button

    func sectionTypeHeader(_ title: String) -> some View {
        Button {
            newFolderSection   = title
            newFolderName      = ""
            showNewFolderAlert = true
        } label: {
            HStack(spacing: 5) {
                Text(title)
                Image(systemName: "folder.badge.plus").font(.caption2)
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
                .recipeRowActions(
                    recipe: recipe,
                    folders: recipeFolderOptions,
                    onMoveRequest: { recipeToMove = recipe },
                    onMove: { store.moveRecipeToFolder(recipe, folder: $0) },
                    onDelete: { recipeToDelete = recipe },
                    onLongPress: { isReordering = true }
                )
            }
            .onMove { src, dst in store.moveRecipes(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    let items = grouped[folder] ?? []
                    ForEach(items) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeRowView(recipe: recipe)
                        }
                        .recipeRowActions(
                            recipe: recipe,
                            folders: recipeFolderOptions,
                            onMoveRequest: { recipeToMove = recipe },
                            onMove: { store.moveRecipeToFolder(recipe, folder: $0) },
                            onDelete: { recipeToDelete = recipe },
                            onLongPress: { isReordering = true }
                        )
                    }
                    .onMove { src, dst in store.moveRecipes(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in isReordering = true }
                        )
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
            ForEach(unfoldered) { blend in blendRow(blend) }
                .onMove { src, dst in store.moveBlends(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    ForEach(grouped[folder] ?? []) { blend in blendRow(blend) }
                        .onMove { src, dst in store.moveBlends(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in isReordering = true }
                        )
                }
            }
        }
    }

    func blendRow(_ blend: FlourBlend) -> some View {
        Button { editingBlend = blend } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(blend.name.isEmpty ? "Untitled Blend" : blend.name)
                    .font(.system(.body, design: .monospaced)).foregroundColor(.primary)
                Text(blend.components.map { "\(Int($0.percentage))% \($0.type.rawValue)" }.joined(separator: " · "))
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !blendFolderOptions.isEmpty || !blend.folderName.isEmpty {
                Button { blendToMove = blend } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(Color(hex: "D2B96A"))
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteBlend(blend) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in isReordering = true }
        )
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
            ForEach(unfoldered) { process in processRow(process) }
                .onMove { src, dst in store.moveProcesses(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    ForEach(grouped[folder] ?? []) { process in processRow(process) }
                        .onMove { src, dst in store.moveProcesses(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in isReordering = true }
                        )
                }
            }
        }
    }

    func processRow(_ process: SavedProcess) -> some View {
        Button { editingProcess = process } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(process.name.isEmpty ? "Untitled Process" : process.name)
                    .font(.system(.body, design: .monospaced)).foregroundColor(.primary)
                Text("\(process.cards.count) steps")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !processFolderOptions.isEmpty || !process.folderName.isEmpty {
                Button { processToMove = process } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(Color(hex: "D2B96A"))
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteProcess(process) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in isReordering = true }
        )
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
            ForEach(unfoldered) { pref in prefermentRow(pref) }
                .onMove { src, dst in store.movePreferments(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    ForEach(grouped[folder] ?? []) { pref in prefermentRow(pref) }
                        .onMove { src, dst in store.movePreferments(inFolder: folder, from: src, to: dst) }
                } label: {
                    Label(folder, systemImage: "folder")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in isReordering = true }
                        )
                }
            }
        }
    }

    func prefermentRow(_ pref: SavedPreferment) -> some View {
        Button { editingPreferment = pref } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(pref.name.isEmpty ? "Untitled Preferment" : pref.name)
                    .font(.system(.body, design: .monospaced)).foregroundColor(.primary)
                Text("\(pref.label)  ·  \(Int(pref.hydration * 100))%")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !prefermentFolderOptions.isEmpty || !pref.folderName.isEmpty {
                Button { prefermentToMove = pref } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(Color(hex: "D2B96A"))
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteSavedPreferment(pref) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in isReordering = true }
        )
    }

    // MARK: - Shared folder move menu (used in context menus)

    @ViewBuilder
    func folderMoveMenu(currentFolder: String, options: [String], onMove: @escaping (String) -> Void) -> some View {
        let destinations = options.filter { $0 != currentFolder }
        if !destinations.isEmpty || !currentFolder.isEmpty {
            Menu {
                if !currentFolder.isEmpty {
                    Button {
                        onMove("")
                    } label: {
                        Label("Remove from Folder", systemImage: "folder.badge.minus")
                    }
                }
                ForEach(destinations, id: \.self) { folder in
                    Button {
                        onMove(folder)
                    } label: {
                        Label(folder, systemImage: "folder")
                    }
                }
            } label: {
                Label("Move to Folder", systemImage: "folder")
            }
        }
    }
}

// MARK: - Recipe row modifier

private extension View {
    func recipeRowActions(
        recipe: Recipe,
        folders: [String],
        onMoveRequest: @escaping () -> Void,
        onMove: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) -> some View {
        self
            // Leading swipe → opens the FolderPickerSheet (reliable on NavigationLink rows)
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if !folders.isEmpty || !recipe.folderName.isEmpty {
                    Button {
                        onMoveRequest()
                    } label: {
                        Label("Move", systemImage: "folder")
                    }
                    .tint(Color(hex: "D2B96A"))
                }
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            // Long-press anywhere on the row enters reorder mode
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in onLongPress() }
            )
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
                    Text(section).font(.system(.body, design: .monospaced))
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
                .font(.caption).foregroundColor(.secondary)
            Text(recipe.bakeLogs.isEmpty ? "Untested" : "Tested ×\(recipe.bakeLogs.count)")
                .font(.caption2)
                .foregroundColor(recipe.bakeLogs.isEmpty ? .orange : .green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Folder Picker Sheet

private struct FolderPickerSheet: View {
    let itemName: String
    let currentFolder: String
    let folders: [String]
    let onMove: (String) -> Void   // "" = remove from folder
    @Environment(\.dismiss) private var dismiss

    var destinations: [String] { folders.filter { $0 != currentFolder } }

    var body: some View {
        NavigationStack {
            List {
                if !currentFolder.isEmpty {
                    Section {
                        Button {
                            onMove("")
                            dismiss()
                        } label: {
                            Label("Remove from \"\(currentFolder)\"", systemImage: "folder.badge.minus")
                                .foregroundColor(.orange)
                                .font(.system(size: 14, design: .monospaced))
                        }
                    }
                }

                if destinations.isEmpty {
                    Section {
                        Text("No other folders — tap ⊕ folder badge on a section header to create one.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section("Move to") {
                        ForEach(destinations, id: \.self) { folder in
                            Button {
                                onMove(folder)
                                dismiss()
                            } label: {
                                Label(folder, systemImage: "folder")
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(itemName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 13, design: .monospaced))
                }
            }
        }
        .preferredColorScheme(.light)
        .presentationDetents([.medium, .large])
    }
}
