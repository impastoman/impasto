import SwiftUI

struct MethodStepView: View {
    @Binding var usePreferment: Bool
    @Binding var prefermentHydration: Double
    @Binding var method: PrefermentMethod
    @Binding var prefEntryMode: PrefEntryMode
    @Binding var timeline: Timeline
    @Binding var prefermentRatio: Double
    @Binding var prefermentFlourBlend: FlourBlend
    @EnvironmentObject var store: RecipeStore

    @State private var showLibraryPicker = false
    @State private var hydrationText: String = ""
    @State private var ratioText: String = ""
    @State private var savePrefName: String = ""
    @State private var prefSaved: Bool = false
    @State private var useCustomPrefBlend: Bool = false

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
                    ratioSection
                    prefBlendSection
                    timelineWarningSection
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
            if ratioText.isEmpty { ratioText = "\(Int(prefermentRatio * 100))" }
            useCustomPrefBlend = !prefermentFlourBlend.components.isEmpty
        }
        .sheet(isPresented: $showLibraryPicker) {
            PrefermentLibraryPickerView { selected in
                prefermentHydration = selected.hydration
                method = selected.method
                hydrationText = "\(Int(selected.hydration * 100))"
                if selected.ratioPercent > 0 {
                    prefermentRatio = selected.ratioPercent
                    ratioText = "\(Int(selected.ratioPercent * 100))"
                }
                if !selected.flourBlend.components.isEmpty {
                    prefermentFlourBlend = selected.flourBlend
                    useCustomPrefBlend = true
                }
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
                ratioText = "\(Int(prefermentRatio * 100))"
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

    var ratioSection: some View {
        Section {
            VStack(spacing: 10) {
                HStack {
                    Text("Preferment ratio")
                        .font(.system(size: 14, design: .monospaced))
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("\(Int(prefermentRatio * 100))", text: $ratioText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 44)
                            .font(.system(size: 15, design: .monospaced))
                            .onChange(of: ratioText) { _, val in
                                if let d = Double(val), d >= 1, d <= 99 {
                                    prefermentRatio = d / 100
                                }
                            }
                        Text("%")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                Slider(value: $prefermentRatio, in: 0.01...0.99, step: 0.01)
                    .tint(Color(hex: "D2B96A"))
                    .onChange(of: prefermentRatio) { _, val in
                        ratioText = "\(Int(val * 100))"
                    }
            }
            .padding(.vertical, 4)
        } header: { Text("Preferment ratio") }
          footer: { Text("Percentage of total flour that goes into the preferment. Typical: 20–40%.") }
    }

    @ViewBuilder
    var prefBlendSection: some View {
        Section {
            Toggle("Same flour as main blend", isOn: Binding(
                get: { !useCustomPrefBlend },
                set: { useSame in
                    useCustomPrefBlend = !useSame
                    if useSame {
                        prefermentFlourBlend = FlourBlend()
                    } else if prefermentFlourBlend.components.isEmpty {
                        prefermentFlourBlend.components = [FlourComponent()]
                    }
                }
            ))
            .tint(Color(hex: "D2B96A"))

            if useCustomPrefBlend {
                ForEach($prefermentFlourBlend.components) { $component in
                    FlourComponentRow(component: $component) {
                        prefermentFlourBlend.components.removeAll { $0.id == component.id }
                    }
                }
                HStack {
                    Text("Total")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    let total = prefermentFlourBlend.totalPercentage
                    Text(String(format: "%.0f%%", total) + (prefermentFlourBlend.isValid ? "  ✓" : ""))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(prefermentFlourBlend.isValid ? Color(hex: "D2B96A") : .red)
                }
                .listRowBackground(Color.clear)
                Button {
                    prefermentFlourBlend.components.append(FlourComponent())
                } label: {
                    Label("Add flour type", systemImage: "plus")
                        .foregroundColor(Color(hex: "D2B96A"))
                        .font(.system(.body, design: .monospaced))
                }
            }
        } header: { Text("Preferment flour") }
    }

    @ViewBuilder
    var timelineWarningSection: some View {
        if method.minimumHours > timeline.minimumHours {
            Section {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("\(method.rawValue) needs at least \(Int(method.minimumHours))h, but your timeline is \"\(timeline.rawValue)\" (\(timeline.hours)). Consider a longer timeline or switching to Direct method.")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
            .listRowBackground(Color.orange.opacity(0.06))
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
                    var pref = SavedPreferment(
                        name: savePrefName.isEmpty ? "Untitled Preferment" : savePrefName,
                        method: derivedMethod,
                        hydration: prefermentHydration
                    )
                    pref.ratioPercent = prefermentRatio
                    if useCustomPrefBlend { pref.flourBlend = prefermentFlourBlend }
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
                            Text("\(pref.label)  ·  \(Int(pref.hydration * 100))%  ·  \(Int(pref.ratioPercent * 100))% of flour")
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
