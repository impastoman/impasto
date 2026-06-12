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
    @State private var prefHydrateOwnWay: Bool = false

    enum PrefEntryMode { case pick, load, create }

    var body: some View {
        List {
            Section { WizardProgressView(step: 5, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section(header: Text("Use a preferment?").font(.jakarta(.semibold, size: 13))) {
                Toggle("Yes — use a preferment", isOn: $usePreferment)
                    .tint(Color(hex: "7FA2BD"))
                    .onChange(of: usePreferment) { _, val in
                        method = val ? derivedMethod : .direct
                        if !val { prefEntryMode = .pick }
                    }
            }
            .listRowBackground(Color.clear)

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
                            .foregroundColor(.secondary).font(.jakarta(.regular, size: 12))
                        Text("All flour mixed at once · neutral flavor · fastest to the oven")
                            .font(.jakarta(.regular, size: 12))
                            .foregroundColor(.secondary)
                    }
                    .tipText()
                } header: { Text("Direct method") }
            }
        }
        .meadList()
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
                    Image(systemName: "tray.and.arrow.down").foregroundColor(Color(hex: "7FA2BD"))
                    Text("Load preferment")
                        .font(.jakarta(.regular, size: 17))
                        .foregroundColor(store.savedPreferments.isEmpty ? .secondary : Color(hex: "7FA2BD"))
                }
            }
            .disabled(store.savedPreferments.isEmpty)

            if store.savedPreferments.isEmpty {
                Text("No saved preferments yet — create one below or from the Library.")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(.secondary)
                    .tipText()
            }

            Button {
                hydrationText = "\(Int(prefermentHydration * 100))"
                ratioText = "\(Int(prefermentRatio * 100))"
                prefEntryMode = .create
            } label: {
                HStack {
                    Image(systemName: "plus.circle").foregroundColor(Color(hex: "7FA2BD"))
                    Text("Configure preferment")
                        .font(.jakarta(.regular, size: 17))
                        .foregroundColor(Color(hex: "7FA2BD"))
                }
            }
        } header: { Text("Preferment") }
        .listRowBackground(Color.clear)
    }

    var prefStatusRow: some View {
        Section {
            HStack {
                Image(systemName: prefEntryMode == .load ? "tray.and.arrow.down" : "pencil")
                    .foregroundColor(Color(hex: "7FA2BD")).font(.jakarta(.regular, size: 12))
                Text(prefEntryMode == .load ? (savePrefName.isEmpty ? "Loaded from library" : savePrefName) : "New preferment")
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(Color(hex: "7FA2BD"))
                Spacer()
                Button("Change") {
                    savePrefName = ""
                    prefSaved = false
                    prefEntryMode = .pick
                }
                .font(.jakarta(.regular, size: 12))
                .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color(hex: "7FA2BD").opacity(0.06))
    }

    var hydrationSection: some View {
        Section {
            Toggle(isOn: $prefHydrateOwnWay) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hydrate your way")
                        .font(.jakarta(.regular, size: 17))
                    Text("Enter any value from 1–999%")
                        .font(.jakarta(.regular, size: 11))
                        .foregroundColor(.secondary)
                        .tipText()
                }
            }
            .tint(Color(hex: "7FA2BD"))

            VStack(spacing: 12) {
                HStack {
                    Text(prefermentLabel)
                        .font(.jakarta(.regular, size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "7FA2BD"))
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("\(Int(prefermentHydration * 100))", text: $hydrationText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: prefHydrateOwnWay ? 72 : 52)
                            .font(.jakarta(.regular, size: 15))
                            .padding(.vertical, 4).padding(.horizontal, 4)
                            .background(Color(hex: "F0EDE4"))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "7FA2BD").opacity(0.5), lineWidth: 1))
                            .onChange(of: hydrationText) { _, val in
                                let f = val.filter { $0.isNumber || $0 == "." }
                                if f != val { hydrationText = f; return }
                                if let d = Double(val), d >= 1 {
                                    prefermentHydration = prefHydrateOwnWay ? d / 100 : min(d / 100, 1.20)
                                    method = derivedMethod
                                }
                            }
                        Text("%")
                            .font(.jakarta(.regular, size: 15))
                            .foregroundColor(.secondary)
                    }
                }

                if !prefHydrateOwnWay {
                    Slider(value: $prefermentHydration, in: 0.40...1.20, step: 0.01)
                        .tint(Color(hex: "7FA2BD"))
                        .onChange(of: prefermentHydration) { _, val in
                            method = derivedMethod
                            hydrationText = "\(Int(val * 100))"
                        }

                    Text(prefermentNote)
                        .font(.jakarta(.regular, size: 12))
                        .foregroundColor(.secondary)
                        .tipText()

                    HStack(spacing: 0) {
                        ForEach(hydrationZones, id: \.label) { zone in
                            Text(zone.label)
                                .font(.jakarta(.regular, size: 9))
                                .multilineTextAlignment(.center)
                                .foregroundColor(zone.active ? Color(hex: "7FA2BD") : Color.secondary.opacity(0.4))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 6)
        } header: {
            Text("Preferment hydration")
        } footer: {
            Group {
                if prefHydrateOwnWay {
                    Text("Slider hidden — any value from 1–999% accepted. The formula scales accordingly.")
                } else if prefermentHydration < 0.50 {
                    Text("Below 50% the dough will be very stiff — handle with lightly floured hands")
                        .foregroundColor(.orange)
                } else {
                    Text("Tap the field to type any value from 1–999%")
                }
            }
            .font(.jakarta(.regular, size: 11))
            .tipText()
        }
    }

    var ratioSection: some View {
        Section {
            VStack(spacing: 10) {
                HStack {
                    Text("Preferment ratio")
                        .font(.jakarta(.regular, size: 14))
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("\(Int(prefermentRatio * 100))", text: $ratioText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 52)
                            .font(.jakarta(.regular, size: 15))
                            .padding(.vertical, 4).padding(.horizontal, 4)
                            .background(Color(hex: "F0EDE4"))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "7FA2BD").opacity(0.5), lineWidth: 1))
                            .onChange(of: ratioText) { _, val in
                                let f = val.filter { $0.isNumber || $0 == "." }
                                if f != val { ratioText = f; return }
                                if let d = Double(val), d >= 1 {
                                    prefermentRatio = d / 100
                                }
                            }
                        Text("%")
                            .font(.jakarta(.regular, size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                Slider(value: $prefermentRatio, in: 0.01...0.99, step: 0.01)
                    .tint(Color(hex: "7FA2BD"))
                    .onChange(of: prefermentRatio) { _, val in
                        ratioText = "\(Int(val * 100))"
                    }
            }
            .padding(.vertical, 4)
        } header: { Text("Preferment ratio") }
          footer: { Text("Percentage of total flour that goes into the preferment. Typical: 20–40%  ·  tap field to type any value from 1–999%").font(.jakarta(.regular, size: 11)).tipText() }
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
            .tint(Color(hex: "7FA2BD"))

            if useCustomPrefBlend {
                ForEach($prefermentFlourBlend.components) { $component in
                    FlourComponentRow(component: $component) {
                        prefermentFlourBlend.components.removeAll { $0.id == component.id }
                    }
                }
                HStack {
                    Text("Total")
                        .foregroundColor(.secondary)
                        .font(.jakarta(.regular, size: 17))
                    Spacer()
                    let total = prefermentFlourBlend.totalPercentage
                    Text(String(format: "%.0f%%", total) + (prefermentFlourBlend.isValid ? "  ✓" : ""))
                        .font(.jakarta(.regular, size: 17))
                        .foregroundColor(prefermentFlourBlend.isValid ? Color(hex: "7FA2BD") : .red)
                }
                .listRowBackground(Color.clear)
                Button {
                    var c = FlourComponent()
                    c.percentage = max(0, 100 - prefermentFlourBlend.totalPercentage)
                    prefermentFlourBlend.components.append(c)
                } label: {
                    Label("Add flour type", systemImage: "plus")
                        .foregroundColor(Color(hex: "7FA2BD"))
                        .font(.jakarta(.regular, size: 17))
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
                        .font(.jakarta(.regular, size: 12))
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
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "7FA2BD"))
                    Text("Saved to library")
                        .font(.jakarta(.regular, size: 13))
                        .foregroundColor(Color(hex: "7FA2BD"))
                }
            } else {
                TextField("Name this preferment to save...", text: $savePrefName)
                    .font(.jakarta(.regular, size: 13))
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
                .foregroundColor(Color(hex: "7FA2BD"))
            }
        } header: { Text("Save to Library") }
          footer: { Text("Optional — save this preferment for reuse in future recipes").tipText() }
        .listRowBackground(Color.clear)
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
                                .font(.jakarta(.regular, size: 17))
                                .foregroundColor(.primary)
                            Text("\(pref.label)  ·  \(Int(pref.hydration * 100))%  ·  \(Int(pref.ratioPercent * 100))% of flour")
                                .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
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
