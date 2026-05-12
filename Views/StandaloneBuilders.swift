import SwiftUI

// MARK: - Standalone Blend Builder

struct StandaloneBlendBuilderView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var blend = FlourBlend()

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("e.g. Caputo 00 + Semolina", text: $blend.name)
                        .font(.system(.body, design: .monospaced))
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
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Text(String(format: "%.0f%%", blend.totalPercentage) + (blend.isValid ? "  ✓" : ""))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(blend.isValid ? Color(hex: "D2B96A") : .red)
                    }
                    .listRowBackground(Color.clear)
                    Button {
                        blend.components.append(FlourComponent())
                    } label: {
                        Label("Add flour type", systemImage: "plus")
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.system(.body, design: .monospaced))
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
                            .font(.system(.body, design: .monospaced))
                    }
                } header: {
                    Text("Additives  ·  % of total flour weight")
                }

                if blend.containsRye {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text("Rye flour does not autolyse well — consider disabling autolyse if your blend contains rye")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                    .listRowBackground(Color.orange.opacity(0.06))
                }

                if !blend.isValid {
                    Section {
                        Text("Flour percentages must total 100%")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.red.opacity(0.06))
                }
            }
            .navigationTitle("New Flour Blend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.addBlend(blend)
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

    @State private var name = ""
    @State private var processCards: [ProcessCard] = ProcessCard.defaultCards(autolyse: false, bassinage: false)
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("e.g. Cold Retard w/ Stretch & Fold", text: $name)
                        .font(.system(.body, design: .monospaced))
                }

                Section {
                    ForEach(processCards.indices, id: \.self) { idx in
                        HStack(spacing: 10) {
                            Text(processCards[idx].type == .combine ? "🔒" : "\(idx)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(processCards[idx].type == .combine ? .secondary : Color(hex: "D2B96A"))
                                .frame(width: 22, alignment: .center)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(processCards[idx].title)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(processCards[idx].type == .combine ? .secondary : .primary)
                                if !processCards[idx].subtitle.isEmpty {
                                    Text(processCards[idx].subtitle)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if processCards[idx].type.isTimed && processCards[idx].duration > 0 {
                                Text(shortDuration(processCards[idx].duration))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
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
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                } header: { Text("Process steps") }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("New Process")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let savedProcess = SavedProcess(name: name, cards: processCards)
                        store.addProcess(savedProcess)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? .secondary : Color(hex: "D2B96A"))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            StandaloneAddStepSheet { newCard in
                processCards.append(newCard)
                for i in processCards.indices { processCards[i].sortOrder = i }
            }
        }
    }

    func shortDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

private struct StandaloneAddStepSheet: View {
    let onAdd: (ProcessCard) -> Void
    @Environment(\.dismiss) private var dismiss

    var addableTypes: [ProcessCardType] {
        let rest = ProcessCardType.allCases.filter { $0 != .bake && $0 != .combine && $0 != .freeform }
        return [.freeform] + rest
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Add a process step") {
                    ForEach(addableTypes, id: \.self) { type in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.title).font(.headline)
                                if !type.subtitle.isEmpty {
                                    Text(type.subtitle).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onAdd(ProcessCard(type: type))
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Add step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Standalone Preferment Builder

struct StandalonePrefermentBuilderView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var hydration: Double = 0.50
    @State private var notes = ""
    @State private var hydrationText = "50"

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

    var derivedMethod: PrefermentMethod {
        hydration >= 0.99 ? .poolish : .biga
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("e.g. 50% Biga", text: $name)
                        .font(.system(.body, design: .monospaced))
                }

                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Text(prefermentLabel)
                                .font(.system(size: 18, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "D2B96A"))
                            Spacer()
                            HStack(spacing: 2) {
                                TextField("50", text: $hydrationText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 44)
                                    .font(.system(size: 15, design: .monospaced))
                                    .onChange(of: hydrationText) { _, val in
                                        if let d = Double(val), d >= 40, d <= 120 {
                                            hydration = d / 100
                                        }
                                    }
                                Text("%")
                                    .font(.system(size: 15, design: .monospaced))
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
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }

                Section("Notes") {
                    TextField("Fermentation notes, ratios, tips...", text: $notes, axis: .vertical)
                        .font(.system(size: 13, design: .monospaced))
                        .lineLimit(3...)
                }
            }
            .navigationTitle("New Preferment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let pref = SavedPreferment(
                            name: name,
                            method: derivedMethod,
                            hydration: hydration,
                            notes: notes
                        )
                        store.addSavedPreferment(pref)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? .secondary : Color(hex: "D2B96A"))
                }
            }
        }
    }
}
