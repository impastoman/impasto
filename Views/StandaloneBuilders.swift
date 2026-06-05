import SwiftUI

// MARK: - Folder Picker Row

private struct FolderPickerRow: View {
    @Binding var folderName: String
    let existingFolders: [String]

    @State private var showNewFolderAlert = false
    @State private var newFolderInput = ""

    var body: some View {
        HStack {
            Text("Folder")
                .font(.jakarta(.regular, size: 17))
            Spacer()
            Menu {
                Button("None") { folderName = "" }
                if !existingFolders.isEmpty { Divider() }
                ForEach(existingFolders, id: \.self) { folder in
                    Button(folder) { folderName = folder }
                }
                Divider()
                Button("New folder…") {
                    newFolderInput = ""
                    showNewFolderAlert = true
                }
            } label: {
                HStack(spacing: 4) {
                    Text(folderName.isEmpty ? "None" : folderName)
                        .font(.jakarta(.regular, size: 17))
                        .foregroundColor(folderName.isEmpty ? .secondary : Color(hex: "D2B96A"))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("New Folder", isPresented: $showNewFolderAlert) {
            TextField("Folder name", text: $newFolderInput)
            Button("Create") {
                let trimmed = newFolderInput.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { folderName = trimmed }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for the new folder")
        }
    }
}

// MARK: - Standalone Blend Builder

struct StandaloneBlendBuilderView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var blend: FlourBlend
    private let editingId: UUID?

    init(editing: FlourBlend? = nil) {
        _blend = State(initialValue: editing ?? FlourBlend())
        editingId = editing?.id
    }

    var isEditing: Bool { editingId != nil }

    var blendFolders: [String] {
        let fromItems = store.savedBlends.map(\.folderName).filter { !$0.isEmpty }
        return Array(Set(store.blendFolders + fromItems)).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("e.g. Caputo 00 + Semolina", text: $blend.name)
                        .font(.jakarta(.regular, size: 17))
                        .textFieldBox()
                }

                Section {
                    FolderPickerRow(folderName: $blend.folderName, existingFolders: blendFolders)
                }

                Section("Flour blend") {
                    ForEach($blend.components) { $component in
                        FlourComponentRow(component: $component) {
                            blend.components.removeAll { $0.id == component.id }
                        }
                    }
                    HStack {
                        Text("Total")
                            .foregroundColor(.secondary)
                            .font(.jakarta(.regular, size: 17))
                        Spacer()
                        Text(String(format: "%.0f%%", blend.totalPercentage) + (blend.isValid ? "  ✓" : ""))
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(blend.isValid ? Color(hex: "D2B96A") : .red)
                    }
                    .listRowBackground(Color.clear)
                    Button {
                        var c = FlourComponent()
                        c.percentage = max(0, 100 - blend.totalPercentage)
                        blend.components.append(c)
                    } label: {
                        Label("Add flour type", systemImage: "plus")
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.jakarta(.regular, size: 17))
                    }
                }

                Section {
                    ForEach($blend.additives) { $additive in
                        AdditiveRow(additive: $additive) {
                            blend.additives.removeAll { $0.id == additive.id }
                        }
                    }
                    Button {
                        blend.additives.append(Additive())
                    } label: {
                        Label("Add additive", systemImage: "plus")
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.jakarta(.regular, size: 17))
                    }
                } header: {
                    Text("Additives  ·  % of total flour weight")
                }

                if blend.containsRye {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text("Rye flour does not autolyse well — consider disabling autolyse if your blend contains rye")
                                .font(.jakarta(.regular, size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                    .listRowBackground(Color.orange.opacity(0.06))
                }

                if !blend.isValid {
                    Section {
                        Text("Flour percentages must total 100%")
                            .font(.jakarta(.regular, size: 12))
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.red.opacity(0.06))
                }
            }
            .navigationTitle(isEditing ? "Edit Flour Blend" : "New Flour Blend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save As") {
                            var copy = blend; copy.id = UUID()
                            store.addBlend(copy)
                            dismiss()
                        }
                        .disabled(!blend.isValid || blend.name.isEmpty)
                        .foregroundColor(blend.isValid && !blend.name.isEmpty ? .secondary : .secondary)
                        .font(.jakarta(.regular, size: 13))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if isEditing {
                            store.updateBlend(blend)
                        } else {
                            store.addBlend(blend)
                        }
                        dismiss()
                    }
                    .disabled(!blend.isValid || blend.name.isEmpty)
                    .foregroundColor(blend.isValid && !blend.name.isEmpty ? Color(hex: "D2B96A") : .secondary)
                }
            }
        }
    }
}

// MARK: - Standalone Process Builder

struct StandaloneProcessBuilderView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var folderName: String
    @State private var processCards: [ProcessCard]
    @State private var showAddSheet = false
    private let editingId: UUID?

    init(editing: SavedProcess? = nil) {
        _name = State(initialValue: editing?.name ?? "")
        _folderName = State(initialValue: editing?.folderName ?? "")
        _processCards = State(initialValue: editing?.cards ?? ProcessCard.defaultCards(autolyse: false, bassinage: false))
        editingId = editing?.id
    }

    var isEditing: Bool { editingId != nil }

    var processFolders: [String] {
        let fromItems = store.savedProcesses.map(\.folderName).filter { !$0.isEmpty }
        return Array(Set(store.processFolders + fromItems)).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("e.g. Cold Retard w/ Stretch & Fold", text: $name)
                        .font(.jakarta(.regular, size: 17))
                        .textFieldBox()
                }

                Section {
                    FolderPickerRow(folderName: $folderName, existingFolders: processFolders)
                }

                Section {
                    ForEach(processCards.indices, id: \.self) { idx in
                        ProcessCardRow(
                            card: $processCards[idx],
                            position: processCards[idx].type == .combine ? "🔒" : "\(idx)",
                            isLocked: processCards[idx].type == .combine,
                            onRemove: {
                                processCards.remove(at: idx)
                                for i in processCards.indices { processCards[i].sortOrder = i }
                            },
                            onInsertBefore: {
                                processCards.insert(ProcessCard(type: .freeform), at: idx)
                                for i in processCards.indices { processCards[i].sortOrder = i }
                            },
                            onInsertAfter: {
                                processCards.insert(ProcessCard(type: .freeform), at: min(idx + 1, processCards.count))
                                for i in processCards.indices { processCards[i].sortOrder = i }
                            }
                        )
                    }
                    .onMove { from, to in
                        if from.contains(0) { return }
                        let safeTo = max(to, 1)
                        processCards.move(fromOffsets: from, toOffset: safeTo)
                        for i in processCards.indices { processCards[i].sortOrder = i }
                    }
                    .onDelete { offsets in
                        let locked = IndexSet(processCards.indices.filter { processCards[$0].type == .combine })
                        let safe = offsets.subtracting(locked)
                        processCards.remove(atOffsets: safe)
                        for i in processCards.indices { processCards[i].sortOrder = i }
                    }

                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add step", systemImage: "plus.circle")
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                } header: { Text("Process steps") }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(isEditing ? "Edit Process" : "New Process")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save As") {
                            var copy = SavedProcess(name: name, cards: processCards)
                            copy.folderName = folderName
                            store.addProcess(copy)
                            dismiss()
                        }
                        .disabled(name.isEmpty)
                        .foregroundColor(name.isEmpty ? .secondary : .secondary)
                        .font(.jakarta(.regular, size: 13))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var savedProcess = SavedProcess(name: name, cards: processCards)
                        savedProcess.folderName = folderName
                        if let eid = editingId { savedProcess.id = eid }
                        if isEditing {
                            store.updateProcess(savedProcess)
                        } else {
                            store.addProcess(savedProcess)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? .secondary : Color(hex: "D2B96A"))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddStepSheet { newCard in
                processCards.append(newCard)
                for i in processCards.indices { processCards[i].sortOrder = i }
            }
        }
    }
}

// MARK: - Standalone Preferment Builder

struct StandalonePrefermentBuilderView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var folderName: String
    @State private var hydration: Double
    @State private var hydrationText: String
    @State private var notes: String
    @State private var flourBlend: FlourBlend
    private let editingId: UUID?

    init(editing: SavedPreferment? = nil) {
        _name         = State(initialValue: editing?.name ?? "")
        _folderName   = State(initialValue: editing?.folderName ?? "")
        _hydration    = State(initialValue: editing?.hydration ?? 0.50)
        _hydrationText = State(initialValue: "\(Int((editing?.hydration ?? 0.50) * 100))")
        _notes        = State(initialValue: editing?.notes ?? "")
        // Seed flourBlend from saved; if blank, start with one default component
        let saved = editing?.flourBlend ?? FlourBlend()
        _flourBlend   = State(initialValue: saved.components.isEmpty ? FlourBlend() : saved)
        editingId     = editing?.id
    }

    var isEditing: Bool { editingId != nil }

    var prefermentFolders: [String] {
        let fromItems = store.savedPreferments.map(\.folderName).filter { !$0.isEmpty }
        return Array(Set(store.prefermentFolders + fromItems)).sorted()
    }

    var prefermentLabel: String {
        switch hydration {
        case ..<0.50:       return "Dry Biga"
        case 0.50..<0.51:   return "Biga"
        case 0.51..<0.61:   return "Wet Biga"
        case 0.61..<0.99:   return "High-Hydration Preferment"
        case 0.99..<1.01:   return "Poolish"
        default:            return "Wet Poolish"
        }
    }

    var derivedMethod: PrefermentMethod { hydration >= 0.99 ? .poolish : .biga }

    var canSave: Bool { !name.isEmpty && flourBlend.isValid }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("e.g. 50% Biga", text: $name)
                        .font(.jakarta(.regular, size: 17))
                        .textFieldBox()
                }

                Section {
                    FolderPickerRow(folderName: $folderName, existingFolders: prefermentFolders)
                }

                // Hydration — classifies the type (Biga vs Poolish) and implies water %
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Text(prefermentLabel)
                                .font(.jakarta(.regular, size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "D2B96A"))
                            Spacer()
                            HStack(spacing: 2) {
                                TextField("50", text: $hydrationText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 44)
                                    .font(.jakarta(.regular, size: 15))
                                    .inputBox()
                                    .onChange(of: hydrationText) { _, val in
                                        if let d = Double(val), d >= 40, d <= 120 {
                                            hydration = d / 100
                                        }
                                    }
                                Text("% water")
                                    .font(.jakarta(.regular, size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Slider(value: $hydration, in: 0.40...1.20, step: 0.01)
                            .tint(Color(hex: "D2B96A"))
                            .onChange(of: hydration) { _, val in
                                hydrationText = "\(Int(val * 100))"
                            }
                    }
                    .padding(.vertical, 6)
                } header: { Text("Hydration") }
                  footer: {
                    if hydration < 0.50 {
                        Text("Below 50% the dough will be very stiff — handle with lightly floured hands")
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(.orange)
                    }
                }

                // Flour blend — which flours go into this preferment
                Section("Flour") {
                    ForEach($flourBlend.components) { $component in
                        FlourComponentRow(component: $component) {
                            flourBlend.components.removeAll { $0.id == component.id }
                        }
                    }
                    HStack {
                        Text("Total")
                            .foregroundColor(.secondary)
                            .font(.jakarta(.regular, size: 17))
                        Spacer()
                        Text(String(format: "%.0f%%", flourBlend.totalPercentage)
                             + (flourBlend.isValid ? "  ✓" : ""))
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(flourBlend.isValid ? Color(hex: "D2B96A") : .red)
                    }
                    .listRowBackground(Color.clear)
                    Button {
                        var c = FlourComponent()
                        c.percentage = max(0, 100 - flourBlend.totalPercentage)
                        flourBlend.components.append(c)
                    } label: {
                        Label("Add flour type", systemImage: "plus")
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.jakarta(.regular, size: 17))
                    }
                }

                // Additives — diastatic malt, VWG, etc. (% of flour weight)
                Section {
                    ForEach($flourBlend.additives) { $additive in
                        AdditiveRow(additive: $additive) {
                            flourBlend.additives.removeAll { $0.id == additive.id }
                        }
                    }
                    Button {
                        flourBlend.additives.append(Additive())
                    } label: {
                        Label("Add additive", systemImage: "plus")
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.jakarta(.regular, size: 17))
                    }
                } header: { Text("Additives  ·  % of flour weight") }

                if !flourBlend.isValid {
                    Section {
                        Text("Flour percentages must total 100%")
                            .font(.jakarta(.regular, size: 12))
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.red.opacity(0.06))
                }

                Section("Notes") {
                    TextField("Fermentation notes, timing tips…", text: $notes, axis: .vertical)
                        .font(.jakarta(.regular, size: 13))
                        .lineLimit(3...)
                        .notesBox()
                }
            }
            .navigationTitle(isEditing ? "Edit Preferment" : "New Preferment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save As") {
                            var copy = SavedPreferment(name: name, method: derivedMethod, hydration: hydration, notes: notes)
                            copy.flourBlend = flourBlend; copy.folderName = folderName
                            store.addSavedPreferment(copy)
                            dismiss()
                        }
                        .disabled(!canSave)
                        .foregroundColor(canSave ? .secondary : .secondary)
                        .font(.jakarta(.regular, size: 13))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var pref = SavedPreferment(
                            name: name,
                            method: derivedMethod,
                            hydration: hydration,
                            notes: notes
                        )
                        pref.flourBlend = flourBlend
                        pref.folderName = folderName
                        if let eid = editingId { pref.id = eid }
                        if isEditing {
                            store.updateSavedPreferment(pref)
                        } else {
                            store.addSavedPreferment(pref)
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                    .foregroundColor(canSave ? Color(hex: "D2B96A") : .secondary)
                }
            }
        }
    }
}
