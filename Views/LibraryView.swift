import SwiftUI
import UniformTypeIdentifiers

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
    @State private var showSectionReorder = false
    // Tracks which folder (per section) is being hovered during a drag,
    // for visual feedback. Also helps prove drops are being detected.
    @State private var hoveredFolder: String? = nil
    @State private var hoveredHeader: String? = nil
    /// Per-section "which folders are expanded" sets. Replaces
    /// DisclosureGroup which intercepted .draggable / .dropDestination /
    /// .onDrop drops at the gesture-routing layer on iOS 26.
    @State private var expandedProcessFolders: Set<String> = []
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

    @State private var hoveredDiagnostic = false

    /// DIAGNOSTIC drop zone — outside the List. Used to test whether
    /// drops can be received at all in this view hierarchy.
    private var diagnosticDropZone: some View {
        let label = hoveredDiagnostic
            ? "DROP HERE TO MOVE OUT OF FOLDERS"
            : "↓ TEST DROP ZONE ↓"
        let bg: Color = hoveredDiagnostic ? .marginRed : .ruleBlueFaint
        let fg: Color = hoveredDiagnostic ? .white : .ruleBlue
        return Text(label)
            .font(.jakarta(.semibold, size: 11))
            .tracking(1.5)
            .foregroundColor(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(bg)
            .onDrop(of: [.text], isTargeted: $hoveredDiagnostic) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: NSString.self) { obj, _ in
                    print("[Library diagnostic drop] received: \(obj ?? "nil")")
                }
                return true
            }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.librarySectionOrder, id: \.self) { section in
                    sectionView(for: section)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                diagnosticDropZone
            }
            // EditMode is intentionally NOT toggled here. EditMode.active
            // captures gestures on row bodies (for the right-edge handles
            // and selection), which prevents .draggable from initiating a
            // system drag. We use drag-and-drop instead — long-press a row
            // in reorder mode to drag it onto a folder or section header.
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
            .confirmationDialog("", isPresented: $showAddMenu, titleVisibility: .hidden) {
                Button("New Recipe") { showWizard = true }
                Button("Convert a Volume Recipe") { showVolumeConverter = true }
                Button("Reorder library sections") { showSectionReorder = true }
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
                    .font(.jakarta(.semibold, size: 13))
                Image(systemName: "folder.badge.plus").font(.jakarta(.regular, size: 11))
            }
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recipes

    /// Drop handler shared by folder labels and the section header.
    /// Returns true if the dropped string decoded to a known recipe.
    func handleRecipeDrop(items: [String], toFolder folder: String) -> Bool {
        guard let id = items.first.flatMap(UUID.init),
              let r = store.recipes.first(where: { $0.id == id })
        else { return false }
        store.moveRecipeToFolder(r, folder: folder)
        return true
    }

    func handleBlendDrop(items: [String], toFolder folder: String) -> Bool {
        guard let id = items.first.flatMap(UUID.init),
              let b = store.savedBlends.first(where: { $0.id == id })
        else { return false }
        store.moveBlendToFolder(b, folder: folder)
        return true
    }

    func handleProcessDrop(items: [String], toFolder folder: String) -> Bool {
        guard let id = items.first.flatMap(UUID.init),
              let p = store.savedProcesses.first(where: { $0.id == id })
        else { return false }
        store.moveProcessToFolder(p, folder: folder)
        return true
    }

    /// Legacy .onDrop NSItemProvider handler — used in place of
    /// .dropDestination for folder + section-header drop targets
    /// because the newer API isn't being routed by SwiftUI's List
    /// + DisclosureGroup hit testing in iOS 26. Loads the dragged
    /// UUID string off the provider and calls handleProcessDrop on
    /// the main actor.
    func handleProcessOnDrop(providers: [NSItemProvider], toFolder folder: String) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: NSString.self) { obj, _ in
            guard let str = obj as? String else { return }
            DispatchQueue.main.async {
                _ = handleProcessDrop(items: [str], toFolder: folder)
            }
        }
        return true
    }

    func handlePrefermentDrop(items: [String], toFolder folder: String) -> Bool {
        guard let id = items.first.flatMap(UUID.init),
              let p = store.savedPreferments.first(where: { $0.id == id })
        else { return false }
        store.movePrefermentToFolder(p, folder: folder)
        return true
    }

    @ViewBuilder
    var recipesSection: some View {
        let grouped    = Dictionary(grouping: store.recipes) { $0.folderName }
        let allFolders = Array(Set(store.recipeFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header:
            sectionTypeHeader("Recipes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .background(
                    hoveredHeader == "Recipes"
                        ? Color.ruleBlueFaint
                        : Color.clear
                )
                .dropDestination(for: String.self) { items, _ in
                    handleRecipeDrop(items: items, toFolder: "")
                } isTargeted: { targeted in
                    hoveredHeader = targeted ? "Recipes" : nil
                }
        ) {
            if store.recipes.isEmpty && allFolders.isEmpty {
                Text("No recipes yet — tap + to create one.")
                    .font(.jakarta(.regular, size: 13))
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
                    onDelete: { recipeToDelete = recipe }
                )
                .draggable(recipe.id.uuidString)
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
                            onDelete: { recipeToDelete = recipe }
                        )
                        .draggable(recipe.id.uuidString)
                    }
                    .onMove { src, dst in store.moveRecipes(inFolder: folder, from: src, to: dst) }
                } label: {
                    HStack {
                        Label(folder, systemImage: "folder")
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    // Drop target lives ON the label HStack itself (not on
                    // the whole DisclosureGroup) so it doesn't compete
                    // with the disclosure expand-tap or the inner ForEach
                    // reordering. isTargeted highlights the row when a
                    // drag is hovering — if you see this tint while
                    // dragging, drops are being detected.
                    .background(
                        hoveredFolder == "recipes-\(folder)"
                            ? Color.ruleBlueFaint
                            : Color.clear
                    )
                    .dropDestination(for: String.self) { items, _ in
                        handleRecipeDrop(items: items, toFolder: folder)
                    } isTargeted: { targeted in
                        hoveredFolder = targeted ? "recipes-\(folder)" : nil
                    }
                }
            }

            if !allFolders.isEmpty {
                Text("Long-press a recipe to drag it. Drop on a folder to move it in, or on the \"Recipes\" header to take it out.")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                    .tipText()
            }
        }
    }

    // MARK: - Flour Blends

    @ViewBuilder
    var blendsSection: some View {
        let grouped    = Dictionary(grouping: store.savedBlends) { $0.folderName }
        let allFolders = Array(Set(store.blendFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header:
            sectionTypeHeader("Flour Blends")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .background(
                    hoveredHeader == "Flour Blends"
                        ? Color.ruleBlueFaint
                        : Color.clear
                )
                .dropDestination(for: String.self) { items, _ in
                    handleBlendDrop(items: items, toFolder: "")
                } isTargeted: { targeted in
                    hoveredHeader = targeted ? "Flour Blends" : nil
                }
        ) {
            if store.savedBlends.isEmpty && allFolders.isEmpty {
                Text("No saved blends yet.")
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(.secondary)
            }
            ForEach(unfoldered) { blend in
                blendRow(blend)
                    .draggable(blend.id.uuidString)
            }
            .onMove { src, dst in store.moveBlends(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    ForEach(grouped[folder] ?? []) { blend in
                        blendRow(blend)
                            .draggable(blend.id.uuidString)
                    }
                    .onMove { src, dst in store.moveBlends(inFolder: folder, from: src, to: dst) }
                } label: {
                    HStack {
                        Label(folder, systemImage: "folder")
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(
                        hoveredFolder == "blends-\(folder)"
                            ? Color.ruleBlueFaint
                            : Color.clear
                    )
                    .dropDestination(for: String.self) { items, _ in
                        handleBlendDrop(items: items, toFolder: folder)
                    } isTargeted: { targeted in
                        hoveredFolder = targeted ? "blends-\(folder)" : nil
                    }
                }
            }

            if !allFolders.isEmpty {
                Text("Long-press a blend to drag it. Drop on a folder to move it in, or on the \"Flour Blends\" header to take it out.")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                    .tipText()
            }
        }
    }

    func blendRow(_ blend: FlourBlend) -> some View {
        Button { editingBlend = blend } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(blend.name.isEmpty ? "Untitled Blend" : blend.name)
                    .font(.jakarta(.regular, size: 17)).foregroundColor(.primary)
                Text(blend.components.map { "\(Int($0.percentage))% \($0.type.rawValue)" }.joined(separator: " · "))
                    .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary).lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !blendFolderOptions.isEmpty || !blend.folderName.isEmpty {
                Button { blendToMove = blend } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(Color(hex: "7FA2BD"))
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteBlend(blend) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Processes

    @ViewBuilder
    var processesSection: some View {
        let grouped    = Dictionary(grouping: store.savedProcesses) { $0.folderName }
        let allFolders = Array(Set(store.processFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header:
            sectionTypeHeader("Processes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .background(
                    hoveredHeader == "Processes"
                        ? Color.ruleBlueFaint
                        : Color.clear
                )
                .onDrop(
                    of: [.text],
                    isTargeted: Binding(
                        get: { hoveredHeader == "Processes" },
                        set: { hoveredHeader = $0 ? "Processes" : nil }
                    )
                ) { providers in
                    handleProcessOnDrop(providers: providers, toFolder: "")
                }
        ) {
            if store.savedProcesses.isEmpty && allFolders.isEmpty {
                Text("No saved processes yet.")
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(.secondary)
            }
            ForEach(unfoldered) { process in
                processRow(process)
                    .draggable(process.id.uuidString)
            }
            .onMove { src, dst in store.moveProcesses(inFolder: "", from: src, to: dst) }

            // Custom expandable folder rows — DisclosureGroup was
            // swallowing drop events at the gesture-routing layer.
            // Header + conditional content split via helper to keep
            // the type-checker happy.
            ForEach(allFolders, id: \.self) { folder in
                processFolderRow(folder: folder)
                if expandedProcessFolders.contains(folder) {
                    ForEach(grouped[folder] ?? []) { process in
                        processRow(process)
                            .draggable(process.id.uuidString)
                    }
                }
            }

            if !allFolders.isEmpty {
                Text("Long-press a process to drag it. Drop on a folder to move it in, or on the \"Processes\" header to take it out.")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                    .tipText()
            }
        }
    }

    /// Custom folder header row for the Processes section. Extracted
    /// so the parent ForEach body stays small enough for SwiftUI's
    /// type-checker.
    @ViewBuilder
    func processFolderRow(folder: String) -> some View {
        let isExpanded = expandedProcessFolders.contains(folder)
        let key = "processes-\(folder)"
        HStack {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.jakarta(.regular, size: 12))
                .foregroundColor(.secondary)
            Label(folder, systemImage: "folder")
                .font(.jakarta(.regular, size: 17))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(hoveredFolder == key ? Color.ruleBlueFaint : Color.clear)
        .onTapGesture {
            if isExpanded {
                expandedProcessFolders.remove(folder)
            } else {
                expandedProcessFolders.insert(folder)
            }
        }
        .onDrop(
            of: [.text],
            isTargeted: Binding(
                get: { hoveredFolder == key },
                set: { hoveredFolder = $0 ? key : nil }
            )
        ) { providers in
            handleProcessOnDrop(providers: providers, toFolder: folder)
        }
    }

    func processRow(_ process: SavedProcess) -> some View {
        Button { editingProcess = process } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(process.name.isEmpty ? "Untitled Process" : process.name)
                    .font(.jakarta(.regular, size: 17)).foregroundColor(.primary)
                Text("\(process.cards.count) steps")
                    .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !processFolderOptions.isEmpty || !process.folderName.isEmpty {
                Button { processToMove = process } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(Color(hex: "7FA2BD"))
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteProcess(process) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Preferments

    @ViewBuilder
    var prefermentsSection: some View {
        let grouped    = Dictionary(grouping: store.savedPreferments) { $0.folderName }
        let allFolders = Array(Set(store.prefermentFolders + grouped.keys.filter { !$0.isEmpty })).sorted()
        let unfoldered = grouped[""] ?? []

        Section(header:
            sectionTypeHeader("Preferments")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .background(
                    hoveredHeader == "Preferments"
                        ? Color.ruleBlueFaint
                        : Color.clear
                )
                .dropDestination(for: String.self) { items, _ in
                    handlePrefermentDrop(items: items, toFolder: "")
                } isTargeted: { targeted in
                    hoveredHeader = targeted ? "Preferments" : nil
                }
        ) {
            if store.savedPreferments.isEmpty && allFolders.isEmpty {
                Text("No saved preferments yet.")
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(.secondary)
            }
            ForEach(unfoldered) { pref in
                prefermentRow(pref)
                    .draggable(pref.id.uuidString)
            }
            .onMove { src, dst in store.movePreferments(inFolder: "", from: src, to: dst) }

            ForEach(allFolders, id: \.self) { folder in
                DisclosureGroup {
                    ForEach(grouped[folder] ?? []) { pref in
                        prefermentRow(pref)
                            .draggable(pref.id.uuidString)
                    }
                    .onMove { src, dst in store.movePreferments(inFolder: folder, from: src, to: dst) }
                } label: {
                    HStack {
                        Label(folder, systemImage: "folder")
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(.secondary)
                        Spacer() // padding for hover-target reach
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(
                        hoveredFolder == "preferments-\(folder)"
                            ? Color.ruleBlueFaint
                            : Color.clear
                    )
                    .dropDestination(for: String.self) { items, _ in
                        handlePrefermentDrop(items: items, toFolder: folder)
                    } isTargeted: { targeted in
                        hoveredFolder = targeted ? "preferments-\(folder)" : nil
                    }
                }
            }

            if !allFolders.isEmpty {
                Text("Long-press a preferment to drag it. Drop on a folder to move it in, or on the \"Preferments\" header to take it out.")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                    .tipText()
            }
        }
    }

    func prefermentRow(_ pref: SavedPreferment) -> some View {
        Button { editingPreferment = pref } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(pref.name.isEmpty ? "Untitled Preferment" : pref.name)
                    .font(.jakarta(.regular, size: 17)).foregroundColor(.primary)
                Text("\(pref.label)  ·  \(Int(pref.hydration * 100))%")
                    .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !prefermentFolderOptions.isEmpty || !pref.folderName.isEmpty {
                Button { prefermentToMove = pref } label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(Color(hex: "7FA2BD"))
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.deleteSavedPreferment(pref) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
        onDelete: @escaping () -> Void
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
                    .tint(Color(hex: "7FA2BD"))
                }
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
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
                    Text(section).font(.jakarta(.regular, size: 17))
                }
                .onMove { from, to in order.move(fromOffsets: from, toOffset: to) }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Section Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onSave(); dismiss() }
                        .foregroundColor(Color(hex: "7FA2BD"))
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
        HStack(spacing: 10) {
            // Margin strip — the iconic notebook teacher's-red vertical
            // rule. 2pt wide, fills the row's height.
            Rectangle()
                .fill(Color.marginRed)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name).font(.jakarta(.semibold, size: 16))
                    Spacer()
                    Text(styleLabel)
                        .font(.jakarta(.regular, size: 11))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.ruleBlueFaint)
                        .foregroundColor(Color.ruleBlue)
                        .cornerRadius(4)
                }
                Text("\(Int(recipe.finalHydration * 100))% · \(recipe.ballCount) × \(Int(recipe.ballWeight))g · \(recipe.timeline.rawValue)")
                    .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                Text(recipe.bakeLogs.isEmpty ? "Untested" : "Tested ×\(recipe.bakeLogs.count)")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(recipe.bakeLogs.isEmpty ? .orange : .green)
            }
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
                                .font(.jakarta(.regular, size: 14))
                        }
                    }
                }

                if destinations.isEmpty {
                    Section {
                        Text("No other folders — tap ⊕ folder badge on a section header to create one.")
                            .font(.jakarta(.regular, size: 12))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section(header: Text("Move to").font(.jakarta(.semibold, size: 13))) {
                        ForEach(destinations, id: \.self) { folder in
                            Button {
                                onMove(folder)
                                dismiss()
                            } label: {
                                Label(folder, systemImage: "folder")
                                    .font(.jakarta(.regular, size: 14))
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
                        .font(.jakarta(.regular, size: 13))
                }
            }
        }
        .preferredColorScheme(.light)
        .presentationDetents([.medium, .large])
    }
}
