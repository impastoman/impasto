import SwiftUI

struct TechniqueStepView: View {
    @Binding var mixerType: MixerType
    @Binding var autolyse: Bool
    @Binding var bassinage: Bool
    let style: PizzaStyle
    let finalHydration: Double

    var body: some View {
        List {
            Section { WizardProgressView(step: 6, total: 10) }
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

            Section {
                Toggle(isOn: $bassinage) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Bassinage")
                            .font(.headline)
                        Text("Reserve a portion of water and add gradually during kneading. Controls temperature and improves extensibility.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .tint(Color(hex: "D2B96A"))

                if bassinage {
                    LabeledContent("Default reserve", value: "10% of total water")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text("Adjustable per process step in the next screen.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
