import SwiftUI

struct MethodStepView: View {
    @Binding var usePreferment: Bool
    @Binding var prefermentHydration: Double
    @Binding var method: PrefermentMethod
    @Binding var prefEntryMode: PrefEntryMode
    @EnvironmentObject var store: RecipeStore

    @State private var showLibraryPicker = false
    @State private var hydrationText: String = ""
    @State private var savePrefName: String = ""
    @State private var prefSaved: Bool = false

    enum PrefEntryMode { case pick, load, create }

    var body: some View {
        List {
            Section { WizardProgressView(step: 5, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("Use a preferment?") {
                Toggle("Yes — use a preferment", isOn: $usePreferment)
                    .tint(Color(hex: "D2B96A"))
                    .onChange(of: usePreferment) { _, val in
                        method = val ? derivedMethod : .direct
                        if !val { prefEntryMode = .pick }
                    }
            }

            if usePreferment {
                switch prefEntryMode {
                case .pick:
                    prefPickSection
                case .load, .create:
                    prefStatusRow
                    hydrationSection
                    saveToLibrarySection
                }
            } else {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary).font(.caption)
                        Text("All flour mixed at once · neutral flavor · fastest to the oven")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                } header: { Text("Direct method") }
            }
        }
        .onAppear {
            if hydrationText.isEmpty { hydrationText = "\(Int(prefermentHydration * 100))" }
        }
        .sheet(isPresented: $showLibraryPicker) {
            PrefermentLibraryPickerView { selected in
                prefermentHydration = selected.hydration
                method = selected.method
                hydrationText = "\(Int(selected.hydration * 100))"
                savePrefName = selected.name
                prefSaved = true
                prefEntryMode = .load
            }
        }
    }

    var prefPickSection: some View {
        Section {
            Button {
                if store.savedPreferments.isEmpty { return }
                showLibraryPicker = true
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.down").foregroundColor(Color(hex: "D2B96A"))
                    Text("Load preferment")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(store.savedPreferments.isEmpty ? .secondary : Color(hex: "D2B96A"))
                }
            }
            .disabled(store.savedPreferments.isEmpty)

            if store.savedPreferments.isEmpty {
                Text("No saved preferments yet — create one below or from the Library.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Button {
                hydrationText = "\(Int(prefermentHydration * 100))"
                prefEntryMode = .create
            } label: {
                HStack {
                    Image(systemName: "plus.circle").foregroundColor(Color(hex: "D2B96A"))
                    Text("Configure preferment")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        } header: { Text("Preferment") }
    }

    var prefStatusRow: some View {
        Section {
            HStack {
                Image(systemName: prefEntryMode == .load ? "tray.and.arrow.down" : "pencil")
                    .foregroundColor(Color(hex: "D2B96A")).font(.caption)
                Text(prefEntryMode == .load ? (savePrefName.isEmpty ? "Loaded from library" : savePrefName) : "New preferment")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
                Spacer()
                Button("Change") {
                    savePrefName = ""
                    prefSaved = false
                    prefEntryMode = .pick
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color(hex: "D2B96A").opacity(0.06))
    }

    var hydrationSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text(prefermentLabel)
                        .font(.system(size: 18, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "D2B96A"))
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("\(Int(prefermentHydration * 100))", text: $hydrationText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 44)
                            .font(.system(size: 15, design: .monospaced))
                            .onChange(of: hydrationText) { _, val in
                                if let d = Double(val), d >= 40, d <= 120 {
                                    prefermentHydration = d / 100
                                    method = derivedMethod
                                }
                            }
                        Text("%")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Slider(value: $prefermentHydration, in: 0.40...1.20, step: 0.01)
                    .tint(Color(hex: "D2B96A"))
                    .onChange(of: prefermentHydration) { _, val in
                        method = derivedMethod
                        hydrationText = "\(Int(val * 100))"
                    }

                Text(prefermentNote)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)

                HStack(spacing: 0) {
                    ForEach(hydrationZones, id: \.label) { zone in
                        Text(zone.label)
                            .font(.system(size: 9, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundColor(zone.active ? Color(hex: "D2B96A") : Color.secondary.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 6)
        } header: {
            Text("Preferment hydration")
        } footer: {
            if prefermentHydration < 0.50 {
                Text("Below 50% the dough will be very stiff — handle with lightly floured hands")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
    }

    var saveToLibrarySection: some View {
        Section {
            if prefSaved {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "D2B96A"))
                    Text("Saved to library")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            } else {
                TextField("Name this preferment to save...", text: $savePrefName)
                    .font(.system(size: 13, design: .monospaced))
                Button("Save to Library") {
                    let pref = SavedPreferment(
                        name: savePrefName.isEmpty ? "Untitled Preferment" : savePrefName,
                        method: derivedMethod,
                        hydration: prefermentHydration
                    )
                    store.addSavedPreferment(pref)
                    prefSaved = true
                }
                .foregroundColor(Color(hex: "D2B96A"))
            }
        } header: { Text("Save to Library") }
          footer: { Text("Optional — save this preferment for reuse in future recipes") }
    }

    var derivedMethod: PrefermentMethod {
        if !usePreferment { return .direct }
        return prefermentHydration >= 0.99 ? .poolish : .biga
    }

    var prefermentLabel: String {
        switch prefermentHydration {
        case ..<0.50:       return "Dry Biga"
        case 0.50..<0.51:   return "Biga"
        case 0.51..<0.61:   return "Wet Biga"
        case 0.61..<0.99:   return "High-Hydration Preferment"
        case 0.99..<1.01:   return "Poolish"
        default:            return "Wet Poolish"
        }
    }

    var prefermentNote: String {
        switch prefermentHydration {
        case ..<0.51:       return "Slower ferment · more acidity · tight crumb"
        case 0.51..<0.80:   return "Balanced ferment · mild complexity"
        case 0.80..<1.01:   return "Faster ferment · open crumb · mild sourness"
        default:            return "Very active · aromatic · easy to work"
        }
    }

    struct Zone { let label: String; let active: Bool }
    var hydrationZones: [Zone] {
        let zones = ["Dry\nBiga", "Biga", "Wet\nBiga", "Hi-Hyd", "Poolish", "Wet\nPoolish"]
        let thresholds: [ClosedRange<Double>] = [
            0.40...0.495, 0.495...0.505, 0.505...0.61, 0.61...0.99, 0.99...1.005, 1.005...1.20
        ]
        return zip(zones, thresholds).map { Zone(label: $0, active: $1.contains(prefermentHydration)) }
    }
}

// MARK: - Library picker

private struct PrefermentLibraryPickerView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let onSelect: (SavedPreferment) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.savedPreferments) { pref in
                    Button {
                        onSelect(pref)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(pref.name.isEmpty ? "Untitled Preferment" : pref.name)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                            Text("\(pref.label)  ·  \(Int(pref.hydration * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Choose Preferment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
