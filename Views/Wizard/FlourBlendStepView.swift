import SwiftUI

struct FlourBlendStepView: View {
    @Binding var flourBlend: FlourBlend
    @Binding var mode: EntryMode
    @EnvironmentObject var store: RecipeStore

    @State private var showLibraryPicker = false
    @State private var saveBlendName: String = ""
    @State private var blendSaved: Bool = false

    enum EntryMode { case pick, load, create }

    var body: some View {
        List {
            Section { WizardProgressView(step: 3, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            switch mode {
            case .pick:
                pickSection
            case .load, .create:
                statusRow
                flourSection
                totalRow
                addFlourRow
                additivesSection
                hintsSection
                saveToLibrarySection
            }
        }
        .sheet(isPresented: $showLibraryPicker) {
            BlendLibraryPickerView { selected in
                flourBlend = selected
                saveBlendName = selected.name
                blendSaved = true
                mode = .load
            }
        }
    }

    var pickSection: some View {
        Section {
            Button {
                if store.savedBlends.isEmpty { return }
                showLibraryPicker = true
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.down").foregroundColor(Color(hex: "D2B96A"))
                    Text("Load flour blend")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(store.savedBlends.isEmpty ? .secondary : Color(hex: "D2B96A"))
                }
            }
            .disabled(store.savedBlends.isEmpty)

            if store.savedBlends.isEmpty {
                Text("No saved blends yet — create one below or from the Library.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Button {
                flourBlend = FlourBlend()
                mode = .create
            } label: {
                HStack {
                    Image(systemName: "plus.circle").foregroundColor(Color(hex: "D2B96A"))
                    Text("Create flour blend")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        } header: { Text("Flour blend") }
    }

    var statusRow: some View {
        Section {
            HStack {
                Image(systemName: mode == .load ? "tray.and.arrow.down" : "pencil")
                    .foregroundColor(Color(hex: "D2B96A")).font(.caption)
                Text(mode == .load
                     ? (flourBlend.name.isEmpty ? "Loaded from library" : flourBlend.name)
                     : "New blend")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
                Spacer()
                Button("Change") {
                    flourBlend = FlourBlend()
                    saveBlendName = ""
                    blendSaved = false
                    mode = .pick
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color(hex: "D2B96A").opacity(0.06))
    }

    var flourSection: some View {
        Section("Flour blend") {
            ForEach($flourBlend.components) { $component in
                FlourComponentRow(component: $component) {
                    flourBlend.components.removeAll { $0.id == component.id }
                }
            }
        }
    }

    var totalRow: some View {
        let total = flourBlend.totalPercentage
        let isValid = flourBlend.isValid
        return HStack {
            Text("Total").foregroundColor(.secondary).font(.system(.body, design: .monospaced))
            Spacer()
            Text(String(format: "%.0f%%", total) + (isValid ? "  ✓" : ""))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(isValid ? Color(hex: "D2B96A") : .red)
        }
        .listRowBackground(Color.clear)
    }

    var addFlourRow: some View {
        Button {
            var c = FlourComponent()
            c.percentage = max(0, 100 - flourBlend.totalPercentage)
            flourBlend.components.append(c)
        } label: {
            Label("Add flour type", systemImage: "plus")
                .foregroundColor(Color(hex: "D2B96A"))
                .font(.system(.body, design: .monospaced))
        }
    }

    var additivesSection: some View {
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
                    .font(.system(.body, design: .monospaced))
            }
        } header: {
            Text("Additives  ·  % of total flour weight")
        }
    }

    var hintsSection: some View {
        Group {
            if flourBlend.containsRye {
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
            if !flourBlend.isValid {
                Section {
                    Text("Flour percentages must total 100%")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.red)
                }
                .listRowBackground(Color.red.opacity(0.06))
            }
        }
    }

    var saveToLibrarySection: some View {
        Section {
            if blendSaved {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "D2B96A"))
                    Text("Saved to library")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            } else {
                TextField("Name this blend to save...", text: $saveBlendName)
                    .font(.system(size: 13, design: .monospaced))
                Button("Save to Library") {
                    var toSave = flourBlend
                    toSave.name = saveBlendName.isEmpty ? "Untitled Blend" : saveBlendName
                    store.addBlend(toSave)
                    blendSaved = true
                }
                .foregroundColor(flourBlend.isValid ? Color(hex: "D2B96A") : .secondary)
                .disabled(!flourBlend.isValid)
            }
        } header: { Text("Save to Library") }
          footer: { Text("Optional — save this blend for reuse in future recipes") }
    }
}

// MARK: - Library picker

private struct BlendLibraryPickerView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let onSelect: (FlourBlend) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.savedBlends) { blend in
                    Button {
                        onSelect(blend)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(blend.name.isEmpty ? "Untitled Blend" : blend.name)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                            Text(blend.components.map { "\(Int($0.percentage))% \($0.type.rawValue)" }.joined(separator: " · "))
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Choose Blend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct FlourComponentRow: View {
    @Binding var component: FlourComponent
    let onRemove: () -> Void
    @State private var showNote = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: $component.type) {
                    ForEach(FlourType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("0", value: $component.percentage, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .font(.system(.body, design: .monospaced))

                Text("%").foregroundColor(.secondary).font(.system(.body, design: .monospaced))

                Button(action: onRemove) {
                    Image(systemName: "minus.circle").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TextField("gluten %", value: $component.glutenPct, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 72)
                    .font(.system(size: 13, design: .monospaced))
                Text("% gluten").font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                Spacer()
                TextField("brand / note", text: $component.brand)
                    .font(.system(size: 13, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            }

            if !component.type.typicalGlutenRange.isEmpty {
                Text("Typical: \(component.type.typicalGlutenRange)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdditiveRow: View {
    @Binding var additive: Additive
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: $additive.type) {
                    ForEach(AdditiveType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("0", value: $additive.percentage, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .font(.system(.body, design: .monospaced))

                Text("%").foregroundColor(.secondary).font(.system(.body, design: .monospaced))

                Button(action: onRemove) {
                    Image(systemName: "minus.circle").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack {
                TextField("note", text: $additive.note)
                    .font(.system(size: 13, design: .monospaced))
                if !additive.type.typicalRange.isEmpty {
                    Text("Typical: \(additive.type.typicalRange)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
