import SwiftUI

struct MethodStepView: View {
    @Binding var usePreferment: Bool
    @Binding var prefermentHydration: Double
    @Binding var method: PrefermentMethod
    @EnvironmentObject var store: RecipeStore

    @State private var hydrationText: String = ""
    @State private var savePrefName: String = ""
    @State private var prefSaved: Bool = false

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
                    }
            }

            if usePreferment {
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

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Levain").font(.headline)
                            Text("Sourdough starter · wild fermentation")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Coming soon")
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.orange.opacity(0.12))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)
                    .opacity(0.45)
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

            if usePreferment {
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
        }
    }

    var derivedMethod: PrefermentMethod {
        if !usePreferment { return .direct }
        return prefermentHydration >= 0.99 ? .poolish : .biga
    }

    var prefermentLabel: String {
        switch prefermentHydration {
        case ..<0.50:           return "Dry Biga"
        case 0.50..<0.51:       return "Biga"
        case 0.51..<0.61:       return "Wet Biga"
        case 0.61..<0.99:       return "High-Hydration Preferment"
        case 0.99..<1.01:       return "Poolish"
        default:                return "Wet Poolish"
        }
    }

    var prefermentNote: String {
        switch prefermentHydration {
        case ..<0.51:           return "Slower ferment · more acidity · tight crumb"
        case 0.51..<0.80:       return "Balanced ferment · mild complexity"
        case 0.80..<1.01:       return "Faster ferment · open crumb · mild sourness"
        default:                return "Very active · aromatic · easy to work"
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
