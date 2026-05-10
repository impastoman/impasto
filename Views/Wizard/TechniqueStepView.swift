import SwiftUI

struct TechniqueStepView: View {
    @Binding var mixerType: MixerType
    @Binding var autolyse: Bool
    let style: PizzaStyle
    let finalHydration: Double

    var body: some View {
        List {
            Section { WizardProgressView(step: 4, total: 7) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("How will you mix?") {
                ForEach(MixerType.allCases, id: \.self) { mixer in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mixer.rawValue).font(.headline)
                            if !mixer.note.isEmpty {
                                Text(mixer.note).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if mixerType == mixer {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture { mixerType = mixer }
                }
            }

            if finalHydration > 0.70 && mixerType == .hand {
                Section {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow).font(.caption).padding(.top, 2)
                        Text("At \(Int(finalHydration * 100))% hydration, hand mixing will be challenging. Budget extra time and use wet hands.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.yellow.opacity(0.08))
            }

            Section {
                Toggle(isOn: $autolyse) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Autolyse")
                            .font(.headline)
                        Text("Rest flour + water before adding salt and yeast. Improves extensibility.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .tint(Color(hex: "D2B96A"))

                if autolyse {
                    LabeledContent("Suggested rest", value: style == .neapolitan ? "20 min" : "30 min")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
