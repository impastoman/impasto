import SwiftUI

struct ProcessScriptStepView: View {
    @Binding var processCards: [ProcessCard]
    @Binding var mode: EntryMode
    @EnvironmentObject var store: RecipeStore

    @State private var showLibraryPicker = false
    @State private var showAddSheet = false
    @State private var saveProcessName: String = ""
    @State private var processSaved: Bool = false

    enum EntryMode { case pick, load, create }

    var body: some View {
        List {
            Section { WizardProgressView(step: 7, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            switch mode {
            case .pick:
                pickSection
            case .load, .create:
                statusRow
                cardsSection
                saveToLibrarySection
            }
        }
        .scrollContentBackground(.hidden)
        .environment(\.editMode, mode == .pick ? .constant(.inactive) : .constant(.active))
        .sheet(isPresented: $showLibraryPicker) {
            ProcessLibraryPickerView { selected in
                processCards = selected.cards
                saveProcessName = selected.name
                processSaved = true
                mode = .load
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddStepSheet { newCard in
                processCards.append(newCard)
                for i in processCards.indices { processCards[i].sortOrder = i }
            }
        }
    }

    var pickSection: some View {
        Section {
            Button {
                if store.savedProcesses.isEmpty { return }
                showLibraryPicker = true
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.down").foregroundColor(Color(hex: "D2B96A"))
                    Text("Load process")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(store.savedProcesses.isEmpty ? .secondary : Color(hex: "D2B96A"))
                }
            }
            .disabled(store.savedProcesses.isEmpty)

            if store.savedProcesses.isEmpty {
                Text("No saved processes yet — create one below or from the Library.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .tipText()
            }

            Button {
                mode = .create
            } label: {
                HStack {
                    Image(systemName: "plus.circle").foregroundColor(Color(hex: "D2B96A"))
                    Text("Build process")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        } header: { Text("Process") }
        .listRowBackground(Color.clear)
    }

    var statusRow: some View {
        Section {
            HStack {
                Image(systemName: mode == .load ? "tray.and.arrow.down" : "pencil")
                    .foregroundColor(Color(hex: "D2B96A")).font(.caption)
                Text(mode == .load ? (saveProcessName.isEmpty ? "Loaded from library" : saveProcessName) : "New process")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
                Spacer()
                Button("Change") {
                    saveProcessName = ""
                    processSaved = false
                    mode = .pick
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color(hex: "D2B96A").opacity(0.06))
    }

    var cardsSection: some View {
        Section {
            ForEach(processCards.indices, id: \.self) { idx in
                ProcessCardRow(
                    card: $processCards[idx],
                    position: positionLabel(for: idx),
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

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color(hex: "D2B96A"))
                    Text("Add step")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        } header: {
            HStack {
                Text("Process steps")
                Spacer()
                Text("hold to insert")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
                    .textCase(nil)
                    .tipText()
            }
        }
        .listRowBackground(Color.clear)
    }

    var saveToLibrarySection: some View {
        Section {
            if processSaved {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "D2B96A"))
                    Text("Saved to library")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            } else {
                TextField("Name this process to save...", text: $saveProcessName)
                    .font(.system(size: 13, design: .monospaced))
                    .textFieldBox()
                Button("Save to Library") {
                    let savedProcess = SavedProcess(
                        name: saveProcessName.isEmpty ? "Untitled Process" : saveProcessName,
                        cards: processCards
                    )
                    store.addProcess(savedProcess)
                    processSaved = true
                }
                .foregroundColor(Color(hex: "D2B96A"))
            }
        } header: { Text("Save to Library") }
          footer: { Text("Optional — save this process for reuse in future recipes").tipText() }
        .listRowBackground(Color.clear)
    }

    func positionLabel(for idx: Int) -> String {
        if processCards[idx].type == .combine { return "🔒" }
        return "\(idx)"
    }
}

// MARK: - Library picker

private struct ProcessLibraryPickerView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let onSelect: (SavedProcess) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.savedProcesses) { process in
                    Button {
                        onSelect(process)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(process.name.isEmpty ? "Untitled Process" : process.name)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                            Text("\(process.cards.count) steps")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Choose Process")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ProcessCardRow: View {
    @Binding var card: ProcessCard
    let position: String
    let isLocked: Bool
    let onRemove: () -> Void
    let onInsertBefore: () -> Void
    let onInsertAfter: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(position)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(isLocked ? .secondary : Color(hex: "D2B96A"))
                    .frame(width: 22, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    if isLocked {
                        Text(card.title)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        TextField(card.type == .freeform ? "Step name" : card.title, text: Binding(
                            get: { card.customTitle ?? "" },
                            set: { card.customTitle = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .textFieldBox()
                    }
                }

                Spacer()

                if card.duration > 0 {
                    Text(shortDuration(card.duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                if !isLocked {
                    Button {
                        withAnimation { expanded.toggle() }
                    } label: {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                }
            }
            .padding(.vertical, 6)

            if expanded && !isLocked {
                VStack(spacing: 10) {
                    Divider()

                    HStack {
                        Text("Duration")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        DurationField(seconds: Binding(
                            get: { card.duration },
                            set: { card.customDuration = $0 }
                        ))
                    }

                    if card.type == .bassinage {
                        HStack {
                            Text("Reserve water")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(card.bassinageReservePct * 100))%")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                        Slider(value: $card.bassinageReservePct, in: 0.05...0.20, step: 0.01)
                            .tint(Color(hex: "D2B96A"))
                    }

                    if card.type == .autolyse {
                        Picker("Mode", selection: $card.autolyseMode) {
                            ForEach(AutolyseMode.allCases, id: \.self) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .font(.system(size: 13, design: .monospaced))
                        Text(card.autolyseMode.description)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "note.text").font(.caption).foregroundColor(.secondary)
                        TextField("Add a note for this step...", text: $card.recipeNote, axis: .vertical)
                            .font(.system(size: 13, design: .monospaced))
                            .lineLimit(2...)
                            .notesBox()
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .contextMenu {
            if !isLocked {
                Button { onInsertBefore() } label: {
                    Label("Add Step Above", systemImage: "arrow.up.circle")
                }
                Button { onInsertAfter() } label: {
                    Label("Add Step Below", systemImage: "plus.circle")
                }
            }
        }
    }

    func shortDuration(_ t: TimeInterval) -> String {
        if t >= 86_400 {
            let d = Int(t) / 86_400; let h = (Int(t) % 86_400) / 3_600
            return h > 0 ? "\(d)d \(h)h" : "\(d)d"
        }
        let h = Int(t) / 3_600; let m = (Int(t) % 3_600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

struct AddStepSheet: View {
    let onAdd: (ProcessCard) -> Void
    @Environment(\.dismiss) private var dismiss

    var primaryTypes: [ProcessCardType] {
        [.rest, .stretchAndFold, .coldFerment, .freeform]
    }

    var standardTypes: [ProcessCardType] {
        ProcessCardType.allCases.filter { $0.isInDefaultSet && $0 != .bake && $0 != .combine }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Extra steps") {
                    ForEach(primaryTypes, id: \.self) { type in
                        Text(type.title).font(.system(.body, design: .monospaced))
                            .contentShape(Rectangle())
                            .onTapGesture { onAdd(ProcessCard(type: type)); dismiss() }
                    }
                }
                Section("Standard steps") {
                    ForEach(standardTypes, id: \.self) { type in
                        Text(type.title).font(.system(.body, design: .monospaced))
                            .contentShape(Rectangle())
                            .onTapGesture { onAdd(ProcessCard(type: type)); dismiss() }
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

// MARK: - Shared duration input (number field + min/hr/day unit picker)

struct DurationField: View {
    @Binding var seconds: Double
    var valueColor: Color = .primary

    enum DurUnit: String, CaseIterable {
        case min, hr, day

        func toSeconds(_ v: Int) -> Double {
            switch self {
            case .min: return Double(v) * 60
            case .hr:  return Double(v) * 3_600
            case .day: return Double(v) * 86_400
            }
        }
        func fromSeconds(_ s: Double) -> Int {
            switch self {
            case .min: return max(0, Int(s / 60))
            case .hr:  return max(0, Int(s / 3_600))
            case .day: return max(0, Int(s / 86_400))
            }
        }
        static func best(for s: Double) -> DurUnit {
            if s >= 86_400 { return .day }
            if s >= 3_600  { return .hr }
            return .min
        }
    }

    @State private var unit: DurUnit
    @State private var value: Int

    init(seconds: Binding<Double>, valueColor: Color = .primary) {
        _seconds = seconds
        self.valueColor = valueColor
        let best = DurUnit.best(for: seconds.wrappedValue)
        _unit  = State(initialValue: best)
        _value = State(initialValue: best.fromSeconds(seconds.wrappedValue))
    }

    var body: some View {
        HStack(spacing: 6) {
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .frame(width: 44)
                .font(.system(size: 13, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(valueColor)
                .inputBox()
                .onChange(of: value) { _, v in
                    seconds = unit.toSeconds(v)
                }
            Picker("", selection: $unit) {
                ForEach(DurUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .onChange(of: unit) { _, u in
                let converted = u.fromSeconds(seconds)
                value = converted
                seconds = u.toSeconds(converted)
            }
        }
    }
}
